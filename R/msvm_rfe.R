.safe_scale_matrix <- function(x) {
  scaled <- scale(x)
  scaled[!is.finite(scaled)] <- 0
  scaled
}

.msvm_weight_vector <- function(x,
                                y,
                                cost = 10,
                                cachesize = 500,
                                ...) {
  model <- e1071::svm(
    x = x,
    y = y,
    cost = cost,
    cachesize = cachesize,
    scale = FALSE,
    type = "C-classification",
    kernel = "linear",
    ...
  )
  weights <- drop(t(model$coefs) %*% as.matrix(model$SV))
  stats::setNames(weights, colnames(x))
}

.msvm_rfe_rank <- function(x,
                           y,
                           k = 10,
                           halve_above = 50,
                           cost = 10,
                           rank_scale = TRUE,
                           cachesize = 500,
                           verbose = FALSE,
                           ...) {
  x <- as.matrix(x)
  y <- factor(y)
  if (rank_scale) {
    x <- .safe_scale_matrix(x)
  }

  remaining <- colnames(x)
  eliminated <- character()

  while (length(remaining) > 0L) {
    if (length(remaining) == 1L) {
      eliminated <- c(eliminated, remaining)
      break
    }

    internal_k <- min(as.integer(k), min(table(y)))
    if (internal_k > 1L) {
      folds <- .create_folds(y, k = internal_k)
      weight_matrix <- lapply(folds, function(test_idx) {
        .msvm_weight_vector(
          x = x[-test_idx, remaining, drop = FALSE],
          y = y[-test_idx],
          cost = cost,
          cachesize = cachesize,
          ...
        )
      })
      weight_matrix <- do.call(rbind, weight_matrix)
      norms <- sqrt(rowSums(weight_matrix^2))
      norms[norms == 0] <- .Machine$double.eps
      weight_matrix <- weight_matrix / norms
      squared_weights <- weight_matrix^2
      mean_score <- colMeans(squared_weights)
      sd_score <- apply(squared_weights, 2L, stats::sd)
      sd_score[sd_score == 0 | is.na(sd_score)] <- .Machine$double.eps
      score <- mean_score / sd_score
    } else {
      weights <- .msvm_weight_vector(
        x = x[, remaining, drop = FALSE],
        y = y,
        cost = cost,
        cachesize = cachesize,
        ...
      )
      score <- weights^2
    }

    remove_n <- if (length(remaining) > halve_above) {
      round(length(remaining) / 2)
    } else {
      1L
    }
    remove_n <- min(remove_n, length(remaining) - 1L)
    remove_features <- names(sort(score, decreasing = FALSE))[seq_len(remove_n)]

    if (verbose) {
      message("mSVM-RFE removing ", remove_n, " feature(s); ", length(remaining) - remove_n, " remain")
    }

    eliminated <- c(eliminated, remove_features)
    remaining <- setdiff(remaining, remove_features)
  }

  rev(eliminated)
}

.aggregate_msvm_rankings <- function(fold_rankings, all_features) {
  rank_matrix <- matrix(
    NA_real_,
    nrow = length(all_features),
    ncol = length(fold_rankings),
    dimnames = list(all_features, paste0("fold_", seq_along(fold_rankings)))
  )
  for (fold_id in seq_along(fold_rankings)) {
    ranked <- fold_rankings[[fold_id]]
    rank_matrix[ranked, fold_id] <- seq_along(ranked)
  }
  avg_rank <- rowMeans(rank_matrix, na.rm = TRUE)
  names(sort(avg_rank, decreasing = FALSE))
}

.svm_eval_fold <- function(train_x,
                           train_y,
                           test_x,
                           test_y,
                           tune = TRUE,
                           tune_ranges = list(gamma = 2^(-12:0), cost = 2^(-6:6)),
                           tune_sampling = "cross",
                           performance_kernel = "radial",
                           performance_scale = TRUE,
                           performance_params = list(),
                           performance_cost = 10,
                           performance_gamma = NULL) {
  if (tune) {
    tune_obj <- e1071::tune(
      e1071::svm,
      train.x = train_x,
      train.y = train_y,
      kernel = performance_kernel,
      scale = performance_scale,
      ranges = tune_ranges,
      tunecontrol = e1071::tune.control(sampling = tune_sampling)
    )
    model_params <- as.list(tune_obj$best.parameters)
  } else {
    model_params <- list(cost = performance_cost)
    if (!is.null(performance_gamma)) {
      model_params$gamma <- performance_gamma
    }
  }

  model_params <- utils::modifyList(performance_params, model_params)
  model <- do.call(
    e1071::svm,
    c(
      list(
        x = train_x,
        y = train_y,
        kernel = performance_kernel,
        scale = performance_scale,
        type = "C-classification"
      ),
      model_params
    )
  )
  preds <- stats::predict(model, test_x)
  mean(preds != test_y)
}

run_msvm_rfe <- function(data,
                         group_col = "group",
                         feature_cols = NULL,
                         positive_class = NULL,
                         seed = 123,
                         k = 10,
                         halve_above = 50,
                         rank_cost = 10,
                         rank_scale = TRUE,
                         cachesize = 500,
                         nfolds = 5,
                         max_features = 200,
                         tolerance = 0,
                         prefer = c("largest", "smallest"),
                         tune = TRUE,
                         tune_ranges = list(gamma = 2^(-12:0), cost = 2^(-6:6)),
                         tune_sampling = "cross",
                         performance_kernel = "radial",
                         performance_scale = TRUE,
                         performance_params = list(),
                         performance_cost = 10,
                         performance_gamma = NULL,
                         verbose = FALSE,
                         drop_na = TRUE,
                         method_name = "SVM",
                         ...) {
  .require_pkg("e1071")
  prefer <- match.arg(prefer)
  prepared <- .ensure_ikun_data(data, group_col, feature_cols, positive_class, drop_na)
  if (nlevels(prepared$y) != 2L) {
    stop("mSVM-RFE currently supports binary classification only.", call. = FALSE)
  }

  x <- as.matrix(prepared$x)
  y <- prepared$y
  .set_seed(seed)

  folds <- .create_folds(y, k = nfolds, seed = seed)
  fold_rankings <- vector("list", length(folds))
  for (fold_id in seq_along(folds)) {
    test_idx <- folds[[fold_id]]
    train_idx <- setdiff(seq_len(nrow(x)), test_idx)
    fold_rankings[[fold_id]] <- .msvm_rfe_rank(
      x = x[train_idx, , drop = FALSE],
      y = y[train_idx],
      k = k,
      halve_above = halve_above,
      cost = rank_cost,
      rank_scale = rank_scale,
      cachesize = cachesize,
      verbose = verbose,
      ...
    )
  }

  ranked_internal <- .aggregate_msvm_rankings(fold_rankings, colnames(x))
  avg_rank <- rowMeans(sapply(fold_rankings, function(ranked) {
    ranks <- numeric(length(ranked))
    names(ranks) <- ranked
    ranks[ranked] <- seq_along(ranked)
    ranks[colnames(x)]
  }), na.rm = TRUE)
  names(avg_rank) <- colnames(x)

  max_features <- min(as.integer(max_features), length(ranked_internal))
  error_rates <- numeric(max_features)

  for (i in seq_len(max_features)) {
    if (verbose && (i == 1L || i %% max(1L, round(max_features / 10L)) == 0L)) {
      message("mSVM-RFE feature sweep: ", i, "/", max_features)
    }
    fold_errors <- numeric(length(folds))
    for (fold_id in seq_along(folds)) {
      test_idx <- folds[[fold_id]]
      train_idx <- setdiff(seq_len(nrow(x)), test_idx)
      current_features <- fold_rankings[[fold_id]][seq_len(i)]

      fold_errors[fold_id] <- .svm_eval_fold(
        train_x = x[train_idx, current_features, drop = FALSE],
        train_y = y[train_idx],
        test_x = x[test_idx, current_features, drop = FALSE],
        test_y = y[test_idx],
        tune = tune,
        tune_ranges = tune_ranges,
        tune_sampling = tune_sampling,
        performance_kernel = performance_kernel,
        performance_scale = performance_scale,
        performance_params = performance_params,
        performance_cost = performance_cost,
        performance_gamma = performance_gamma
      )
    }
    error_rates[i] <- mean(fold_errors)
  }

  choice <- .select_count(error_rates, maximize = FALSE, tolerance = tolerance, prefer = prefer)
  selected <- ranked_internal[seq_len(choice$optimal_count)]
  ranking <- data.frame(
    feature_internal = ranked_internal,
    feature = .restore_feature_names(ranked_internal, prepared),
    rank = seq_along(ranked_internal),
    avg_rank = avg_rank[ranked_internal],
    FeatureName = .restore_feature_names(ranked_internal, prepared),
    FeatureID = match(ranked_internal, colnames(x)),
    AvgRank = avg_rank[ranked_internal],
    stringsAsFactors = FALSE
  )
  cv_metrics <- data.frame(
    n_features = seq_len(max_features),
    accuracy = 1 - error_rates,
    error = error_rates
  )

  .method_result(
    method = method_name,
    selected_internal = selected,
    prepared = prepared,
    ranking = ranking,
    fold_rankings = fold_rankings,
    cv_metrics = cv_metrics,
    optimal_count = choice$optimal_count,
    strict_best_count = choice$strict_best_count,
    best_error = choice$best_value,
    best_accuracy = 1 - choice$best_value,
    params = list(
      k = k,
      halve_above = halve_above,
      rank_cost = rank_cost,
      rank_scale = rank_scale,
      cachesize = cachesize,
      nfolds = nfolds,
      max_features = max_features,
      tolerance = tolerance,
      prefer = prefer,
      tune = tune,
      tune_ranges = tune_ranges,
      tune_sampling = tune_sampling,
      performance_kernel = performance_kernel,
      performance_scale = performance_scale,
      performance_params = performance_params,
      performance_cost = performance_cost,
      performance_gamma = performance_gamma,
      seed = seed
    )
  )
}

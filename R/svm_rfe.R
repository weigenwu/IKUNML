.svm_linear_scores <- function(x, y, cost = 1, scale = TRUE, ...) {
  model <- e1071::svm(
    x = x,
    y = y,
    kernel = "linear",
    cost = cost,
    scale = scale,
    ...
  )
  weights <- drop(t(model$coefs) %*% as.matrix(model$SV))
  stats::setNames(weights^2, colnames(x))
}

.svm_rfe_rank <- function(x, y, cost = 1, scale = TRUE, halve_above = 50, ...) {
  remaining <- colnames(x)
  eliminated <- character()

  while (length(remaining) > 0L) {
    if (length(remaining) == 1L) {
      eliminated <- c(eliminated, remaining)
      break
    }

    scores <- .svm_linear_scores(x[, remaining, drop = FALSE], y, cost = cost, scale = scale, ...)
    remove_n <- if (length(remaining) > halve_above) {
      max(1L, floor(length(remaining) / 2L))
    } else {
      1L
    }
    remove_n <- min(remove_n, length(remaining) - 1L)
    remove_features <- names(sort(scores, decreasing = FALSE))[seq_len(remove_n)]
    eliminated <- c(eliminated, remove_features)
    remaining <- setdiff(remaining, remove_features)
  }

  rev(eliminated)
}

run_svm_rfe <- function(data,
                        group_col = "group",
                        feature_cols = NULL,
                        positive_class = NULL,
                        seed = 123,
                        cost = 1,
                        scale = TRUE,
                        halve_above = 50,
                        nfolds = 5,
                        max_features = 200,
                        tolerance = 0,
                        prefer = c("largest", "smallest"),
                        drop_na = TRUE,
                        ...) {
  .require_pkg("e1071")
  prefer <- match.arg(prefer)
  prepared <- .ensure_ikun_data(data, group_col, feature_cols, positive_class, drop_na)
  if (nlevels(prepared$y) != 2L) {
    stop("SVM-RFE currently supports binary classification only.", call. = FALSE)
  }

  x <- as.matrix(prepared$x)
  y <- prepared$y

  .set_seed(seed)
  ranked_internal <- .svm_rfe_rank(
    x = x,
    y = y,
    cost = cost,
    scale = scale,
    halve_above = halve_above,
    ...
  )
  max_features <- min(as.integer(max_features), length(ranked_internal))
  folds <- .create_folds(y, k = nfolds, seed = seed)
  accuracies <- numeric(max_features)

  for (i in seq_len(max_features)) {
    current_features <- ranked_internal[seq_len(i)]
    fold_acc <- numeric(length(folds))
    for (fold_id in seq_along(folds)) {
      test_idx <- folds[[fold_id]]
      train_idx <- setdiff(seq_len(nrow(x)), test_idx)
      model <- e1071::svm(
        x = x[train_idx, current_features, drop = FALSE],
        y = y[train_idx],
        kernel = "linear",
        cost = cost,
        scale = scale,
        ...
      )
      preds <- stats::predict(model, x[test_idx, current_features, drop = FALSE])
      fold_acc[fold_id] <- mean(preds == y[test_idx])
    }
    accuracies[i] <- mean(fold_acc)
  }

  choice <- .select_count(accuracies, maximize = TRUE, tolerance = tolerance, prefer = prefer)
  selected <- ranked_internal[seq_len(choice$optimal_count)]
  ranking <- data.frame(
    feature_internal = ranked_internal,
    feature = .restore_feature_names(ranked_internal, prepared),
    rank = seq_along(ranked_internal),
    stringsAsFactors = FALSE
  )
  cv_metrics <- data.frame(
    n_features = seq_len(max_features),
    accuracy = accuracies,
    error = 1 - accuracies
  )

  .method_result(
    method = "svm_rfe",
    selected_internal = selected,
    prepared = prepared,
    ranking = ranking,
    cv_metrics = cv_metrics,
    optimal_count = choice$optimal_count,
    strict_best_count = choice$strict_best_count,
    best_accuracy = choice$best_value,
    params = list(
      cost = cost,
      scale = scale,
      halve_above = halve_above,
      nfolds = nfolds,
      max_features = max_features,
      tolerance = tolerance,
      prefer = prefer,
      seed = seed
    )
  )
}

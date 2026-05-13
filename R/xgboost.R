run_xgboost <- function(data,
                        group_col = "group",
                        feature_cols = NULL,
                        positive_class = NULL,
                        seed = 123,
                        params = list(),
                        nrounds = 500,
                        cv_nrounds = 100,
                        max_features = 200,
                        nfolds = 5,
                        tolerance = 0,
                        prefer = c("largest", "smallest"),
                        threshold = 0.5,
                        record_eval = TRUE,
                        verbose = 0,
                        drop_na = TRUE,
                        ...) {
  .require_pkg("xgboost")
  prefer <- match.arg(prefer)
  prepared <- .ensure_ikun_data(data, group_col, feature_cols, positive_class, drop_na)

  x <- as.matrix(prepared$x)
  y <- factor(prepared$y)
  labels <- as.integer(y) - 1L
  num_classes <- nlevels(y)

  default_params <- if (num_classes == 2L) {
    list(objective = "binary:logistic", eval_metric = "error")
  } else {
    list(objective = "multi:softmax", num_class = num_classes, eval_metric = "merror")
  }
  xgb_params <- utils::modifyList(default_params, params)

  dtrain <- xgboost::xgb.DMatrix(data = x, label = labels)
  .set_seed(seed)
  extra_args <- list(...)
  train_args <- list(
    params = xgb_params,
    data = dtrain,
    nrounds = nrounds,
    verbose = verbose
  )
  if (record_eval && is.null(extra_args$watchlist)) {
    train_args$watchlist <- list(train = dtrain)
  }
  xgb_model <- do.call(xgboost::xgb.train, c(train_args, extra_args))

  importance_df <- as.data.frame(
    xgboost::xgb.importance(feature_names = colnames(x), model = xgb_model),
    stringsAsFactors = FALSE
  )
  if (nrow(importance_df) == 0L) {
    stop("XGBoost returned no feature importance values.", call. = FALSE)
  }
  importance_df$feature_internal <- importance_df$Feature
  importance_df$feature <- .restore_feature_names(importance_df$feature_internal, prepared)
  importance_df <- importance_df[order(-importance_df$Gain), , drop = FALSE]
  rownames(importance_df) <- NULL

  max_features <- min(as.integer(max_features), nrow(importance_df))
  candidate_features <- importance_df$feature_internal[seq_len(max_features)]
  folds <- .create_folds(y, k = nfolds, seed = seed)
  accuracies <- numeric(max_features)

  for (i in seq_len(max_features)) {
    current_features <- candidate_features[seq_len(i)]
    fold_acc <- numeric(length(folds))

    for (fold_id in seq_along(folds)) {
      test_idx <- folds[[fold_id]]
      train_idx <- setdiff(seq_len(nrow(x)), test_idx)
      dtrain_sub <- xgboost::xgb.DMatrix(
        data = x[train_idx, current_features, drop = FALSE],
        label = labels[train_idx]
      )
      dtest_sub <- xgboost::xgb.DMatrix(
        data = x[test_idx, current_features, drop = FALSE],
        label = labels[test_idx]
      )

      model <- xgboost::xgb.train(
        params = xgb_params,
        data = dtrain_sub,
        nrounds = cv_nrounds,
        verbose = 0
      )
      preds <- stats::predict(model, dtest_sub)
      pred_class <- if (num_classes == 2L) {
        ifelse(preds >= threshold, 1L, 0L)
      } else {
        as.integer(preds)
      }
      fold_acc[fold_id] <- mean(pred_class == labels[test_idx])
    }
    accuracies[i] <- mean(fold_acc)
  }

  choice <- .select_count(accuracies, maximize = TRUE, tolerance = tolerance, prefer = prefer)
  selected <- candidate_features[seq_len(choice$optimal_count)]
  cv_metrics <- data.frame(
    n_features = seq_len(max_features),
    accuracy = accuracies,
    error = 1 - accuracies
  )

  .method_result(
    method = "xgboost",
    selected_internal = selected,
    prepared = prepared,
    importance = importance_df,
    cv_metrics = cv_metrics,
    optimal_count = choice$optimal_count,
    strict_best_count = choice$strict_best_count,
    best_accuracy = choice$best_value,
    model = xgb_model,
    params = list(
      params = xgb_params,
      nrounds = nrounds,
      cv_nrounds = cv_nrounds,
      max_features = max_features,
      nfolds = nfolds,
      tolerance = tolerance,
      prefer = prefer,
      threshold = threshold,
      record_eval = record_eval,
      seed = seed
    )
  )
}

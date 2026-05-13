run_rf <- function(data,
                   group_col = "group",
                   feature_cols = NULL,
                   positive_class = NULL,
                   seed = 123,
                   ntree = 500,
                   importance_type = 1,
                   importance_measure = NULL,
                   scale_importance = TRUE,
                   nfolds = 5,
                   cv_ntree = 500,
                   max_features = 200,
                   tolerance = 0,
                   prefer = c("largest", "smallest"),
                   selection_size = NULL,
                   drop_na = TRUE,
                   ...) {
  .require_pkg("randomForest")
  prefer <- match.arg(prefer)
  prepared <- .ensure_ikun_data(data, group_col, feature_cols, positive_class, drop_na)
  analysis_data <- data.frame(Group = prepared$y, prepared$x, check.names = FALSE)

  .set_seed(seed)
  rf_model <- randomForest::randomForest(
    Group ~ .,
    data = analysis_data,
    ntree = ntree,
    importance = TRUE,
    ...
  )

  importance_matrix <- randomForest::importance(
    rf_model,
    type = importance_type,
    scale = scale_importance
  )
  importance_df <- as.data.frame(importance_matrix, check.names = FALSE)
  importance_df$feature_internal <- rownames(importance_df)

  if (is.null(importance_measure)) {
    candidates <- c("MeanDecreaseAccuracy", "MeanDecreaseGini", "IncNodePurity", "%IncMSE", "IncMSE")
    importance_measure <- candidates[candidates %in% names(importance_df)][1L]
    if (is.na(importance_measure)) {
      numeric_cols <- names(importance_df)[vapply(importance_df, is.numeric, logical(1L))]
      importance_measure <- numeric_cols[length(numeric_cols)]
    }
  }
  if (!importance_measure %in% names(importance_df)) {
    stop("importance_measure was not found in randomForest importance output.", call. = FALSE)
  }

  importance_df$importance <- importance_df[[importance_measure]]
  importance_df$feature <- .restore_feature_names(importance_df$feature_internal, prepared)
  importance_df <- importance_df[order(-importance_df$importance), , drop = FALSE]
  rownames(importance_df) <- NULL

  max_features <- min(as.integer(max_features), nrow(importance_df))
  candidate_features <- importance_df$feature_internal[seq_len(max_features)]

  if (!is.null(selection_size)) {
    optimal_count <- min(as.integer(selection_size), max_features)
    cv_metrics <- NULL
    strict_best_count <- NA_integer_
    best_accuracy <- NA_real_
  } else {
    folds <- .create_folds(prepared$y, k = nfolds, seed = seed)
    accuracies <- numeric(max_features)

    for (i in seq_len(max_features)) {
      current_features <- candidate_features[seq_len(i)]
      fold_acc <- numeric(length(folds))

      for (fold_id in seq_along(folds)) {
        test_idx <- folds[[fold_id]]
        train_idx <- setdiff(seq_len(nrow(analysis_data)), test_idx)
        train_data <- analysis_data[train_idx, c("Group", current_features), drop = FALSE]
        test_data <- analysis_data[test_idx, c("Group", current_features), drop = FALSE]
        model <- randomForest::randomForest(Group ~ ., data = train_data, ntree = cv_ntree)
        preds <- stats::predict(model, test_data)
        fold_acc[fold_id] <- mean(preds == test_data$Group)
      }
      accuracies[i] <- mean(fold_acc)
    }

    choice <- .select_count(accuracies, maximize = TRUE, tolerance = tolerance, prefer = prefer)
    optimal_count <- choice$optimal_count
    strict_best_count <- choice$strict_best_count
    best_accuracy <- choice$best_value
    cv_metrics <- data.frame(
      n_features = seq_len(max_features),
      accuracy = accuracies,
      error = 1 - accuracies
    )
  }

  selected <- candidate_features[seq_len(optimal_count)]

  .method_result(
    method = "rf",
    selected_internal = selected,
    prepared = prepared,
    importance = importance_df,
    cv_metrics = cv_metrics,
    optimal_count = optimal_count,
    strict_best_count = strict_best_count,
    best_accuracy = best_accuracy,
    model = rf_model,
    params = list(
      ntree = ntree,
      importance_type = importance_type,
      importance_measure = importance_measure,
      nfolds = nfolds,
      cv_ntree = cv_ntree,
      max_features = max_features,
      tolerance = tolerance,
      prefer = prefer,
      selection_size = selection_size,
      seed = seed
    )
  )
}

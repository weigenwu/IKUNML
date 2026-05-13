run_rpart <- function(data,
                      group_col = "group",
                      feature_cols = NULL,
                      positive_class = NULL,
                      seed = 123,
                      cp = 0.01,
                      minsplit = 20,
                      maxdepth = 30,
                      xval = 10,
                      nfolds = 5,
                      max_features = 200,
                      tolerance = 0,
                      prefer = c("largest", "smallest"),
                      selection_size = NULL,
                      drop_na = TRUE,
                      ...) {
  .require_pkg("rpart")
  prefer <- match.arg(prefer)
  prepared <- .ensure_ikun_data(data, group_col, feature_cols, positive_class, drop_na)
  analysis_data <- data.frame(Group = prepared$y, prepared$x, check.names = FALSE)
  ctrl <- rpart::rpart.control(cp = cp, minsplit = minsplit, maxdepth = maxdepth, xval = xval, ...)

  .set_seed(seed)
  tree_model <- rpart::rpart(Group ~ ., data = analysis_data, method = "class", control = ctrl)
  importance_values <- tree_model$variable.importance
  if (is.null(importance_values) || length(importance_values) == 0L) {
    stop("rpart did not split on any feature. Try a smaller cp or minsplit.", call. = FALSE)
  }

  importance <- data.frame(
    feature_internal = names(importance_values),
    importance = as.numeric(importance_values),
    stringsAsFactors = FALSE
  )
  importance$feature <- .restore_feature_names(importance$feature_internal, prepared)
  importance <- importance[order(-importance$importance), , drop = FALSE]
  rownames(importance) <- NULL

  max_features <- min(as.integer(max_features), nrow(importance))
  candidate_features <- importance$feature_internal[seq_len(max_features)]

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
        model <- rpart::rpart(Group ~ ., data = train_data, method = "class", control = ctrl)
        preds <- stats::predict(model, test_data, type = "class")
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
  ranking <- data.frame(
    feature_internal = importance$feature_internal,
    feature = importance$feature,
    rank = seq_len(nrow(importance)),
    importance = importance$importance,
    stringsAsFactors = FALSE
  )

  .method_result(
    method = "rpart",
    selected_internal = selected,
    prepared = prepared,
    ranking = ranking,
    importance = importance,
    cv_metrics = cv_metrics,
    optimal_count = optimal_count,
    strict_best_count = strict_best_count,
    best_accuracy = best_accuracy,
    model = tree_model,
    params = list(
      cp = cp,
      minsplit = minsplit,
      maxdepth = maxdepth,
      xval = xval,
      nfolds = nfolds,
      max_features = max_features,
      tolerance = tolerance,
      prefer = prefer,
      selection_size = selection_size,
      seed = seed
    )
  )
}

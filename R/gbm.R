run_gbm <- function(data,
                    group_col = "group",
                    feature_cols = NULL,
                    positive_class = NULL,
                    seed = 123,
                    n.trees = 500,
                    interaction.depth = 3,
                    shrinkage = 0.05,
                    n.minobsinnode = 10,
                    bag.fraction = 0.5,
                    cv_n.trees = 100,
                    nfolds = 5,
                    max_features = 200,
                    tolerance = 0,
                    prefer = c("largest", "smallest"),
                    selection_size = NULL,
                    threshold = 0.5,
                    verbose = FALSE,
                    drop_na = TRUE,
                    ...) {
  .require_pkg("gbm")
  prefer <- match.arg(prefer)
  prepared <- .ensure_ikun_data(data, group_col, feature_cols, positive_class, drop_na)
  if (nlevels(prepared$y) != 2L) {
    stop("GBM feature selection currently supports binary classification only.", call. = FALSE)
  }

  labels <- .binary_label(prepared$y, positive_class %||% prepared$positive_class)
  model_data <- data.frame(Group = labels, prepared$x, check.names = FALSE)

  .set_seed(seed)
  gbm_model <- gbm::gbm(
    Group ~ .,
    data = model_data,
    distribution = "bernoulli",
    n.trees = n.trees,
    interaction.depth = interaction.depth,
    shrinkage = shrinkage,
    n.minobsinnode = n.minobsinnode,
    bag.fraction = bag.fraction,
    train.fraction = 1,
    verbose = verbose,
    ...
  )

  importance <- gbm::summary.gbm(gbm_model, plotit = FALSE)
  names(importance)[names(importance) == "var"] <- "feature_internal"
  names(importance)[names(importance) == "rel.inf"] <- "importance"
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
        train_idx <- setdiff(seq_len(nrow(model_data)), test_idx)
        train_data <- model_data[train_idx, c("Group", current_features), drop = FALSE]
        test_data <- model_data[test_idx, c("Group", current_features), drop = FALSE]
        model <- gbm::gbm(
          Group ~ .,
          data = train_data,
          distribution = "bernoulli",
          n.trees = cv_n.trees,
          interaction.depth = interaction.depth,
          shrinkage = shrinkage,
          n.minobsinnode = n.minobsinnode,
          bag.fraction = bag.fraction,
          train.fraction = 1,
          verbose = FALSE
        )
        probs <- stats::predict(model, test_data, n.trees = cv_n.trees, type = "response")
        preds <- ifelse(probs >= threshold, 1L, 0L)
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
    method = "gbm",
    selected_internal = selected,
    prepared = prepared,
    ranking = ranking,
    importance = importance,
    cv_metrics = cv_metrics,
    optimal_count = optimal_count,
    strict_best_count = strict_best_count,
    best_accuracy = best_accuracy,
    model = gbm_model,
    params = list(
      n.trees = n.trees,
      interaction.depth = interaction.depth,
      shrinkage = shrinkage,
      n.minobsinnode = n.minobsinnode,
      bag.fraction = bag.fraction,
      cv_n.trees = cv_n.trees,
      nfolds = nfolds,
      max_features = max_features,
      tolerance = tolerance,
      prefer = prefer,
      selection_size = selection_size,
      threshold = threshold,
      seed = seed
    )
  )
}

.caret_rfe_functions <- function(functions) {
  if (is.list(functions)) {
    return(functions)
  }
  functions <- match.arg(functions, c("rf", "treebag", "caret"))
  switch(
    functions,
    rf = caret::rfFuncs,
    treebag = caret::treebagFuncs,
    caret = caret::caretFuncs
  )
}

run_caret_rfe <- function(data,
                          group_col = "group",
                          feature_cols = NULL,
                          positive_class = NULL,
                          seed = 123,
                          sizes = NULL,
                          max_features = 200,
                          functions = c("rf", "treebag", "caret"),
                          method = "cv",
                          number = 5,
                          metric = NULL,
                          maximize = NULL,
                          rfe_control_args = list(),
                          drop_na = TRUE,
                          ...) {
  .require_pkg("caret")
  functions <- .caret_rfe_functions(functions)
  prepared <- .ensure_ikun_data(data, group_col, feature_cols, positive_class, drop_na)

  max_features <- min(as.integer(max_features), ncol(prepared$x))
  if (is.null(sizes)) {
    sizes <- unique(sort(c(seq_len(min(10L, max_features)), seq(20L, max_features, by = 10L), max_features)))
  }
  sizes <- sort(unique(as.integer(sizes[sizes >= 1L & sizes <= ncol(prepared$x)])))
  if (length(sizes) == 0L) {
    stop("sizes must contain at least one valid feature count.", call. = FALSE)
  }

  if (is.null(metric)) {
    metric <- if (nlevels(prepared$y) == 2L) "Accuracy" else "Accuracy"
  }
  if (is.null(maximize)) {
    maximize <- !metric %in% c("RMSE", "MAE", "logLoss")
  }

  ctrl_args <- utils::modifyList(
    list(functions = functions, method = method, number = number, verbose = FALSE),
    rfe_control_args
  )
  rfe_ctrl <- do.call(caret::rfeControl, ctrl_args)

  .set_seed(seed)
  rfe_model <- caret::rfe(
    x = prepared$x,
    y = prepared$y,
    sizes = sizes,
    rfeControl = rfe_ctrl,
    metric = metric,
    maximize = maximize,
    ...
  )

  selected <- rfe_model$optVariables %||% caret::predictors(rfe_model)
  selected <- intersect(selected, prepared$feature_map$internal)

  variables <- rfe_model$variables
  if (!is.null(variables) && "var" %in% names(variables)) {
    score_col <- c("Overall", "Accuracy", "Kappa", "ROC")[c("Overall", "Accuracy", "Kappa", "ROC") %in% names(variables)][1L]
    if (!is.na(score_col)) {
      importance <- stats::aggregate(variables[[score_col]], list(feature_internal = variables$var), mean, na.rm = TRUE)
      names(importance)[2L] <- "importance"
    } else {
      importance <- data.frame(feature_internal = unique(variables$var), importance = NA_real_)
    }
  } else {
    importance <- data.frame(feature_internal = selected, importance = seq_along(selected), stringsAsFactors = FALSE)
  }
  importance$feature <- .restore_feature_names(importance$feature_internal, prepared)
  importance <- importance[order(-importance$importance), , drop = FALSE]
  rownames(importance) <- NULL

  ranking <- data.frame(
    feature_internal = importance$feature_internal,
    feature = importance$feature,
    rank = seq_len(nrow(importance)),
    importance = importance$importance,
    stringsAsFactors = FALSE
  )

  cv_metrics <- rfe_model$results
  if (!is.null(cv_metrics)) {
    cv_metrics <- as.data.frame(cv_metrics)
    if ("Variables" %in% names(cv_metrics)) {
      names(cv_metrics)[names(cv_metrics) == "Variables"] <- "n_features"
    }
    if ("Accuracy" %in% names(cv_metrics)) {
      cv_metrics$accuracy <- cv_metrics$Accuracy
      cv_metrics$error <- 1 - cv_metrics$Accuracy
    }
  }

  .method_result(
    method = "caret_rfe",
    selected_internal = selected,
    prepared = prepared,
    ranking = ranking,
    importance = importance,
    cv_metrics = cv_metrics,
    optimal_count = length(selected),
    best_accuracy = if (!is.null(cv_metrics) && "accuracy" %in% names(cv_metrics)) max(cv_metrics$accuracy, na.rm = TRUE) else NA_real_,
    model = rfe_model,
    params = list(
      sizes = sizes,
      max_features = max_features,
      method = method,
      number = number,
      metric = metric,
      maximize = maximize,
      seed = seed
    )
  )
}

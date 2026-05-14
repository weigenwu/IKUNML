nested_cv_feature_selection <- function(data,
                                        group_col = "group",
                                        feature_cols = NULL,
                                        methods = c("lasso", "rf"),
                                        method_params = list(),
                                        positive_class = NULL,
                                        model = c("glm", "randomForest", "svm"),
                                        outer_folds = 5,
                                        min_hits = NULL,
                                        fallback_min_hits = 1,
                                        max_fallback_features = 30,
                                        seed = 123,
                                        threshold = 0.5,
                                        output_dir = NULL,
                                        parallel = FALSE,
                                        cores = NULL,
                                        progress = TRUE,
                                        drop_na = TRUE,
                                        ...) {
  model <- match.arg(model)
  methods <- .normalize_methods(methods)
  prepared <- prepare_ikun_data(
    data = data,
    group_col = group_col,
    feature_cols = feature_cols,
    positive_class = positive_class,
    drop_na = drop_na
  )
  if (!is.data.frame(data)) {
    data <- as.data.frame(data, check.names = FALSE)
  }
  clean_data <- data[prepared$samples, c(prepared$group_col, prepared$feature_cols), drop = FALSE]
  folds <- .create_folds(prepared$y, k = outer_folds, seed = seed)
  positive_class <- positive_class %||% prepared$positive_class %||% levels(prepared$y)[2L]

  started_at <- Sys.time()

  fold_runner <- function(fold_id) {
    if (isTRUE(progress)) {
      message("[IKUNML] Nested CV fold ", fold_id, "/", length(folds))
    }
    test_idx <- folds[[fold_id]]
    train_idx <- setdiff(seq_len(nrow(clean_data)), test_idx)
    train_data <- clean_data[train_idx, , drop = FALSE]
    test_data <- clean_data[test_idx, , drop = FALSE]

    selection <- run_feature_selection(
      data = train_data,
      group_col = prepared$group_col,
      feature_cols = prepared$feature_cols,
      methods = methods,
      method_params = method_params,
      positive_class = positive_class,
      seed = seed + fold_id,
      output_dir = NULL,
      write_plots = FALSE,
      progress = FALSE,
      continue_on_error = TRUE,
      drop_na = drop_na
    )

    selected <- feature_intersection(selection, min_hits = min_hits)
    if (length(selected) == 0L && !is.null(fallback_min_hits)) {
      hit_summary <- feature_hit_summary(selection)
      selected <- utils::head(
        hit_summary$feature[hit_summary$Hit_Count >= fallback_min_hits],
        max_fallback_features
      )
    }
    if (length(selected) == 0L) {
      stop("Nested CV fold ", fold_id, " selected no features.", call. = FALSE)
    }

    validation <- validate_selected_features(
      data = train_data,
      test_data = test_data,
      features = selected,
      group_col = prepared$group_col,
      positive_class = positive_class,
      model = model,
      threshold = threshold,
      output_dir = NULL,
      drop_na = drop_na,
      ...
    )
    fold_result <- list(
      selection = selection,
      validation = validation,
      features = selected
    )
    fold_metric <- validation$metrics
    fold_metric$fold <- fold_id
    fold_metric$n_features <- length(selected)
    list(fold_result = fold_result, fold_metric = fold_metric)
  }

  fold_outputs <- .parallel_lapply(seq_along(folds), fold_runner, parallel = parallel, cores = cores)
  fold_results <- lapply(fold_outputs, `[[`, "fold_result")
  metrics <- lapply(fold_outputs, `[[`, "fold_metric")

  metrics <- do.call(rbind, metrics)
  rownames(metrics) <- NULL
  summary <- data.frame(
    metric = c("accuracy", "sensitivity", "specificity", "precision", "auc", "n_features"),
    mean = c(
      mean(metrics$accuracy, na.rm = TRUE),
      mean(metrics$sensitivity, na.rm = TRUE),
      mean(metrics$specificity, na.rm = TRUE),
      mean(metrics$precision, na.rm = TRUE),
      mean(metrics$auc, na.rm = TRUE),
      mean(metrics$n_features, na.rm = TRUE)
    ),
    sd = c(
      stats::sd(metrics$accuracy, na.rm = TRUE),
      stats::sd(metrics$sensitivity, na.rm = TRUE),
      stats::sd(metrics$specificity, na.rm = TRUE),
      stats::sd(metrics$precision, na.rm = TRUE),
      stats::sd(metrics$auc, na.rm = TRUE),
      stats::sd(metrics$n_features, na.rm = TRUE)
    ),
    stringsAsFactors = FALSE
  )
  completed_at <- Sys.time()

  out <- structure(
    list(
      summary = summary,
      fold_metrics = metrics,
      fold_results = fold_results,
      methods = methods,
      model_type = model,
      positive_class = positive_class,
      runtime_seconds = as.numeric(difftime(completed_at, started_at, units = "secs")),
      params = list(
        outer_folds = outer_folds,
        min_hits = min_hits,
        fallback_min_hits = fallback_min_hits,
        max_fallback_features = max_fallback_features,
        seed = seed,
        parallel = parallel,
        cores = cores
      )
    ),
    class = "ikun_nested_cv_result"
  )
  if (!is.null(output_dir)) {
    write_nested_cv_results(out, output_dir = output_dir)
  }
  out
}

write_nested_cv_results <- function(result, output_dir = "IKUNML_nested_cv") {
  if (!inherits(result, "ikun_nested_cv_result")) {
    stop("result must be produced by nested_cv_feature_selection().", call. = FALSE)
  }
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }
  utils::write.csv(result$summary, file.path(output_dir, "nested_cv_summary.csv"), row.names = FALSE)
  utils::write.csv(result$fold_metrics, file.path(output_dir, "nested_cv_fold_metrics.csv"), row.names = FALSE)
  feature_rows <- lapply(seq_along(result$fold_results), function(i) {
    data.frame(fold = i, feature = result$fold_results[[i]]$features, stringsAsFactors = FALSE)
  })
  utils::write.csv(do.call(rbind, feature_rows), file.path(output_dir, "nested_cv_features_by_fold.csv"), row.names = FALSE)
  saveRDS(result, file.path(output_dir, "nested_cv_result.rds"))
  invisible(output_dir)
}

print.ikun_nested_cv_result <- function(x, ...) {
  cat("IKUNML nested CV result\n")
  cat("Model:", x$model_type, "\n")
  cat("Runtime:", sprintf("%.2f seconds", x$runtime_seconds), "\n")
  print(x$summary)
  invisible(x)
}

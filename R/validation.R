.features_from_selection <- function(result = NULL, features = NULL, methods = NULL, min_hits = NULL) {
  if (!is.null(features)) {
    return(unique(as.character(features)))
  }
  if (is.null(result)) {
    stop("Provide either result or features.", call. = FALSE)
  }
  if (!is.null(min_hits)) {
    return(feature_intersection(result, methods = methods, min_hits = min_hits))
  }
  feature_intersection(result, methods = methods)
}

.train_test_split <- function(y, train_fraction = 0.7, seed = NULL) {
  .stratified_sample_indices(y, fraction = train_fraction, seed = seed)
}

.binary_auc <- function(labels, scores) {
  labels <- as.integer(labels)
  pos <- labels == 1L
  n_pos <- sum(pos)
  n_neg <- sum(!pos)
  if (n_pos == 0L || n_neg == 0L) {
    return(NA_real_)
  }
  ranks <- rank(scores, ties.method = "average")
  (sum(ranks[pos]) - n_pos * (n_pos + 1) / 2) / (n_pos * n_neg)
}

.roc_table <- function(labels, scores) {
  labels <- as.integer(labels)
  thresholds <- sort(unique(c(Inf, scores, -Inf)), decreasing = TRUE)
  rows <- lapply(thresholds, function(threshold) {
    pred <- as.integer(scores >= threshold)
    tp <- sum(pred == 1L & labels == 1L)
    fp <- sum(pred == 1L & labels == 0L)
    tn <- sum(pred == 0L & labels == 0L)
    fn <- sum(pred == 0L & labels == 1L)
    data.frame(
      threshold = threshold,
      sensitivity = if ((tp + fn) == 0L) NA_real_ else tp / (tp + fn),
      specificity = if ((tn + fp) == 0L) NA_real_ else tn / (tn + fp),
      fpr = if ((tn + fp) == 0L) NA_real_ else fp / (tn + fp),
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}

.classification_metrics <- function(truth, score, threshold = 0.5) {
  truth <- as.integer(truth)
  pred <- as.integer(score >= threshold)
  tp <- sum(pred == 1L & truth == 1L)
  fp <- sum(pred == 1L & truth == 0L)
  tn <- sum(pred == 0L & truth == 0L)
  fn <- sum(pred == 0L & truth == 1L)
  data.frame(
    accuracy = mean(pred == truth),
    sensitivity = if ((tp + fn) == 0L) NA_real_ else tp / (tp + fn),
    specificity = if ((tn + fp) == 0L) NA_real_ else tn / (tn + fp),
    precision = if ((tp + fp) == 0L) NA_real_ else tp / (tp + fp),
    auc = .binary_auc(truth, score),
    threshold = threshold,
    TP = tp,
    FP = fp,
    TN = tn,
    FN = fn,
    stringsAsFactors = FALSE
  )
}

.fit_predict_classifier <- function(train_x,
                                    train_y,
                                    test_x,
                                    model = c("glm", "randomForest", "svm"),
                                    positive_class,
                                    ...) {
  model <- match.arg(model)
  if (identical(model, "glm")) {
    train_label <- as.integer(train_y == positive_class)
    train_df <- data.frame(.y = train_label, train_x, check.names = FALSE)
    fit <- stats::glm(.y ~ ., data = train_df, family = stats::binomial(), ...)
    score <- stats::predict(fit, newdata = as.data.frame(test_x, check.names = FALSE), type = "response")
  } else if (identical(model, "randomForest")) {
    .require_pkg("randomForest")
    fit <- randomForest::randomForest(x = train_x, y = train_y, ...)
    prob <- stats::predict(fit, test_x, type = "prob")
    score <- prob[, positive_class]
  } else {
    .require_pkg("e1071")
    fit <- e1071::svm(x = train_x, y = train_y, probability = TRUE, ...)
    pred <- stats::predict(fit, test_x, probability = TRUE)
    prob <- attr(pred, "probabilities")
    score <- prob[, positive_class]
  }
  list(model = fit, score = as.numeric(score))
}

.write_validation_roc <- function(validation, output_dir, plot_formats = c("pdf", "tiff"), tiff_res = 300) {
  old_formats <- getOption("IKUNML.plot_formats")
  old_tiff_res <- getOption("IKUNML.tiff_res")
  options(IKUNML.plot_formats = plot_formats, IKUNML.tiff_res = tiff_res)
  on.exit(options(IKUNML.plot_formats = old_formats, IKUNML.tiff_res = old_tiff_res), add = TRUE)
  .write_pdf_plot(
    file.path(output_dir, "validation_ROC.pdf"),
    6,
    5,
    function() {
      graphics::plot(
        validation$roc$fpr,
        validation$roc$sensitivity,
        type = "l",
        lwd = 2,
        col = "#4DBBD5",
        xlab = "1 - Specificity",
        ylab = "Sensitivity",
        main = sprintf("Validation ROC (AUC = %.3f)", validation$metrics$auc[[1L]])
      )
      graphics::abline(0, 1, lty = 2, col = "gray50")
    }
  )
}

validate_selected_features <- function(data,
                                       result = NULL,
                                       features = NULL,
                                       methods = NULL,
                                       min_hits = NULL,
                                       group_col = "group",
                                       positive_class = NULL,
                                       model = c("glm", "randomForest", "svm"),
                                       train_fraction = 0.7,
                                       test_data = NULL,
                                       seed = 123,
                                       threshold = 0.5,
                                       output_dir = NULL,
                                       plot_formats = c("pdf", "tiff"),
                                       tiff_res = 300,
                                       drop_na = TRUE,
                                       ...) {
  model <- match.arg(model)
  features <- .features_from_selection(result = result, features = features, methods = methods, min_hits = min_hits)
  if (length(features) == 0L) {
    stop("No features were selected for validation.", call. = FALSE)
  }

  train_prepared <- prepare_ikun_data(
    data = data,
    group_col = group_col,
    feature_cols = features,
    positive_class = positive_class,
    drop_na = drop_na
  )
  if (nlevels(train_prepared$y) != 2L) {
    stop("validate_selected_features() currently supports binary classification only.", call. = FALSE)
  }
  positive_class <- positive_class %||% train_prepared$positive_class %||% levels(train_prepared$y)[2L]

  if (is.null(test_data)) {
    train_idx <- .train_test_split(train_prepared$y, train_fraction = train_fraction, seed = seed)
    test_idx <- setdiff(seq_along(train_prepared$y), train_idx)
    train_x <- train_prepared$x[train_idx, , drop = FALSE]
    train_y <- train_prepared$y[train_idx]
    test_x <- train_prepared$x[test_idx, , drop = FALSE]
    test_y <- train_prepared$y[test_idx]
  } else {
    test_prepared <- prepare_ikun_data(
      data = test_data,
      group_col = group_col,
      feature_cols = features,
      positive_class = positive_class,
      drop_na = drop_na
    )
    train_x <- train_prepared$x
    train_y <- train_prepared$y
    test_x <- test_prepared$x
    test_y <- factor(test_prepared$y, levels = levels(train_prepared$y))
  }

  fit <- .fit_predict_classifier(
    train_x = train_x,
    train_y = train_y,
    test_x = test_x,
    model = model,
    positive_class = positive_class,
    ...
  )
  truth <- as.integer(test_y == positive_class)
  metrics <- .classification_metrics(truth, fit$score, threshold = threshold)
  roc <- .roc_table(truth, fit$score)
  predictions <- data.frame(
    sample = names(test_y) %||% seq_along(test_y),
    truth = as.character(test_y),
    score = fit$score,
    predicted = ifelse(fit$score >= threshold, positive_class, setdiff(levels(train_prepared$y), positive_class)[1L]),
    stringsAsFactors = FALSE
  )

  out <- structure(
    list(
      metrics = metrics,
      roc = roc,
      predictions = predictions,
      model = fit$model,
      features = features,
      model_type = model,
      positive_class = positive_class,
      threshold = threshold
    ),
    class = "ikun_validation_result"
  )
  if (!is.null(output_dir)) {
    write_validation_results(out, output_dir = output_dir, plot_formats = plot_formats, tiff_res = tiff_res)
  }
  out
}

write_validation_results <- function(result,
                                     output_dir = "IKUNML_validation",
                                     plot_formats = c("pdf", "tiff"),
                                     tiff_res = 300) {
  if (!inherits(result, "ikun_validation_result")) {
    stop("result must be produced by validate_selected_features().", call. = FALSE)
  }
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }
  utils::write.csv(result$metrics, file.path(output_dir, "validation_metrics.csv"), row.names = FALSE)
  utils::write.csv(result$predictions, file.path(output_dir, "validation_predictions.csv"), row.names = FALSE)
  utils::write.csv(result$roc, file.path(output_dir, "validation_roc.csv"), row.names = FALSE)
  utils::write.table(result$features, file.path(output_dir, "validation_features.txt"), quote = FALSE, row.names = FALSE, col.names = FALSE)
  saveRDS(result$model, file.path(output_dir, "validation_model.rds"))
  .write_validation_roc(result, output_dir, plot_formats = plot_formats, tiff_res = tiff_res)
  invisible(output_dir)
}

print.ikun_validation_result <- function(x, ...) {
  cat("IKUNML validation result\n")
  cat("Model:", x$model_type, "\n")
  cat("Features:", length(x$features), "\n")
  print(x$metrics)
  invisible(x)
}

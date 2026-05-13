.write_pdf_plot <- function(file, width, height, plotter) {
  grDevices::pdf(file, width = width, height = height)
  on.exit(grDevices::dev.off(), add = TRUE)
  plotter()
  invisible(file)
}

.plot_metric_curve <- function(metrics, y_col, title, ylab, color = "#4DBBD5") {
  if (is.null(metrics) || !y_col %in% names(metrics) || nrow(metrics) == 0L) {
    return(invisible(FALSE))
  }
  graphics::plot(
    metrics$n_features,
    metrics[[y_col]],
    type = "b",
    pch = 16,
    col = color,
    lwd = 2,
    xlab = "Number of Features",
    ylab = ylab,
    main = title
  )
  invisible(TRUE)
}

.plot_top_bar <- function(table,
                          value_col,
                          feature_col = "feature",
                          top_n = 30,
                          title = "Top Features",
                          ylab = "Importance",
                          color = "#A0D8EA") {
  if (is.null(table) || !value_col %in% names(table) || !feature_col %in% names(table)) {
    return(invisible(FALSE))
  }
  plot_table <- utils::head(table, top_n)
  values <- plot_table[[value_col]]
  names(values) <- plot_table[[feature_col]]
  opar <- graphics::par(no.readonly = TRUE)
  on.exit(graphics::par(opar), add = TRUE)
  graphics::par(mar = c(5, 10, 4, 2))
  graphics::barplot(
    rev(values),
    horiz = TRUE,
    las = 1,
    col = color,
    border = NA,
    main = title,
    xlab = ylab
  )
  invisible(TRUE)
}

.plot_lasso_diagnostics <- function(method_result, method_dir) {
  if (!is.null(method_result$model)) {
    .write_pdf_plot(
      file.path(method_dir, paste0(method_result$method, "_coefficient_path.pdf")),
      7,
      5,
      function() graphics::plot(method_result$model, xvar = "lambda", label = TRUE)
    )
  }
  if (!is.null(method_result$cvfit)) {
    .write_pdf_plot(
      file.path(method_dir, paste0(method_result$method, "_cv_curve.pdf")),
      7,
      5,
      function() graphics::plot(method_result$cvfit)
    )
  }
}

.plot_boruta_diagnostics <- function(method_result, method_dir) {
  .require_pkg("Boruta")
  if (!is.null(method_result$model)) {
    .write_pdf_plot(
      file.path(method_dir, "boruta_importance.pdf"),
      9,
      6,
      function() graphics::plot(
        method_result$model,
        las = 3,
        xlab = "",
        ylab = "Importance: Z-score",
        main = "Boruta Feature Importance"
      )
    )
    .write_pdf_plot(
      file.path(method_dir, "boruta_importance_history.pdf"),
      9,
      6,
      function() Boruta::plotImpHistory(
        method_result$model,
        xlab = "Random Forest Run",
        ylab = "Importance: Z-score",
        main = "Boruta Importance History"
      )
    )
  }
}

.plot_svm_diagnostics <- function(method_result, method_dir, top_n) {
  if (!is.null(method_result$cv_metrics)) {
    .write_pdf_plot(
      file.path(method_dir, "svm_rfe_accuracy.pdf"),
      7,
      5,
      function() {
        .plot_metric_curve(method_result$cv_metrics, "accuracy", "SVM-RFE Accuracy", "Classification Accuracy")
        if (!is.null(method_result$best_accuracy)) {
          graphics::abline(h = method_result$best_accuracy, col = "#E64B35", lty = 2, lwd = 2)
        }
      }
    )
    .write_pdf_plot(
      file.path(method_dir, "svm_rfe_error.pdf"),
      7,
      5,
      function() .plot_metric_curve(
        method_result$cv_metrics,
        "error",
        "SVM-RFE Error Rate",
        "Classification Error Rate",
        color = "#E64B35"
      )
    )
  }
  if (!is.null(method_result$ranking)) {
    ranking <- method_result$ranking
    ranking$score <- max(ranking$rank, na.rm = TRUE) - ranking$rank + 1
    .write_pdf_plot(
      file.path(method_dir, "svm_rfe_top_features.pdf"),
      9,
      7,
      function() .plot_top_bar(
        ranking,
        value_col = "score",
        top_n = top_n,
        title = "Top Features Selected by SVM-RFE",
        ylab = "Reverse Rank Score"
      )
    )
  }
}

.plot_rf_diagnostics <- function(method_result, method_dir, top_n) {
  if (!is.null(method_result$model)) {
    .write_pdf_plot(
      file.path(method_dir, "rf_error_rate.pdf"),
      7,
      5,
      function() graphics::plot(method_result$model, main = "Random Forest Error Rate", lwd = 2)
    )
  }
  if (!is.null(method_result$cv_metrics)) {
    .write_pdf_plot(
      file.path(method_dir, "rf_cv_accuracy.pdf"),
      8,
      5,
      function() {
        .plot_metric_curve(method_result$cv_metrics, "accuracy", "Random Forest Feature Selection", "CV Accuracy")
        if (!is.null(method_result$optimal_count)) {
          graphics::abline(v = method_result$optimal_count, col = "#E64B35", lty = 2, lwd = 2)
        }
      }
    )
  }
  .write_pdf_plot(
    file.path(method_dir, "rf_top_features.pdf"),
    9,
    7,
    function() .plot_top_bar(
      method_result$importance,
      value_col = "importance",
      top_n = top_n,
      title = "Top Features by Random Forest",
      ylab = method_result$params$importance_measure %||% "Importance"
    )
  )
}

.plot_xgboost_diagnostics <- function(method_result, method_dir, top_n) {
  eval_log <- method_result$model$evaluation_log
  if (!is.null(eval_log) && nrow(eval_log) > 0L && ncol(eval_log) >= 2L) {
    eval_log <- as.data.frame(eval_log)
    .write_pdf_plot(
      file.path(method_dir, "xgboost_training_metric.pdf"),
      7,
      5,
      function() graphics::plot(
        eval_log[[1L]],
        eval_log[[2L]],
        type = "l",
        col = "#E64B35",
        lwd = 2,
        xlab = names(eval_log)[1L],
        ylab = names(eval_log)[2L],
        main = "XGBoost Training Metric"
      )
    )
  }
  if (!is.null(method_result$cv_metrics)) {
    .write_pdf_plot(
      file.path(method_dir, "xgboost_cv_accuracy.pdf"),
      8,
      5,
      function() {
        .plot_metric_curve(method_result$cv_metrics, "accuracy", "XGBoost Feature Selection", "CV Accuracy")
        if (!is.null(method_result$optimal_count)) {
          graphics::abline(v = method_result$optimal_count, col = "#E64B35", lty = 2, lwd = 2)
        }
      }
    )
  }
  .write_pdf_plot(
    file.path(method_dir, "xgboost_top_features.pdf"),
    9,
    7,
    function() .plot_top_bar(
      method_result$importance,
      value_col = "Gain",
      top_n = top_n,
      title = "Top Features by XGBoost",
      ylab = "Gain"
    )
  )
}

.plot_ga_diagnostics <- function(method_result, method_dir) {
  if (!is.null(method_result$model)) {
    .write_pdf_plot(
      file.path(method_dir, "ga_evolution_accuracy.pdf"),
      8,
      5,
      function() graphics::plot(method_result$model, main = "Genetic Algorithm Accuracy Across Generations")
    )
  }
}

write_ikun_plots <- function(result,
                             output_dir = "IKUNML_results",
                             methods = NULL,
                             top_n = 30) {
  if (!inherits(result, "ikunml_result")) {
    stop("result must be produced by run_feature_selection().", call. = FALSE)
  }
  completed <- names(result$results)
  methods <- methods %||% completed
  methods <- intersect(.normalize_methods(methods), completed)
  if (length(methods) == 0L) {
    stop("No completed methods were selected for plotting.", call. = FALSE)
  }
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  for (method in methods) {
    method_result <- result$results[[method]]
    method_dir <- file.path(output_dir, method)
    if (!dir.exists(method_dir)) {
      dir.create(method_dir, recursive = TRUE)
    }

    if (method %in% c("lasso", "elastic_net")) {
      .plot_lasso_diagnostics(method_result, method_dir)
    } else if (identical(method, "boruta")) {
      .plot_boruta_diagnostics(method_result, method_dir)
    } else if (identical(method, "svm_rfe")) {
      .plot_svm_diagnostics(method_result, method_dir, top_n = top_n)
    } else if (identical(method, "rf")) {
      .plot_rf_diagnostics(method_result, method_dir, top_n = top_n)
    } else if (identical(method, "xgboost")) {
      .plot_xgboost_diagnostics(method_result, method_dir, top_n = top_n)
    } else if (identical(method, "ga")) {
      .plot_ga_diagnostics(method_result, method_dir)
    }
  }

  invisible(output_dir)
}

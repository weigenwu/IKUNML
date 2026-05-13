write_ikun_results <- function(result, output_dir = "IKUNML_results", overwrite = TRUE) {
  if (!inherits(result, "ikunml_result")) {
    stop("result must be produced by run_feature_selection().", call. = FALSE)
  }

  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  for (method in names(result$results)) {
    method_result <- result$results[[method]]
    method_dir <- file.path(output_dir, method)
    if (!dir.exists(method_dir)) {
      dir.create(method_dir, recursive = TRUE)
    }

    utils::write.table(
      method_result$selected_features,
      file = file.path(method_dir, paste0(method, "_selected_features.txt")),
      quote = FALSE,
      row.names = FALSE,
      col.names = FALSE
    )

    if (!is.null(method_result$coefficients)) {
      utils::write.csv(
        method_result$coefficients,
        file = file.path(method_dir, paste0(method, "_coefficients.csv")),
        row.names = FALSE
      )
    }
    if (!is.null(method_result$stats)) {
      utils::write.csv(
        method_result$stats,
        file = file.path(method_dir, paste0(method, "_stats.csv")),
        row.names = FALSE
      )
    }
    if (!is.null(method_result$ranking)) {
      utils::write.csv(
        method_result$ranking,
        file = file.path(method_dir, paste0(method, "_ranking.csv")),
        row.names = FALSE
      )
    }
    if (!is.null(method_result$importance)) {
      utils::write.csv(
        method_result$importance,
        file = file.path(method_dir, paste0(method, "_importance.csv")),
        row.names = FALSE
      )
    }
    if (!is.null(method_result$cv_metrics)) {
      utils::write.csv(
        method_result$cv_metrics,
        file = file.path(method_dir, paste0(method, "_cv_metrics.csv")),
        row.names = FALSE
      )
    }
  }

  hit_summary <- feature_hit_summary(result)
  utils::write.csv(
    hit_summary,
    file = file.path(output_dir, "feature_hit_summary.csv"),
    row.names = FALSE
  )

  common <- feature_intersection(result)
  utils::write.table(
    common,
    file = file.path(output_dir, "common_features.txt"),
    quote = FALSE,
    row.names = FALSE,
    col.names = FALSE
  )

  if (length(result$errors) > 0L) {
    error_table <- data.frame(
      method = names(result$errors),
      error = unlist(result$errors, use.names = FALSE),
      stringsAsFactors = FALSE
    )
    utils::write.csv(error_table, file.path(output_dir, "method_errors.csv"), row.names = FALSE)
  }

  invisible(output_dir)
}

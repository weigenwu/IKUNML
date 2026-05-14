run_feature_selection <- function(data,
                                  group_col = "group",
                                  feature_cols = NULL,
                                  methods = c("lasso", "boruta", "rf", "xgboost"),
                                  method_params = list(),
                                  positive_class = NULL,
                                  seed = 123,
                                  output_dir = "IKUNML_results",
                                  write_plots = TRUE,
                                  save_models = FALSE,
                                  plot_formats = c("pdf", "tiff"),
                                  tiff_res = 300,
                                  folder_names = NULL,
                                  progress = TRUE,
                                  continue_on_error = FALSE,
                                  drop_na = TRUE) {
  methods <- .normalize_methods(methods)
  prepared <- prepare_ikun_data(
    data = data,
    group_col = group_col,
    feature_cols = feature_cols,
    positive_class = positive_class,
    drop_na = drop_na
  )

  runners <- list(
    lasso = run_lasso,
    elastic_net = run_elastic_net,
    boruta = run_boruta,
    SVM = run_svm_rfe,
    rf = run_rf,
    caret_rfe = run_caret_rfe,
    gbm = run_gbm,
    rpart = run_rpart,
    xgboost = run_xgboost,
    ga = run_ga
  )

  results <- list()
  errors <- list()
  runtime_records <- list()
  total_start <- Sys.time()

  for (method_index in seq_along(methods)) {
    method <- methods[[method_index]]
    params <- method_params[[method]] %||% list()
    alias_names <- names(.method_aliases)[.method_aliases == method]
    for (alias in alias_names) {
      if (is.null(method_params[[method]]) && !is.null(method_params[[alias]])) {
        params <- method_params[[alias]]
        break
      }
    }
    if (is.null(params$seed)) {
      params$seed <- seed
    }

    call_args <- c(list(data = prepared), params)
    started_at <- Sys.time()
    if (isTRUE(progress)) {
      message(sprintf(
        "[IKUNML] (%d/%d) Starting %s at %s",
        method_index,
        length(methods),
        method,
        format(started_at, "%Y-%m-%d %H:%M:%S")
      ))
    }
    method_result <- tryCatch(
      do.call(runners[[method]], call_args),
      error = function(e) e
    )
    completed_at <- Sys.time()
    elapsed_seconds <- as.numeric(difftime(completed_at, started_at, units = "secs"))

    if (inherits(method_result, "error")) {
      errors[[method]] <- method_result$message
      runtime_records[[method]] <- data.frame(
        method = method,
        status = "failed",
        started_at = format(started_at, "%Y-%m-%d %H:%M:%S"),
        completed_at = format(completed_at, "%Y-%m-%d %H:%M:%S"),
        elapsed_seconds = elapsed_seconds,
        selected_features = NA_integer_,
        message = method_result$message,
        stringsAsFactors = FALSE
      )
      if (isTRUE(progress)) {
        message(sprintf("[IKUNML] (%d/%d) Failed %s after %.2f seconds", method_index, length(methods), method, elapsed_seconds))
      }
      if (!continue_on_error) {
        stop("Method '", method, "' failed: ", method_result$message, call. = FALSE)
      }
    } else {
      method_result$started_at <- started_at
      method_result$completed_at <- completed_at
      method_result$runtime_seconds <- elapsed_seconds
      results[[method]] <- method_result
      runtime_records[[method]] <- data.frame(
        method = method,
        status = "completed",
        started_at = format(started_at, "%Y-%m-%d %H:%M:%S"),
        completed_at = format(completed_at, "%Y-%m-%d %H:%M:%S"),
        elapsed_seconds = elapsed_seconds,
        selected_features = length(method_result$selected_features),
        message = "",
        stringsAsFactors = FALSE
      )
      if (isTRUE(progress)) {
        message(sprintf(
          "[IKUNML] (%d/%d) Finished %s in %.2f seconds; selected %d feature(s)",
          method_index,
          length(methods),
          method,
          elapsed_seconds,
          length(method_result$selected_features)
        ))
      }
    }
  }
  total_completed <- Sys.time()
  runtimes <- if (length(runtime_records) > 0L) {
    do.call(rbind, runtime_records)
  } else {
    data.frame(
      method = character(),
      status = character(),
      started_at = character(),
      completed_at = character(),
      elapsed_seconds = numeric(),
      selected_features = integer(),
      message = character(),
      stringsAsFactors = FALSE
    )
  }
  rownames(runtimes) <- NULL

  output <- structure(
    list(
      methods = methods,
      results = results,
      errors = errors,
      feature_map = prepared$feature_map,
      samples = prepared$samples,
      runtimes = runtimes,
      total_runtime_seconds = as.numeric(difftime(total_completed, total_start, units = "secs")),
      group_col = group_col,
      positive_class = positive_class,
      seed = seed,
      call = match.call()
    ),
    class = "ikunml_result"
  )

  if (!is.null(output_dir)) {
    write_ikun_results(
      output,
      output_dir = output_dir,
      write_plots = write_plots,
      save_models = save_models,
      plot_formats = plot_formats,
      tiff_res = tiff_res,
      folder_names = folder_names
    )
  }

  output
}

print.ikunml_result <- function(x, ...) {
  cat("IKUNML feature selection result\n")
  cat("Requested methods:", paste(x$methods, collapse = ", "), "\n")
  if (length(x$results) > 0L) {
    for (method in names(x$results)) {
      cat(" - ", method, ": ", length(x$results[[method]]$selected_features), " selected features\n", sep = "")
    }
  }
  if (length(x$errors) > 0L) {
    cat("Failed methods:", paste(names(x$errors), collapse = ", "), "\n")
  }
  if (!is.null(x$total_runtime_seconds)) {
    cat("Total runtime:", sprintf("%.2f seconds", x$total_runtime_seconds), "\n")
  }
  invisible(x)
}

summary.ikunml_result <- function(object, ...) {
  feature_hit_summary(object)
}

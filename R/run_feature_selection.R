run_feature_selection <- function(data,
                                  group_col = "group",
                                  feature_cols = NULL,
                                  methods = c("lasso", "boruta", "rf", "xgboost"),
                                  method_params = list(),
                                  positive_class = NULL,
                                  seed = 123,
                                  output_dir = NULL,
                                  write_plots = FALSE,
                                  save_models = FALSE,
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
    svm_rfe = run_svm_rfe,
    rf = run_rf,
    xgboost = run_xgboost,
    ga = run_ga
  )

  results <- list()
  errors <- list()

  for (method in methods) {
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
    method_result <- tryCatch(
      do.call(runners[[method]], call_args),
      error = function(e) e
    )

    if (inherits(method_result, "error")) {
      errors[[method]] <- method_result$message
      if (!continue_on_error) {
        stop("Method '", method, "' failed: ", method_result$message, call. = FALSE)
      }
    } else {
      results[[method]] <- method_result
    }
  }

  output <- structure(
    list(
      methods = methods,
      results = results,
      errors = errors,
      feature_map = prepared$feature_map,
      samples = prepared$samples,
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
      save_models = save_models
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
  invisible(x)
}

summary.ikunml_result <- function(object, ...) {
  feature_hit_summary(object)
}

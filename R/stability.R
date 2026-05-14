stability_selection <- function(data,
                                group_col = "group",
                                feature_cols = NULL,
                                methods = c("lasso", "rf"),
                                method_params = list(),
                                positive_class = NULL,
                                seed = 123,
                                n_iter = 50,
                                sample_fraction = 0.8,
                                min_frequency = 0.6,
                                output_dir = NULL,
                                parallel = FALSE,
                                cores = NULL,
                                progress = TRUE,
                                drop_na = TRUE,
                                continue_on_error = TRUE) {
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

  seeds <- seed + seq_len(n_iter)
  iter_runner <- function(iter_id) {
    iter_seed <- seeds[[iter_id]]
    idx <- .stratified_sample_indices(prepared$y, fraction = sample_fraction, seed = iter_seed)
    iter_data <- clean_data[idx, , drop = FALSE]
    tryCatch(
      run_feature_selection(
        data = iter_data,
        group_col = prepared$group_col,
        feature_cols = prepared$feature_cols,
        methods = methods,
        method_params = method_params,
        positive_class = positive_class,
        seed = iter_seed,
        output_dir = NULL,
        write_plots = FALSE,
        progress = FALSE,
        continue_on_error = continue_on_error,
        drop_na = drop_na
      ),
      error = function(e) e
    )
  }

  if (isTRUE(progress)) {
    message("[IKUNML] Stability selection: ", n_iter, " resampling run(s)")
  }
  started_at <- Sys.time()
  iter_results <- .parallel_lapply(seq_len(n_iter), iter_runner, parallel = parallel, cores = cores)
  completed_at <- Sys.time()

  errors <- lapply(seq_along(iter_results), function(i) {
    if (inherits(iter_results[[i]], "error")) {
      data.frame(iteration = i, error = iter_results[[i]]$message, stringsAsFactors = FALSE)
    } else {
      NULL
    }
  })
  errors <- errors[!vapply(errors, is.null, logical(1L))]
  error_table <- if (length(errors) > 0L) do.call(rbind, errors) else data.frame(iteration = integer(), error = character())

  completed <- iter_results[!vapply(iter_results, inherits, logical(1L), what = "error")]
  if (length(completed) == 0L) {
    stop("All stability selection iterations failed.", call. = FALSE)
  }

  rows <- list()
  for (method in methods) {
    selected_by_iter <- lapply(completed, function(res) {
      if (!method %in% names(res$results)) {
        return(character())
      }
      res$results[[method]]$selected_features
    })
    counts <- table(unlist(selected_by_iter, use.names = FALSE))
    method_summary <- if (length(counts) == 0L) {
      data.frame(
        method = character(),
        feature = character(),
        selected_n = integer(),
        total_n = integer(),
        selection_frequency = numeric(),
        stringsAsFactors = FALSE
      )
    } else {
      data.frame(
        method = method,
        feature = names(counts),
        selected_n = as.integer(counts),
        total_n = length(completed),
        selection_frequency = as.numeric(counts) / length(completed),
        stringsAsFactors = FALSE
      )
    }
    method_summary$stable <- method_summary$selection_frequency >= min_frequency
    rows[[method]] <- method_summary
  }
  summary <- if (length(rows) > 0L) do.call(rbind, rows) else data.frame()
  rownames(summary) <- NULL
  if (nrow(summary) > 0L) {
    summary <- summary[order(summary$method, -summary$selection_frequency, summary$feature), , drop = FALSE]
  }

  out <- structure(
    list(
      summary = summary,
      stable_features = split(summary$feature[summary$stable], summary$method[summary$stable]),
      methods = methods,
      iterations = length(completed),
      requested_iterations = n_iter,
      errors = error_table,
      started_at = started_at,
      completed_at = completed_at,
      runtime_seconds = as.numeric(difftime(completed_at, started_at, units = "secs")),
      params = list(
        sample_fraction = sample_fraction,
        min_frequency = min_frequency,
        seed = seed,
        parallel = parallel,
        cores = cores
      )
    ),
    class = "ikun_stability_result"
  )

  if (!is.null(output_dir)) {
    write_stability_results(out, output_dir = output_dir)
  }
  out
}

write_stability_results <- function(result, output_dir = "IKUNML_stability") {
  if (!inherits(result, "ikun_stability_result")) {
    stop("result must be produced by stability_selection().", call. = FALSE)
  }
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }
  utils::write.csv(result$summary, file.path(output_dir, "stability_summary.csv"), row.names = FALSE)
  if (nrow(result$errors) > 0L) {
    utils::write.csv(result$errors, file.path(output_dir, "stability_errors.csv"), row.names = FALSE)
  }
  for (method in names(result$stable_features)) {
    utils::write.table(
      result$stable_features[[method]],
      file.path(output_dir, paste0(method, "_stable_features.txt")),
      quote = FALSE,
      row.names = FALSE,
      col.names = FALSE
    )
  }
  saveRDS(result, file.path(output_dir, "stability_result.rds"))
  invisible(output_dir)
}

print.ikun_stability_result <- function(x, ...) {
  cat("IKUNML stability selection result\n")
  cat("Completed iterations:", x$iterations, "/", x$requested_iterations, "\n")
  cat("Runtime:", sprintf("%.2f seconds", x$runtime_seconds), "\n")
  if (nrow(x$summary) > 0L) {
    stable_counts <- stats::aggregate(stable ~ method, x$summary, sum)
    for (i in seq_len(nrow(stable_counts))) {
      cat(" - ", stable_counts$method[[i]], ": ", stable_counts$stable[[i]], " stable feature(s)\n", sep = "")
    }
  }
  invisible(x)
}

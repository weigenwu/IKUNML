run_svm_rfe <- function(data,
                        group_col = "group",
                        feature_cols = NULL,
                        positive_class = NULL,
                        seed = 123,
                        k = 10,
                        halve_above = 50,
                        rank_cost = 10,
                        rank_scale = TRUE,
                        cachesize = 500,
                        nfolds = 5,
                        max_features = 200,
                        tolerance = 0,
                        prefer = c("largest", "smallest"),
                        tune = TRUE,
                        tune_ranges = list(gamma = 2^(-12:0), cost = 2^(-6:6)),
                        tune_sampling = "cross",
                        performance_kernel = "radial",
                        performance_scale = TRUE,
                        performance_params = list(),
                        performance_cost = 10,
                        performance_gamma = NULL,
                        verbose = FALSE,
                        drop_na = TRUE,
                        ...) {
  extra_args <- list(...)
  if (!is.null(extra_args[["halve.above"]])) {
    halve_above <- extra_args[["halve.above"]]
    extra_args[["halve.above"]] <- NULL
  }
  if (!is.null(extra_args$cost)) {
    rank_cost <- extra_args$cost
    performance_cost <- extra_args$cost
    extra_args$cost <- NULL
  }
  if (!is.null(extra_args$scale)) {
    rank_scale <- extra_args$scale
    performance_scale <- extra_args$scale
    extra_args$scale <- NULL
  }

  do.call(
    run_msvm_rfe,
    c(
      list(
        data = data,
        group_col = group_col,
        feature_cols = feature_cols,
        positive_class = positive_class,
        seed = seed,
        k = k,
        halve_above = halve_above,
        rank_cost = rank_cost,
        rank_scale = rank_scale,
        cachesize = cachesize,
        nfolds = nfolds,
        max_features = max_features,
        tolerance = tolerance,
        prefer = prefer,
        tune = tune,
        tune_ranges = tune_ranges,
        tune_sampling = tune_sampling,
        performance_kernel = performance_kernel,
        performance_scale = performance_scale,
        performance_params = performance_params,
        performance_cost = performance_cost,
        performance_gamma = performance_gamma,
        verbose = verbose,
        drop_na = drop_na,
        method_name = "svm_rfe"
      ),
      extra_args
    )
  )
}

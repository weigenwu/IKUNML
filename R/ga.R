run_ga <- function(data,
                   group_col = "group",
                   feature_cols = NULL,
                   positive_class = NULL,
                   seed = 123,
                   iters = 30,
                   popSize = 20,
                   method = "cv",
                   nfolds = 5,
                   ntree = 100,
                   parallel = FALSE,
                   cores = NULL,
                   drop_na = TRUE,
                   ...) {
  .require_pkg("caret")
  .require_pkg("randomForest")
  prepared <- .ensure_ikun_data(data, group_col, feature_cols, positive_class, drop_na)

  if (parallel) {
    .require_pkg("doParallel")
    cores <- cores %||% max(1L, parallel::detectCores() - 2L)
    cl <- parallel::makeCluster(cores)
    doParallel::registerDoParallel(cl)
    on.exit({
      parallel::stopCluster(cl)
      if (requireNamespace("foreach", quietly = TRUE)) {
        foreach::registerDoSEQ()
      }
    }, add = TRUE)
  }

  ga_ctrl <- caret::gafsControl(
    functions = caret::rfGA,
    method = method,
    number = nfolds,
    allowParallel = parallel,
    genParallel = parallel
  )

  .set_seed(seed)
  ga_model <- caret::gafs(
    x = prepared$x,
    y = prepared$y,
    iters = iters,
    popSize = popSize,
    gafsControl = ga_ctrl,
    ntree = ntree,
    ...
  )

  selected <- ga_model$optVariables
  .method_result(
    method = "ga",
    selected_internal = selected,
    prepared = prepared,
    model = ga_model,
    optimal_iteration = ga_model$optIter,
    params = list(
      iters = iters,
      popSize = popSize,
      method = method,
      nfolds = nfolds,
      ntree = ntree,
      parallel = parallel,
      cores = cores,
      seed = seed
    )
  )
}

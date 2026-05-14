test_that("small Boruta method runs", {
  skip_if_not_installed("Boruta")
  dat <- read.csv(system.file("extdata", "example_data.csv", package = "IKUNML"), row.names = 1, check.names = FALSE)

  res <- run_boruta(
    dat,
    group_col = "group",
    ntree = 20,
    maxRuns = 20,
    pValue = 0.2,
    mcAdj = FALSE,
    tentative_rough_fix = FALSE
  )

  expect_s3_class(res, "ikun_method_result")
  expect_equal(res$method, "boruta")
  expect_true(is.data.frame(res$stats))
})

test_that("small XGBoost method runs", {
  skip_if_not_installed("xgboost")
  dat <- read.csv(system.file("extdata", "example_data.csv", package = "IKUNML"), row.names = 1, check.names = FALSE)

  res <- run_xgboost(
    dat,
    group_col = "group",
    params = list(max_depth = 2, eta = 0.4, nthread = 1),
    nrounds = 5,
    cv_nrounds = 3,
    max_features = 3,
    nfolds = 2,
    record_eval = FALSE,
    verbose = 0
  )

  expect_s3_class(res, "ikun_method_result")
  expect_equal(res$method, "xgboost")
  expect_true(nrow(res$cv_metrics) >= 1)
  expect_true(nrow(res$cv_metrics) <= 3)
})

test_that("small GA method runs", {
  skip_if_not_installed("caret")
  skip_if_not_installed("randomForest")
  dat <- read.csv(system.file("extdata", "example_data.csv", package = "IKUNML"), row.names = 1, check.names = FALSE)

  res <- run_ga(
    dat,
    group_col = "group",
    iters = 2,
    popSize = 4,
    method = "cv",
    nfolds = 2,
    ntree = 20,
    parallel = FALSE
  )

  expect_s3_class(res, "ikun_method_result")
  expect_equal(res$method, "ga")
  expect_true(is.character(res$selected_features))
})

test_that("reproducibility helper writes session files", {
  out_dir <- file.path(tempdir(), paste0("ikunml_repro_", as.integer(stats::runif(1, 1, 1e7))))

  info <- export_reproducibility_info(
    output_dir = out_dir,
    include_installed_packages = FALSE
  )

  expect_true(file.exists(info$session_info))
  expect_true(file.exists(info$system_info))
  expect_null(info$installed_packages)
})

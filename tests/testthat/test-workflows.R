test_that("example data is shipped and readable", {
  path <- system.file("extdata", "example_data.csv", package = "IKUNML")
  expect_true(file.exists(path))
  dat <- read.csv(path, row.names = 1, check.names = FALSE)
  expect_true("group" %in% names(dat))
  expect_true(all(c("Normal", "Tumor") %in% dat$group))
})

test_that("startup message can be disabled", {
  old <- getOption("IKUNML.startup")
  on.exit(options(IKUNML.startup = old), add = TRUE)
  options(IKUNML.startup = FALSE)
  msg <- capture.output(IKUNML:::.onAttach("", ""), type = "message")
  expect_equal(msg, character())
})

test_that("small LASSO workflow runs and writes report", {
  skip_if_not_installed("glmnet")
  dat <- read.csv(system.file("extdata", "example_data.csv", package = "IKUNML"), row.names = 1, check.names = FALSE)
  out_dir <- file.path(tempdir(), paste0("ikunml_lasso_", as.integer(stats::runif(1, 1, 1e7))))
  res <- run_feature_selection(
    dat,
    group_col = "group",
    methods = "lasso",
    output_dir = out_dir,
    write_plots = FALSE,
    write_report = TRUE,
    progress = FALSE,
    method_params = list(lasso = list(nfolds = 5, nlambda = 20))
  )
  expect_s3_class(res, "ikunml_result")
  expect_true(file.exists(file.path(out_dir, "lasso", "lasso_selected_features.csv")))
  expect_true(file.exists(file.path(out_dir, "IKUNML_report.html")))
})

test_that("small RF and SVM methods run", {
  skip_if_not_installed("randomForest")
  skip_if_not_installed("e1071")
  dat <- read.csv(system.file("extdata", "example_data.csv", package = "IKUNML"), row.names = 1, check.names = FALSE)
  rf_res <- run_rf(
    dat,
    group_col = "group",
    ntree = 30,
    cv_ntree = 20,
    nfolds = 2,
    max_features = 3
  )
  svm_res <- run_SVM(
    dat,
    group_col = "group",
    k = 2,
    nfolds = 2,
    max_features = 3,
    tune = FALSE,
    performance_kernel = "linear"
  )
  expect_s3_class(rf_res, "ikun_method_result")
  expect_s3_class(svm_res, "ikun_method_result")
  expect_equal(svm_res$method, "SVM")
})

test_that("validation and HTML report helpers run on explicit features", {
  dat <- read.csv(system.file("extdata", "example_data.csv", package = "IKUNML"), row.names = 1, check.names = FALSE)
  out_dir <- file.path(tempdir(), paste0("ikunml_validation_", as.integer(stats::runif(1, 1, 1e7))))
  val <- validate_selected_features(
    dat,
    features = c("tsRNA-1", "tsRNA.2"),
    group_col = "group",
    positive_class = "Tumor",
    model = "glm",
    train_fraction = 0.7,
    output_dir = out_dir,
    plot_formats = "pdf"
  )
  expect_s3_class(val, "ikun_validation_result")
  expect_true(file.exists(file.path(out_dir, "validation_metrics.csv")))
  expect_true(is.finite(val$metrics$auc[[1]]))
})

test_that("prepare_ikun_data preserves original feature names", {
  dat <- data.frame(
    group = c("Normal", "Tumor", "Normal", "Tumor"),
    check.names = FALSE
  )
  dat[["tRF-1"]] <- c(1, 2, 1.5, 2.2)
  dat[["tRF.2"]] <- c(3, 4, 3.5, 4.1)

  prepared <- prepare_ikun_data(dat, group_col = "group")

  expect_s3_class(prepared, "ikun_data")
  expect_equal(prepared$feature_map$feature, c("tRF-1", "tRF.2"))
  expect_equal(ncol(prepared$x), 2)
  expect_true(all(vapply(prepared$x, is.numeric, logical(1))))
})

test_that("feature hit summary counts selected features", {
  fake_method <- function(method, features) {
    structure(
      list(method = method, selected_features = features),
      class = c("ikun_method_result", paste0("ikun_", method, "_result"))
    )
  }

  res <- structure(
    list(
      methods = c("lasso", "rf"),
      results = list(
        lasso = fake_method("lasso", c("a", "b")),
        rf = fake_method("rf", c("b", "c"))
      ),
      errors = list()
    ),
    class = "ikunml_result"
  )

  summary <- feature_hit_summary(res)
  expect_equal(summary$Hit_Count[summary$feature == "b"], 2)
  expect_equal(feature_intersection(res), "b")
})

test_that("method aliases include elastic net and GA", {
  expect_true("elastic_net" %in% available_methods())
  expect_true("SVM" %in% available_methods())
  expect_false("svm_rfe" %in% available_methods())
  expect_false("msvm_rfe" %in% available_methods())
  expect_true("caret_rfe" %in% available_methods())
  expect_true("gbm" %in% available_methods())
  expect_true("rpart" %in% available_methods())
  expect_true("ga" %in% available_methods())
  expect_equal(
    IKUNML:::.normalize_methods(c("enet", "msvmrfe", "rfe", "boosting", "decision_tree", "genetic_algorithm")),
    c("elastic_net", "SVM", "caret_rfe", "gbm", "rpart", "ga")
  )
})

test_that("method folder names use publication-style defaults and overrides", {
  expect_equal(IKUNML:::.method_folder_name("SVM"), "SVM")
  expect_equal(IKUNML:::.method_folder_name("rf"), "RF")
  expect_equal(IKUNML:::.method_folder_name("xgboost"), "XGBoost")
  expect_equal(IKUNML:::.method_folder_name("ga"), "GA")
  expect_equal(
    IKUNML:::.method_folder_name("SVM", c(svm_rfe = "SVM_custom")),
    "SVM_custom"
  )
})

test_that("config method blocks are mapped into method_params", {
  cfg <- list(
    lasso = list(alpha = 0.5),
    SVM = list(tolerance = 0.02),
    rf = list(ntree = 100)
  )
  params <- IKUNML:::.config_method_params(cfg, c("lasso", "SVM", "rf"))
  expect_equal(params$lasso$alpha, 0.5)
  expect_equal(params$SVM$tolerance, 0.02)
  expect_equal(params$rf$ntree, 100)

  alias_params <- IKUNML:::.config_method_params(
    list(method_params = list(svm_rfe = list(k = 10))),
    "SVM"
  )
  expect_equal(alias_params$SVM$k, 10)
})

test_that("binary AUC helper returns expected rank-based value", {
  labels <- c(0, 0, 1, 1)
  scores <- c(0.1, 0.4, 0.35, 0.8)
  expect_equal(IKUNML:::.binary_auc(labels, scores), 0.75)
})

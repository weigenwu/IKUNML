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
  expect_true("ga" %in% available_methods())
  expect_equal(IKUNML:::.normalize_methods(c("enet", "genetic_algorithm")), c("elastic_net", "ga"))
})

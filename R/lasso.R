run_lasso <- function(data,
                      group_col = "group",
                      feature_cols = NULL,
                      positive_class = NULL,
                      seed = 123,
                      family = "binomial",
                      alpha = 1,
                      nlambda = 100,
                      nfolds = 10,
                      lambda_choice = c("lambda.min", "lambda.1se"),
                      standardize = TRUE,
                      type.measure = NULL,
                      drop_na = TRUE,
                      ...) {
  .require_pkg("glmnet")
  penalty <- .penalty_name(alpha)
  lambda_choice <- match.arg(lambda_choice)
  prepared <- .ensure_ikun_data(data, group_col, feature_cols, positive_class, drop_na)

  x <- as.matrix(prepared$x)
  y <- if (identical(family, "binomial")) {
    .binary_label(prepared$y, positive_class %||% prepared$positive_class)
  } else {
    prepared$y
  }

  .set_seed(seed)
  cv_args <- list(
    x = x,
    y = y,
    family = family,
    alpha = alpha,
    nlambda = nlambda,
    nfolds = nfolds,
    standardize = standardize
  )
  if (!is.null(type.measure)) {
    cv_args$type.measure <- type.measure
  }
  cv_args <- c(cv_args, list(...))
  cvfit <- do.call(glmnet::cv.glmnet, cv_args)

  coefs <- as.matrix(stats::coef(cvfit, s = lambda_choice))
  coefficient_table <- data.frame(
    feature_internal = rownames(coefs),
    feature = rownames(coefs),
    coefficient = as.numeric(coefs[, 1L]),
    stringsAsFactors = FALSE
  )
  non_intercept <- coefficient_table$feature_internal != "(Intercept)"
  coefficient_table$feature[non_intercept] <- .restore_feature_names(
    coefficient_table$feature_internal[non_intercept],
    prepared
  )

  selected <- coefficient_table$feature_internal[
    coefficient_table$coefficient != 0 & coefficient_table$feature_internal != "(Intercept)"
  ]

  .method_result(
    method = "lasso",
    selected_internal = selected,
    prepared = prepared,
    coefficients = coefficient_table,
    lambda = cvfit[[lambda_choice]],
    lambda_choice = lambda_choice,
    penalty = penalty,
    cvfit = cvfit,
    model = cvfit$glmnet.fit,
    params = list(
      family = family,
      alpha = alpha,
      penalty = penalty,
      nlambda = nlambda,
      nfolds = nfolds,
      lambda_choice = lambda_choice,
      standardize = standardize,
      type.measure = type.measure,
      seed = seed
    )
  )
}

run_elastic_net <- function(data,
                            group_col = "group",
                            feature_cols = NULL,
                            positive_class = NULL,
                            seed = 123,
                            family = "binomial",
                            alpha = 0.5,
                            nlambda = 100,
                            nfolds = 10,
                            lambda_choice = c("lambda.min", "lambda.1se"),
                            standardize = TRUE,
                            type.measure = NULL,
                            drop_na = TRUE,
                            ...) {
  result <- run_lasso(
    data = data,
    group_col = group_col,
    feature_cols = feature_cols,
    positive_class = positive_class,
    seed = seed,
    family = family,
    alpha = alpha,
    nlambda = nlambda,
    nfolds = nfolds,
    lambda_choice = lambda_choice,
    standardize = standardize,
    type.measure = type.measure,
    drop_na = drop_na,
    ...
  )
  result$method <- "elastic_net"
  class(result) <- c("ikun_method_result", "ikun_elastic_net_result")
  result
}

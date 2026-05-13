.ikunml_methods <- c("lasso", "elastic_net", "boruta", "svm_rfe", "msvm_rfe", "rf", "xgboost", "ga")

.method_aliases <- c(
  lasso = "lasso",
  glmnet = "lasso",
  elastic_net = "elastic_net",
  elasticnet = "elastic_net",
  enet = "elastic_net",
  boruta = "boruta",
  svm = "svm_rfe",
  svm_rfe = "svm_rfe",
  svmrfe = "svm_rfe",
  msvm = "msvm_rfe",
  msvm_rfe = "msvm_rfe",
  msvmrfe = "msvm_rfe",
  rf = "rf",
  random_forest = "rf",
  randomforest = "rf",
  xgb = "xgboost",
  xgboost = "xgboost",
  ga = "ga",
  genetic_algorithm = "ga"
)

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

available_methods <- function() {
  .ikunml_methods
}

.require_pkg <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop(
      "Package '", pkg, "' is required for this function. Install it with install.packages('",
      pkg, "').",
      call. = FALSE
    )
  }
  invisible(TRUE)
}

.normalize_methods <- function(methods) {
  if (length(methods) == 1L && identical(tolower(methods), "all")) {
    return(.ikunml_methods)
  }

  methods <- tolower(gsub("-", "_", methods))
  mapped <- unname(.method_aliases[methods])
  missing <- methods[is.na(mapped)]
  if (length(missing) > 0L) {
    stop(
      "Unknown method(s): ", paste(missing, collapse = ", "),
      ". Available methods are: ", paste(.ikunml_methods, collapse = ", "),
      call. = FALSE
    )
  }
  unique(mapped)
}

.set_seed <- function(seed) {
  if (!is.null(seed)) {
    set.seed(seed)
  }
  invisible(seed)
}

.penalty_name <- function(alpha) {
  if (!is.numeric(alpha) || length(alpha) != 1L || is.na(alpha) || alpha < 0 || alpha > 1) {
    stop("alpha must be one numeric value between 0 and 1.", call. = FALSE)
  }
  if (identical(alpha, 1) || isTRUE(all.equal(alpha, 1))) {
    "lasso"
  } else if (identical(alpha, 0) || isTRUE(all.equal(alpha, 0))) {
    "ridge"
  } else {
    "elastic_net"
  }
}

.make_internal_names <- function(x) {
  make.unique(make.names(as.character(x)))
}

.create_folds <- function(y, k = 5L, seed = NULL) {
  y <- factor(y)
  n <- length(y)
  if (n < 2L) {
    stop("At least two samples are required for cross-validation.", call. = FALSE)
  }
  k <- min(as.integer(k), n)
  if (k < 2L) {
    stop("Cross-validation requires k >= 2.", call. = FALSE)
  }

  .set_seed(seed)
  folds <- vector("list", k)
  for (level in levels(y)) {
    idx <- sample(which(y == level))
    split_id <- rep(seq_len(k), length.out = length(idx))
    for (i in seq_len(k)) {
      folds[[i]] <- c(folds[[i]], idx[split_id == i])
    }
  }
  lapply(folds, sort)
}

.binary_label <- function(y, positive_class = NULL) {
  y <- factor(y)
  if (nlevels(y) != 2L) {
    stop("This method requires exactly two classes.", call. = FALSE)
  }

  levels_y <- levels(y)
  if (is.null(positive_class)) {
    positive_class <- if ("1" %in% levels_y) "1" else levels_y[2L]
  }
  if (!positive_class %in% levels_y) {
    stop("positive_class must be one of: ", paste(levels_y, collapse = ", "), call. = FALSE)
  }
  as.integer(as.character(y) == positive_class)
}

.select_count <- function(values, maximize = TRUE, tolerance = 0, prefer = c("largest", "smallest")) {
  prefer <- match.arg(prefer)
  if (!is.numeric(values) || length(values) == 0L || all(is.na(values))) {
    stop("Cannot choose an optimal feature count because all metric values are missing.", call. = FALSE)
  }

  if (maximize) {
    best_value <- max(values, na.rm = TRUE)
    strict_best_count <- which.max(values)
    acceptable <- which(values >= best_value - tolerance)
    threshold <- best_value - tolerance
  } else {
    best_value <- min(values, na.rm = TRUE)
    strict_best_count <- which.min(values)
    acceptable <- which(values <= best_value + tolerance)
    threshold <- best_value + tolerance
  }

  optimal_count <- if (identical(prefer, "largest")) max(acceptable) else min(acceptable)
  list(
    optimal_count = optimal_count,
    strict_best_count = strict_best_count,
    best_value = best_value,
    threshold = threshold
  )
}

.restore_feature_names <- function(features, prepared) {
  idx <- match(features, prepared$feature_map$internal)
  restored <- prepared$feature_map$feature[idx]
  restored[is.na(restored)] <- features[is.na(restored)]
  unname(restored)
}

.method_result <- function(method, selected_internal, prepared, ...) {
  selected_features <- .restore_feature_names(selected_internal, prepared)
  structure(
    list(
      method = method,
      selected_features = selected_features,
      selected_internal = selected_internal,
      feature_map = prepared$feature_map,
      ...
    ),
    class = c("ikun_method_result", paste0("ikun_", method, "_result"))
  )
}

print.ikun_method_result <- function(x, ...) {
  cat("IKUNML method result\n")
  cat("Method:", x$method, "\n")
  cat("Selected features:", length(x$selected_features), "\n")
  if (length(x$selected_features) > 0L) {
    cat(paste(utils::head(x$selected_features, 10L), collapse = ", "))
    if (length(x$selected_features) > 10L) {
      cat(", ...")
    }
    cat("\n")
  }
  invisible(x)
}

feature_sets <- function(result, methods = NULL) {
  if (inherits(result, "ikun_method_result")) {
    out <- list(result$selected_features)
    names(out) <- result$method
    return(out)
  }
  if (!inherits(result, "ikunml_result")) {
    stop("result must be an IKUNML result object.", call. = FALSE)
  }

  available <- names(result$results)
  methods <- methods %||% available
  methods <- .normalize_methods(methods)
  methods <- intersect(methods, available)
  if (length(methods) == 0L) {
    stop("No completed methods were selected.", call. = FALSE)
  }

  sets <- lapply(result$results[methods], function(x) unique(x$selected_features))
  sets
}

feature_intersection <- function(result, methods = NULL, min_hits = NULL) {
  sets <- feature_sets(result, methods)
  if (is.null(min_hits)) {
    return(Reduce(intersect, sets))
  }

  summary <- feature_hit_summary(result, methods)
  summary$feature[summary$Hit_Count >= min_hits]
}

feature_hit_summary <- function(result, methods = NULL) {
  sets <- feature_sets(result, methods)
  all_features <- unique(unlist(sets, use.names = FALSE))
  out <- data.frame(feature = all_features, stringsAsFactors = FALSE)

  for (method in names(sets)) {
    out[[method]] <- ifelse(out$feature %in% sets[[method]], "Yes", "")
  }
  out$Hit_Count <- rowSums(out[, names(sets), drop = FALSE] == "Yes")
  out <- out[order(-out$Hit_Count, out$feature), , drop = FALSE]
  rownames(out) <- NULL
  out
}

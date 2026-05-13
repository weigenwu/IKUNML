prepare_ikun_data <- function(data,
                              group_col = "group",
                              feature_cols = NULL,
                              positive_class = NULL,
                              drop_na = TRUE) {
  if (!is.data.frame(data)) {
    data <- as.data.frame(data, check.names = FALSE)
  }

  if (is.numeric(group_col)) {
    group_col <- names(data)[group_col]
  }
  if (length(group_col) != 1L || !group_col %in% names(data)) {
    stop("group_col must identify one existing column in data.", call. = FALSE)
  }

  if (is.null(feature_cols)) {
    feature_cols <- setdiff(names(data), group_col)
  } else if (is.numeric(feature_cols)) {
    feature_cols <- names(data)[feature_cols]
  }

  missing_features <- setdiff(feature_cols, names(data))
  if (length(missing_features) > 0L) {
    stop("These feature columns are missing from data: ", paste(missing_features, collapse = ", "), call. = FALSE)
  }
  if (length(feature_cols) == 0L) {
    stop("No feature columns were supplied.", call. = FALSE)
  }

  y_raw <- data[[group_col]]
  y <- factor(y_raw)
  if (!is.null(positive_class) && !positive_class %in% levels(y)) {
    stop("positive_class must be one of: ", paste(levels(y), collapse = ", "), call. = FALSE)
  }

  x <- data[, feature_cols, drop = FALSE]
  x_num <- lapply(x, function(col) {
    if (is.numeric(col)) {
      return(col)
    }
    suppressWarnings(as.numeric(as.character(col)))
  })
  x_num <- as.data.frame(x_num, check.names = FALSE, stringsAsFactors = FALSE)

  failed_numeric <- names(x_num)[vapply(x_num, function(col) all(is.na(col)), logical(1L))]
  if (length(failed_numeric) > 0L) {
    stop(
      "These feature columns could not be converted to numeric values: ",
      paste(failed_numeric, collapse = ", "),
      call. = FALSE
    )
  }

  complete <- stats::complete.cases(y, x_num)
  if (!all(complete)) {
    if (!drop_na) {
      stop("Missing values detected. Set drop_na = TRUE to remove incomplete samples.", call. = FALSE)
    }
    y <- y[complete]
    x_num <- x_num[complete, , drop = FALSE]
  }

  internal_names <- .make_internal_names(feature_cols)
  names(x_num) <- internal_names

  feature_map <- data.frame(
    feature = feature_cols,
    internal = internal_names,
    stringsAsFactors = FALSE
  )

  structure(
    list(
      x = x_num,
      y = y,
      group = y,
      group_col = group_col,
      feature_cols = feature_cols,
      feature_map = feature_map,
      positive_class = positive_class,
      samples = rownames(data)[complete]
    ),
    class = "ikun_data"
  )
}

.ensure_ikun_data <- function(data,
                              group_col = "group",
                              feature_cols = NULL,
                              positive_class = NULL,
                              drop_na = TRUE) {
  if (inherits(data, "ikun_data")) {
    return(data)
  }
  prepare_ikun_data(
    data = data,
    group_col = group_col,
    feature_cols = feature_cols,
    positive_class = positive_class,
    drop_na = drop_na
  )
}

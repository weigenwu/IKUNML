.read_ikun_table <- function(path, row_names = NULL, check_names = FALSE, ...) {
  ext <- tolower(tools::file_ext(path))
  if (ext %in% c("tsv", "txt")) {
    utils::read.delim(path, row.names = row_names, check.names = check_names, ...)
  } else {
    utils::read.csv(path, row.names = row_names, check.names = check_names, ...)
  }
}

.as_config_list <- function(config) {
  if (is.character(config) && length(config) == 1L) {
    .require_pkg("yaml")
    return(yaml::read_yaml(config))
  }
  if (is.list(config)) {
    return(config)
  }
  stop("config must be a YAML file path or a list.", call. = FALSE)
}

.config_method_params <- function(config, methods) {
  method_params <- config$method_params %||% list()
  for (method in methods) {
    aliases <- names(.method_aliases)[.method_aliases == method]
    config_names <- c(method, aliases)
    if (is.null(method_params[[method]])) {
      for (name in aliases) {
        if (!is.null(method_params[[name]])) {
          method_params[[method]] <- method_params[[name]]
          break
        }
      }
    }
    for (name in config_names) {
      if (!is.null(config[[name]]) && is.null(method_params[[method]])) {
        method_params[[method]] <- config[[name]]
      }
    }
  }
  method_params
}

run_feature_selection_config <- function(config, data = NULL) {
  config <- .as_config_list(config)

  if (is.null(data)) {
    if (!is.null(config$data)) {
      data <- config$data
    } else if (!is.null(config$data_path)) {
      data <- .read_ikun_table(
        config$data_path,
        row_names = config$row_names %||% NULL,
        check_names = config$check_names %||% FALSE
      )
    } else {
      stop("Provide data directly or set data/data_path in config.", call. = FALSE)
    }
  }

  methods <- config$methods %||% c("lasso", "boruta", "rf", "xgboost")
  methods <- .normalize_methods(methods)
  method_params <- .config_method_params(config, methods)

  args <- list(
    data = data,
    group_col = config$group_col %||% "group",
    feature_cols = config$feature_cols %||% NULL,
    methods = methods,
    method_params = method_params,
    positive_class = config$positive_class %||% NULL,
    seed = config$seed %||% 123,
    output_dir = config$output_dir %||% "IKUNML_results",
    write_plots = config$write_plots %||% TRUE,
    save_models = config$save_models %||% FALSE,
    plot_formats = config$plot_formats %||% c("pdf", "tiff"),
    tiff_res = config$tiff_res %||% 300,
    folder_names = config$folder_names %||% NULL,
    progress = config$progress %||% TRUE,
    continue_on_error = config$continue_on_error %||% FALSE,
    drop_na = config$drop_na %||% TRUE,
    write_report = config$write_report %||% TRUE,
    report_file = config$report_file %||% "IKUNML_report.html",
    write_excel_report = config$write_excel_report %||% FALSE
  )
  do.call(run_feature_selection, args)
}

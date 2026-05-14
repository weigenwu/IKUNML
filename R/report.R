.html_escape <- function(x) {
  x <- as.character(x)
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  x <- gsub('"', "&quot;", x, fixed = TRUE)
  x
}

.param_to_string <- function(x) {
  if (is.null(x)) {
    return("")
  }
  if (length(x) == 0L) {
    return("")
  }
  paste(utils::capture.output(utils::str(x, give.attr = FALSE)), collapse = " ")
}

.html_path <- function(x) {
  gsub("\\\\", "/", x)
}

.method_parameters_table <- function(result) {
  rows <- lapply(names(result$results), function(method) {
    params <- result$results[[method]]$params
    if (is.null(params) || length(params) == 0L) {
      return(NULL)
    }
    data.frame(
      method = method,
      parameter = names(params),
      value = vapply(params, .param_to_string, character(1L)),
      stringsAsFactors = FALSE
    )
  })
  rows <- rows[!vapply(rows, is.null, logical(1L))]
  if (length(rows) == 0L) {
    return(data.frame(method = character(), parameter = character(), value = character()))
  }
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}

.run_metadata_table <- function(result) {
  data.frame(
    item = c(
      "package",
      "package_version",
      "R_version",
      "platform",
      "seed",
      "positive_class",
      "total_runtime_seconds",
      "created_at"
    ),
    value = c(
      "IKUNML",
      tryCatch(as.character(utils::packageVersion("IKUNML")), error = function(e) ""),
      paste(R.version$major, R.version$minor, sep = "."),
      R.version$platform,
      as.character(result$seed %||% ""),
      as.character(result$positive_class %||% ""),
      sprintf("%.3f", result$total_runtime_seconds %||% NA_real_),
      format(Sys.time(), "%Y-%m-%d %H:%M:%S")
    ),
    stringsAsFactors = FALSE
  )
}

.write_run_metadata <- function(result, output_dir) {
  metadata <- .run_metadata_table(result)
  utils::write.csv(metadata, file.path(output_dir, "run_metadata.csv"), row.names = FALSE)
  invisible(metadata)
}

.write_method_parameters <- function(result, output_dir) {
  params <- .method_parameters_table(result)
  utils::write.csv(params, file.path(output_dir, "method_parameters.csv"), row.names = FALSE)
  invisible(params)
}

.html_table <- function(x, max_rows = 200L) {
  if (is.null(x) || nrow(x) == 0L) {
    return("<p>No rows.</p>")
  }
  x <- utils::head(as.data.frame(x, stringsAsFactors = FALSE), max_rows)
  header <- paste0("<th>", .html_escape(names(x)), "</th>", collapse = "")
  rows <- apply(x, 1L, function(row) {
    paste0("<tr>", paste0("<td>", .html_escape(row), "</td>", collapse = ""), "</tr>")
  })
  paste0("<table><thead><tr>", header, "</tr></thead><tbody>", paste(rows, collapse = "\n"), "</tbody></table>")
}

.method_plot_links <- function(method, output_dir, folder_names = NULL) {
  method_dir <- file.path(output_dir, .method_folder_name(method, folder_names))
  if (!dir.exists(method_dir)) {
    return("")
  }
  files <- list.files(method_dir, pattern = "[.](pdf|tif|tiff)$", ignore.case = TRUE)
  if (length(files) == 0L) {
    return("")
  }
  links <- paste0(
    "<li><a href=\"",
    .html_escape(.html_path(file.path(.method_folder_name(method, folder_names), files))),
    "\">",
    .html_escape(files),
    "</a></li>",
    collapse = "\n"
  )
  paste0("<ul>", links, "</ul>")
}

write_ikun_report <- function(result,
                              output_dir = "IKUNML_results",
                              file = "IKUNML_report.html",
                              top_n = 50,
                              include_plots = TRUE,
                              folder_names = NULL) {
  if (!inherits(result, "ikunml_result")) {
    stop("result must be produced by run_feature_selection().", call. = FALSE)
  }
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  report_path <- if (grepl("[/\\\\]", file)) file else file.path(output_dir, file)
  metadata <- .run_metadata_table(result)
  params <- .method_parameters_table(result)
  hit_summary <- feature_hit_summary(result)
  common <- feature_intersection(result)
  common_table <- data.frame(feature = common, stringsAsFactors = FALSE)

  method_cards <- lapply(names(result$results), function(method) {
    method_result <- result$results[[method]]
    selected <- data.frame(feature = utils::head(method_result$selected_features, top_n), stringsAsFactors = FALSE)
    runtime <- if (!is.null(result$runtimes) && method %in% result$runtimes$method) {
      result$runtimes[result$runtimes$method == method, , drop = FALSE]
    } else {
      NULL
    }
    plot_links <- if (include_plots) .method_plot_links(method, output_dir, folder_names) else ""
    paste0(
      "<section><h2>", .html_escape(method), "</h2>",
      "<p>Selected features: ", length(method_result$selected_features), "</p>",
      "<h3>Runtime</h3>", .html_table(runtime),
      "<h3>Top Selected Features</h3>", .html_table(selected, max_rows = top_n),
      if (nzchar(plot_links)) paste0("<h3>Diagnostic Plots</h3>", plot_links) else "",
      "</section>"
    )
  })

  html <- c(
    "<!doctype html>",
    "<html><head><meta charset=\"utf-8\">",
    "<title>IKUNML Report</title>",
    "<style>",
    "body{font-family:Arial,sans-serif;margin:32px;line-height:1.45;color:#1f2933}",
    "h1,h2{color:#102a43} section{margin:28px 0;padding-top:8px;border-top:1px solid #d9e2ec}",
    "table{border-collapse:collapse;width:100%;margin:10px 0 18px 0;font-size:13px}",
    "th,td{border:1px solid #d9e2ec;padding:6px 8px;text-align:left;vertical-align:top}",
    "th{background:#f0f4f8}",
    "</style></head><body>",
    "<h1>IKUNML Feature Selection Report</h1>",
    "<h2>Run Metadata</h2>",
    .html_table(metadata),
    "<h2>Method Runtime</h2>",
    .html_table(result$runtimes),
    "<h2>Method Parameters</h2>",
    .html_table(params, max_rows = 500L),
    "<h2>Common Features</h2>",
    .html_table(common_table, max_rows = top_n),
    "<h2>Feature Hit Summary</h2>",
    .html_table(hit_summary, max_rows = top_n),
    paste(method_cards, collapse = "\n"),
    "</body></html>"
  )
  writeLines(html, report_path, useBytes = TRUE)
  invisible(report_path)
}

.add_worksheet_table <- function(wb, sheet, data) {
  if (is.null(data) || ncol(as.data.frame(data)) == 0L) {
    data <- data.frame(message = "No rows", stringsAsFactors = FALSE)
  }
  openxlsx::addWorksheet(wb, sheet)
  openxlsx::writeDataTable(wb, sheet, data)
  invisible(wb)
}

write_ikun_excel_report <- function(result,
                                    output_dir = "IKUNML_results",
                                    file = "IKUNML_report.xlsx",
                                    folder_names = NULL) {
  .require_pkg("openxlsx")
  if (!inherits(result, "ikunml_result")) {
    stop("result must be produced by run_feature_selection().", call. = FALSE)
  }
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }
  report_path <- if (grepl("[/\\\\]", file)) file else file.path(output_dir, file)
  wb <- openxlsx::createWorkbook()

  .add_worksheet_table(wb, "metadata", .run_metadata_table(result))
  .add_worksheet_table(wb, "runtime", result$runtimes %||% data.frame())
  .add_worksheet_table(wb, "parameters", .method_parameters_table(result))
  .add_worksheet_table(wb, "hit_summary", feature_hit_summary(result))
  .add_worksheet_table(wb, "common_features", data.frame(feature = feature_intersection(result)))

  for (method in names(result$results)) {
    method_result <- result$results[[method]]
    selected <- data.frame(feature = method_result$selected_features, stringsAsFactors = FALSE)
    sheet <- substr(gsub("[^A-Za-z0-9_]", "_", method), 1L, 31L)
    .add_worksheet_table(wb, sheet, selected)
  }

  openxlsx::saveWorkbook(wb, report_path, overwrite = TRUE)
  invisible(report_path)
}

\name{write_ikun_results}
\alias{write_ikun_results}
\title{Write IKUNML Result Tables}
\usage{
write_ikun_results(result, output_dir = "IKUNML_results", overwrite = TRUE,
  write_plots = TRUE, save_models = FALSE, plot_formats = c("pdf", "tiff"),
  tiff_res = 300, folder_names = NULL, write_report = TRUE,
  report_file = "IKUNML_report.html", write_excel_report = FALSE)
}
\arguments{
\item{result}{An \code{ikunml_result} object.}
\item{output_dir}{Directory where result files are written.}
\item{overwrite}{Reserved for future overwrite checks.}
\item{write_plots}{Whether to also write method diagnostic PDF and TIFF plots.}
\item{save_models}{Whether to save method result and model objects as RDS files.}
\item{plot_formats}{Plot formats to export. Supports \code{"pdf"} and \code{"tiff"}.}
\item{tiff_res}{TIFF resolution in dots per inch.}
\item{folder_names}{Optional named character vector overriding method folder names.}
\item{write_report}{Whether to write an HTML summary report.}
\item{report_file}{HTML report file name or path.}
\item{write_excel_report}{Whether to write an Excel workbook summary. Requires \pkg{openxlsx}.}
}
\value{
The output directory, invisibly.
}
\description{
Writes selected feature lists, rankings, importance tables, cross-validation
metrics, runtime summaries, run metadata, method parameters, common features,
hit summaries, and optional reports to disk.
When requested, it also saves diagnostic plots and RDS model objects. This is
especially useful for GA runs because those are expensive to repeat.
}

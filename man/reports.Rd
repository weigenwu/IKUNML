\name{reports}
\alias{write_ikun_report}
\alias{write_ikun_excel_report}
\title{Write IKUNML Summary Reports}
\usage{
write_ikun_report(result, output_dir = "IKUNML_results",
  file = "IKUNML_report.html", top_n = 50, include_plots = TRUE,
  folder_names = NULL)

write_ikun_excel_report(result, output_dir = "IKUNML_results",
  file = "IKUNML_report.xlsx", folder_names = NULL)
}
\arguments{
\item{result}{An \code{ikunml_result} object.}
\item{output_dir}{Directory containing IKUNML result files.}
\item{file}{Report file name or path.}
\item{top_n}{Number of top features shown in the HTML report sections.}
\item{include_plots}{Whether to link diagnostic PDF/TIFF files in the HTML report.}
\item{folder_names}{Optional named character vector overriding method folder names.}
}
\value{
The report path, invisibly.
}
\description{
Writes a compact HTML report, or an Excel workbook when \pkg{openxlsx} is
installed, summarizing runtime, parameters, selected features, intersections,
and method-specific outputs.
}

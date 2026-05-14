\name{run_feature_selection}
\alias{run_feature_selection}
\title{Run Multiple Feature Selection Methods}
\usage{
run_feature_selection(data, group_col = "group", feature_cols = NULL,
  methods = c("lasso", "boruta", "rf", "xgboost"),
  method_params = list(), positive_class = NULL, seed = 123,
  output_dir = "IKUNML_results", write_plots = TRUE, save_models = FALSE,
  plot_formats = c("pdf", "tiff"), tiff_res = 300, folder_names = NULL,
  progress = TRUE, continue_on_error = FALSE, drop_na = TRUE,
  write_report = TRUE, report_file = "IKUNML_report.html",
  write_excel_report = FALSE)
}
\arguments{
\item{data}{Input data frame.}
\item{group_col}{Name or index of the grouping column.}
\item{feature_cols}{Optional feature column names or indices.}
\item{methods}{Methods to run. Use \code{"all"} to request every supported method.
Use \code{"lasso"} for the default \code{alpha = 1} \pkg{glmnet} model,
\code{"elastic_net"} for the same backend with default \code{alpha = 0.5}, and
\code{"ga"} for genetic algorithm feature selection. \code{"SVM"} uses
the older multiple SVM-RFE style workflow. Additional methods include
\code{"caret_rfe"}, \code{"gbm"}, and \code{"rpart"}.}
\item{method_params}{Named list of method-specific parameter lists.}
\item{positive_class}{Optional positive class label for binary methods.}
\item{seed}{Random seed passed to methods unless overridden in \code{method_params}.}
\item{output_dir}{Directory for exported result tables and plots. Set to \code{NULL} to disable file export.}
\item{write_plots}{Whether to export method diagnostic PDF and TIFF plots when \code{output_dir} is set.}
\item{save_models}{Whether to save method result and model objects as RDS files when \code{output_dir} is set.}
\item{plot_formats}{Plot formats to export. Supports \code{"pdf"} and \code{"tiff"}.}
\item{tiff_res}{TIFF resolution in dots per inch.}
\item{folder_names}{Optional named character vector overriding method folder names.}
\item{progress}{Whether to print method start, finish, and elapsed-time messages.}
\item{continue_on_error}{If \code{TRUE}, failed methods are recorded and later methods continue.}
\item{drop_na}{Whether to remove incomplete samples.}
\item{write_report}{Whether to write an HTML summary report when \code{output_dir} is set.}
\item{report_file}{HTML report file name or path.}
\item{write_excel_report}{Whether to write an Excel workbook summary. Requires \pkg{openxlsx}.}
}
\value{
An \code{ikunml_result} object.
}
\description{
Runs selected feature-selection methods with a shared data preparation step and
returns method results plus overlap helpers.
}
\examples{
\dontrun{
data <- read.csv("data.csv", row.names = 1, check.names = FALSE)
res <- run_feature_selection(
  data,
  group_col = "group",
  methods = c("lasso", "rf"),
  method_params = list(
    lasso = list(lambda_choice = "lambda.min"),
    rf = list(ntree = 1000, max_features = 100)
  )
)
feature_intersection(res)

enet_ga <- run_feature_selection(
  data,
  group_col = "group",
  methods = c("elastic_net", "ga"),
  method_params = list(
    elastic_net = list(alpha = 0.5),
    ga = list(iters = 50, popSize = 30)
  ),
  output_dir = "IKUNML_results",
  write_plots = TRUE,
  save_models = TRUE
)

svm <- run_feature_selection(
  data,
  group_col = "group",
  methods = "SVM",
  method_params = list(
    SVM = list(k = 10, halve_above = 50, max_features = 200, tolerance = 0.02)
  )
)

more_ml <- run_feature_selection(
  data,
  group_col = "group",
  methods = c("caret_rfe", "gbm", "rpart"),
  method_params = list(
    caret_rfe = list(sizes = c(5, 10, 20, 50), number = 5),
    gbm = list(n.trees = 500, cv_n.trees = 100),
    rpart = list(cp = 0.001)
  )
)
}
}

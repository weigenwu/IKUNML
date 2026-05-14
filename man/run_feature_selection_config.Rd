\name{run_feature_selection_config}
\alias{run_feature_selection_config}
\title{Run Feature Selection From a YAML Config}
\usage{
run_feature_selection_config(config, data = NULL)
}
\arguments{
\item{config}{A YAML file path or a named list.}
\item{data}{Optional data frame. If omitted, set \code{data_path} or \code{data} in the config.}
}
\value{
An \code{ikunml_result} object.
}
\description{
Reads a YAML/list configuration and calls \code{run_feature_selection()}.
Top-level method blocks such as \code{lasso:}, \code{SVM:}, and \code{rf:}
are converted into \code{method_params}.
}
\examples{
\dontrun{
res <- run_feature_selection_config("config.yml")

res <- run_feature_selection_config(list(
  data_path = "data.csv",
  row_names = 1,
  group_col = "group",
  methods = c("lasso", "SVM", "rf"),
  lasso = list(alpha = 0.5),
  SVM = list(tolerance = 0.02),
  rf = list(ntree = 1000)
))
}
}

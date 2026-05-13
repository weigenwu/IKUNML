\name{run_feature_selection}
\alias{run_feature_selection}
\title{Run Multiple Feature Selection Methods}
\usage{
run_feature_selection(data, group_col = "group", feature_cols = NULL,
  methods = c("lasso", "boruta", "rf", "xgboost"),
  method_params = list(), positive_class = NULL, seed = 123,
  output_dir = NULL, continue_on_error = FALSE, drop_na = TRUE)
}
\arguments{
\item{data}{Input data frame.}
\item{group_col}{Name or index of the grouping column.}
\item{feature_cols}{Optional feature column names or indices.}
\item{methods}{Methods to run. Use \code{"all"} to request every supported method.
Use \code{"lasso"} for the default \code{alpha = 1} \pkg{glmnet} model,
\code{"elastic_net"} for the same backend with default \code{alpha = 0.5}, and
\code{"ga"} for genetic algorithm feature selection.}
\item{method_params}{Named list of method-specific parameter lists.}
\item{positive_class}{Optional positive class label for binary methods.}
\item{seed}{Random seed passed to methods unless overridden in \code{method_params}.}
\item{output_dir}{Optional directory for exported result tables.}
\item{continue_on_error}{If \code{TRUE}, failed methods are recorded and later methods continue.}
\item{drop_na}{Whether to remove incomplete samples.}
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
  )
)
}
}

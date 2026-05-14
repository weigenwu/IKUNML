\name{stability_selection}
\alias{stability_selection}
\alias{write_stability_results}
\title{Repeated Resampling Stability Selection}
\usage{
stability_selection(data, group_col = "group", feature_cols = NULL,
  methods = c("lasso", "rf"), method_params = list(), positive_class = NULL,
  seed = 123, n_iter = 50, sample_fraction = 0.8, min_frequency = 0.6,
  output_dir = NULL, parallel = FALSE, cores = NULL, progress = TRUE,
  drop_na = TRUE, continue_on_error = TRUE)

write_stability_results(result, output_dir = "IKUNML_stability")
}
\arguments{
\item{data}{Input data frame.}
\item{group_col}{Name or index of the grouping column.}
\item{feature_cols}{Optional feature column names or indices.}
\item{methods}{Feature selection methods to repeat.}
\item{method_params}{Named list of method-specific parameter lists.}
\item{positive_class}{Optional positive class label for binary methods.}
\item{seed}{Random seed.}
\item{n_iter}{Number of resampling iterations.}
\item{sample_fraction}{Fraction sampled within each class per iteration.}
\item{min_frequency}{Minimum selection frequency used to call a feature stable.}
\item{output_dir}{Optional output directory.}
\item{parallel}{Whether to parallelize resampling iterations.}
\item{cores}{Number of worker cores.}
\item{progress}{Whether to print progress messages.}
\item{drop_na}{Whether to remove incomplete samples.}
\item{continue_on_error}{Whether failed iterations/methods should be recorded and skipped.}
\item{result}{A result from \code{stability_selection()}.}
}
\value{
An \code{ikun_stability_result} object or the output directory invisibly.
}
\description{
Repeats feature selection on stratified subsamples and reports how often each
feature is selected by each method.
}

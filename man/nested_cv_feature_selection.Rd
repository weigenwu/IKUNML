\name{nested_cv_feature_selection}
\alias{nested_cv_feature_selection}
\alias{write_nested_cv_results}
\title{Nested Cross-Validation for Feature Selection}
\usage{
nested_cv_feature_selection(data, group_col = "group", feature_cols = NULL,
  methods = c("lasso", "rf"), method_params = list(), positive_class = NULL,
  model = c("glm", "randomForest", "svm"), outer_folds = 5, min_hits = NULL,
  fallback_min_hits = 1, max_fallback_features = 30, seed = 123,
  threshold = 0.5, output_dir = NULL, parallel = FALSE, cores = NULL,
  progress = TRUE, drop_na = TRUE, ...)

write_nested_cv_results(result, output_dir = "IKUNML_nested_cv")
}
\arguments{
\item{data}{Input data frame.}
\item{group_col}{Name or index of the grouping column.}
\item{feature_cols}{Optional feature column names or indices.}
\item{methods}{Feature selection methods used inside each training fold.}
\item{method_params}{Named list of method-specific parameter lists.}
\item{positive_class}{Positive class label.}
\item{model}{Classifier used for fold validation.}
\item{outer_folds}{Number of outer cross-validation folds.}
\item{min_hits}{Minimum method hit count for selecting features inside each fold.}
\item{fallback_min_hits}{Fallback hit count if the full intersection is empty.}
\item{max_fallback_features}{Maximum fallback features to use.}
\item{seed}{Random seed.}
\item{threshold}{Probability threshold for predicted class calls.}
\item{output_dir}{Optional output directory.}
\item{parallel}{Whether to parallelize outer folds.}
\item{cores}{Number of worker cores.}
\item{progress}{Whether to print progress messages.}
\item{drop_na}{Whether to remove incomplete samples.}
\item{...}{Additional classifier parameters.}
\item{result}{A result from \code{nested_cv_feature_selection()}.}
}
\value{
An \code{ikun_nested_cv_result} object or the output directory invisibly.
}
\description{
Runs feature selection inside each outer training fold, then validates the
selected features on the held-out fold. This is intended to reduce optimistic
bias from selecting features on the full dataset before model evaluation.
}

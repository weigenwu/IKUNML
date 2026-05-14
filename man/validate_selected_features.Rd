\name{validate_selected_features}
\alias{validate_selected_features}
\alias{write_validation_results}
\title{Validate Selected Features With a Classifier}
\usage{
validate_selected_features(data, result = NULL, features = NULL, methods = NULL,
  min_hits = NULL, group_col = "group", positive_class = NULL,
  model = c("glm", "randomForest", "svm"), train_fraction = 0.7,
  test_data = NULL, seed = 123, threshold = 0.5, output_dir = NULL,
  plot_formats = c("pdf", "tiff"), tiff_res = 300, drop_na = TRUE, ...)

write_validation_results(result, output_dir = "IKUNML_validation",
  plot_formats = c("pdf", "tiff"), tiff_res = 300)
}
\arguments{
\item{data}{Training data frame.}
\item{result}{Optional \code{ikunml_result} object used to derive features.}
\item{features}{Optional explicit feature vector.}
\item{methods}{Optional methods used when deriving features from \code{result}.}
\item{min_hits}{Optional minimum method hit count used when deriving features.}
\item{group_col}{Name or index of the grouping column.}
\item{positive_class}{Positive class label. Defaults to the second factor level.}
\item{model}{Classifier used for validation.}
\item{train_fraction}{Train fraction when \code{test_data} is not supplied.}
\item{test_data}{Optional external validation data frame.}
\item{seed}{Random seed for train/test split.}
\item{threshold}{Probability threshold for predicted class calls.}
\item{output_dir}{Optional output directory.}
\item{plot_formats}{Plot formats to export.}
\item{tiff_res}{TIFF resolution in dots per inch.}
\item{drop_na}{Whether to remove incomplete samples.}
\item{...}{Additional model parameters.}
}
\value{
An \code{ikun_validation_result} object or the output directory invisibly.
}
\description{
Fits a classifier from selected features and exports validation metrics,
predictions, ROC data, ROC plots, and the fitted model.
}

\name{available_methods}
\alias{available_methods}
\title{List Supported Feature Selection Methods}
\usage{
available_methods()
}
\value{
A character vector of method names accepted by \code{run_feature_selection()}.
}
\description{
Returns the feature-selection method identifiers supported by IKUNML.
The returned methods include \code{"ga"} for genetic algorithm selection and
\code{"elastic_net"} as a clearer alias for \pkg{glmnet} models with
\code{0 < alpha < 1}. The \code{"svm_rfe"} method implements the old multiple
SVM-RFE workflow often sourced from \code{msvmRFE.R}. Additional methods include
\code{"caret_rfe"}, \code{"gbm"}, and \code{"rpart"}.
}
\examples{
available_methods()
}

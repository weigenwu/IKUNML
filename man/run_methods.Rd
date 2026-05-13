\name{run_methods}
\alias{run_lasso}
\alias{run_elastic_net}
\alias{run_boruta}
\alias{run_svm_rfe}
\alias{run_msvm_rfe}
\alias{run_rf}
\alias{run_caret_rfe}
\alias{run_gbm}
\alias{run_rpart}
\alias{run_xgboost}
\alias{run_ga}
\title{Run Individual Feature Selection Methods}
\usage{
run_lasso(data, group_col = "group", feature_cols = NULL, ...)

run_elastic_net(data, group_col = "group", feature_cols = NULL, ...)

run_boruta(data, group_col = "group", feature_cols = NULL, ...)

run_svm_rfe(data, group_col = "group", feature_cols = NULL, ...)

run_msvm_rfe(data, group_col = "group", feature_cols = NULL, ...)

run_rf(data, group_col = "group", feature_cols = NULL, ...)

run_caret_rfe(data, group_col = "group", feature_cols = NULL, ...)

run_gbm(data, group_col = "group", feature_cols = NULL, ...)

run_rpart(data, group_col = "group", feature_cols = NULL, ...)

run_xgboost(data, group_col = "group", feature_cols = NULL, ...)

run_ga(data, group_col = "group", feature_cols = NULL, ...)
}
\arguments{
\item{data}{Input data frame or an \code{ikun_data} object.}
\item{group_col}{Name or index of the grouping column.}
\item{feature_cols}{Optional feature column names or indices.}
\item{...}{Method-specific parameters. See the function signatures in the source for all options.}
}
\value{
An \code{ikun_method_result} object containing selected features, method output,
and parameters.
}
\description{
These functions run one feature-selection method at a time. They are useful when
you want full control over one algorithm before combining results manually.
}
\details{
\code{run_lasso()} uses \pkg{glmnet} with configurable \code{alpha}; \code{alpha = 1}
is LASSO, \code{alpha = 0} is ridge, and values between 0 and 1 are elastic net.
\code{run_elastic_net()} is a convenience wrapper around \code{run_lasso()} with
default \code{alpha = 0.5}. \code{run_boruta()} uses \pkg{Boruta}.
\code{run_svm_rfe()} uses a lightweight linear \pkg{e1071} SVM-RFE
implementation. \code{run_msvm_rfe()} implements the older multiple SVM-RFE
workflow with fold-specific rankings, \code{k} internal ranking folds,
\code{halve_above} feature halving, and an optional tuned SVM feature-count
sweep.
\code{run_rf()} uses \pkg{randomForest}. \code{run_caret_rfe()} uses
\pkg{caret}'s RFE framework, defaulting to random forest functions.
\code{run_gbm()} uses \pkg{gbm}. \code{run_rpart()} uses a classification tree
from \pkg{rpart}. \code{run_xgboost()} uses \pkg{xgboost}. \code{run_ga()} uses
\pkg{caret} genetic algorithm feature selection with random forest fitness.
}

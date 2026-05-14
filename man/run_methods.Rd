\name{run_methods}
\alias{run_lasso}
\alias{run_elastic_net}
\alias{run_boruta}
\alias{run_SVM}
\alias{run_svm_rfe}
\alias{run_rf}
\alias{run_caret_rfe}
\alias{run_gbm}
\alias{run_rpart}
\alias{run_xgboost}
\alias{run_ga}
\title{Run Individual Feature Selection Methods}
\usage{
run_lasso(data, group_col = "group", feature_cols = NULL,
  positive_class = NULL, seed = 123, family = "binomial", alpha = 1,
  nlambda = 100, nfolds = 10,
  lambda_choice = c("lambda.min", "lambda.1se"), standardize = TRUE,
  type.measure = NULL, drop_na = TRUE, ...)

run_elastic_net(data, group_col = "group", feature_cols = NULL,
  positive_class = NULL, seed = 123, family = "binomial", alpha = 0.5,
  nlambda = 100, nfolds = 10,
  lambda_choice = c("lambda.min", "lambda.1se"), standardize = TRUE,
  type.measure = NULL, drop_na = TRUE, ...)

run_boruta(data, group_col = "group", feature_cols = NULL,
  positive_class = NULL, seed = 123, ntree = 500, maxRuns = 100,
  pValue = 0.01, mcAdj = TRUE, doTrace = 0,
  tentative_rough_fix = TRUE, with_tentative = FALSE, drop_na = TRUE,
  ...)

run_SVM(...)

run_svm_rfe(data, group_col = "group", feature_cols = NULL,
  positive_class = NULL, seed = 123, k = 10, halve_above = 50,
  rank_cost = 10, rank_scale = TRUE, cachesize = 500, nfolds = 5,
  max_features = 200, tolerance = 0, prefer = c("largest", "smallest"),
  tune = TRUE, tune_ranges = list(gamma = 2^(-12:0), cost = 2^(-6:6)),
  tune_sampling = "cross", performance_kernel = "radial",
  performance_scale = TRUE, performance_params = list(),
  performance_cost = 10, performance_gamma = NULL, verbose = FALSE,
  drop_na = TRUE, ...)

run_rf(data, group_col = "group", feature_cols = NULL,
  positive_class = NULL, seed = 123, ntree = 500, importance_type = 1,
  importance_measure = NULL, scale_importance = TRUE, nfolds = 5,
  cv_ntree = 500, max_features = 200, tolerance = 0,
  prefer = c("largest", "smallest"), selection_size = NULL,
  drop_na = TRUE, ...)

run_caret_rfe(data, group_col = "group", feature_cols = NULL,
  positive_class = NULL, seed = 123, sizes = NULL, max_features = 200,
  functions = c("rf", "treebag", "caret"), method = "cv", number = 5,
  metric = NULL, maximize = NULL, rfe_control_args = list(),
  drop_na = TRUE, ...)

run_gbm(data, group_col = "group", feature_cols = NULL,
  positive_class = NULL, seed = 123, n.trees = 500,
  interaction.depth = 3, shrinkage = 0.05, n.minobsinnode = 10,
  bag.fraction = 0.5, cv_n.trees = 100, nfolds = 5,
  max_features = 200, tolerance = 0, prefer = c("largest", "smallest"),
  selection_size = NULL, threshold = 0.5, verbose = FALSE,
  drop_na = TRUE, ...)

run_rpart(data, group_col = "group", feature_cols = NULL,
  positive_class = NULL, seed = 123, cp = 0.01, minsplit = 20,
  maxdepth = 30, xval = 10, nfolds = 5, max_features = 200,
  tolerance = 0, prefer = c("largest", "smallest"),
  selection_size = NULL, drop_na = TRUE, ...)

run_xgboost(data, group_col = "group", feature_cols = NULL,
  positive_class = NULL, seed = 123, params = list(), nrounds = 500,
  cv_nrounds = 100, max_features = 200, nfolds = 5, tolerance = 0,
  prefer = c("largest", "smallest"), threshold = 0.5,
  record_eval = TRUE, verbose = 0, drop_na = TRUE, ...)

run_ga(data, group_col = "group", feature_cols = NULL,
  positive_class = NULL, seed = 123, iters = 30, popSize = 20,
  method = "cv", nfolds = 5, ntree = 100, parallel = FALSE,
  cores = NULL, drop_na = TRUE, ...)
}
\arguments{
\item{data}{Input data frame or an \code{ikun_data} object.}
\item{group_col}{Name or index of the grouping column.}
\item{feature_cols}{Optional feature column names or indices.}
\item{positive_class}{Optional positive class label for binary methods.}
\item{seed}{Random seed.}
\item{family}{\pkg{glmnet} response family.}
\item{alpha}{\pkg{glmnet} mixing parameter. \code{1} is LASSO and values between 0 and 1 are elastic net.}
\item{nlambda}{Number of \pkg{glmnet} lambda values.}
\item{nfolds}{Number of cross-validation folds.}
\item{lambda_choice}{Lambda used to extract non-zero \pkg{glmnet} coefficients.}
\item{standardize}{Whether \pkg{glmnet} should standardize predictors.}
\item{type.measure}{Optional \pkg{glmnet} cross-validation metric.}
\item{drop_na}{Whether to remove incomplete samples.}
\item{ntree}{Number of random forest trees.}
\item{maxRuns}{Maximum Boruta runs.}
\item{pValue}{Boruta p-value threshold.}
\item{mcAdj}{Whether Boruta applies multiple-comparison adjustment.}
\item{doTrace}{Boruta trace level.}
\item{tentative_rough_fix}{Whether to apply \code{TentativeRoughFix()}.}
\item{with_tentative}{Whether tentative Boruta attributes are returned.}
\item{k}{Internal folds used by multiple SVM-RFE ranking.}
\item{halve_above}{Feature count above which SVM-RFE removes half of remaining features each step.}
\item{rank_cost}{Linear SVM cost used for feature ranking.}
\item{rank_scale}{Whether to scale predictors before SVM-RFE ranking.}
\item{cachesize}{SVM cache size.}
\item{max_features}{Maximum number of top-ranked features evaluated.}
\item{tolerance}{Performance tolerance for selecting the final feature count.}
\item{prefer}{Whether to prefer the largest or smallest feature count within tolerance.}
\item{tune}{Whether to tune SVM parameters during the feature-count sweep.}
\item{tune_ranges}{Parameter ranges passed to \pkg{e1071} tuning.}
\item{tune_sampling}{Sampling mode passed to \pkg{e1071} tuning.}
\item{performance_kernel}{SVM kernel used during performance evaluation.}
\item{performance_scale}{Whether to scale predictors during SVM performance evaluation.}
\item{performance_params}{Additional SVM performance parameters.}
\item{performance_cost}{SVM cost used when \code{tune = FALSE}.}
\item{performance_gamma}{SVM gamma used when \code{tune = FALSE}.}
\item{verbose}{Whether to print method-level progress.}
\item{importance_type}{Random forest importance type.}
\item{importance_measure}{Column used to rank random forest importance.}
\item{scale_importance}{Whether to scale random forest importance.}
\item{cv_ntree}{Number of trees used in random forest feature-count cross-validation.}
\item{selection_size}{Optional fixed number of top features to select.}
\item{sizes}{Candidate feature subset sizes for \pkg{caret} RFE.}
\item{functions}{\pkg{caret} RFE function set or custom function list.}
\item{method}{Resampling method for \pkg{caret} RFE or genetic algorithm.}
\item{number}{Number of \pkg{caret} resampling folds/repeats.}
\item{metric}{Metric optimized by \pkg{caret} RFE.}
\item{maximize}{Whether the \pkg{caret} RFE metric should be maximized.}
\item{rfe_control_args}{Additional arguments passed to \code{caret::rfeControl()}.}
\item{n.trees}{Number of GBM trees.}
\item{interaction.depth}{GBM interaction depth.}
\item{shrinkage}{GBM learning rate.}
\item{n.minobsinnode}{GBM minimum observations in terminal nodes.}
\item{bag.fraction}{GBM bagging fraction.}
\item{cv_n.trees}{Number of GBM trees used during feature-count cross-validation.}
\item{threshold}{Probability threshold for binary class predictions.}
\item{cp}{Complexity parameter for \pkg{rpart}.}
\item{minsplit}{Minimum split size for \pkg{rpart}.}
\item{maxdepth}{Maximum tree depth for \pkg{rpart}.}
\item{xval}{Internal cross-validation count for \pkg{rpart}.}
\item{params}{Named list of XGBoost parameters.}
\item{nrounds}{Number of XGBoost boosting rounds.}
\item{cv_nrounds}{Number of XGBoost rounds used during feature-count cross-validation.}
\item{record_eval}{Whether to keep XGBoost training evaluation logs.}
\item{iters}{Number of genetic algorithm iterations.}
\item{popSize}{Genetic algorithm population size.}
\item{parallel}{Whether to use parallel processing where supported.}
\item{cores}{Number of parallel worker cores.}
\item{...}{Additional method-specific parameters passed to the backend.}
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
\code{run_SVM()} and the backward-compatible \code{run_svm_rfe()} implement the older multiple SVM-RFE workflow with
fold-specific rankings, \code{k} internal ranking folds, \code{halve_above}
feature halving, and an optional tuned SVM feature-count sweep.
For easier migration from older scripts, \code{halve.above}, \code{cost}, and
\code{scale} are accepted through \code{...} and mapped onto the current
SVM-RFE parameters.
\code{run_rf()} uses \pkg{randomForest}. \code{run_caret_rfe()} uses
\pkg{caret}'s RFE framework, defaulting to random forest functions.
\code{run_gbm()} uses \pkg{gbm}. \code{run_rpart()} uses a classification tree
from \pkg{rpart}. \code{run_xgboost()} uses \pkg{xgboost}. \code{run_ga()} uses
\pkg{caret} genetic algorithm feature selection with random forest fitness.
}

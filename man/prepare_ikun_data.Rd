\name{prepare_ikun_data}
\alias{prepare_ikun_data}
\title{Prepare Data for IKUNML Methods}
\usage{
prepare_ikun_data(data, group_col = "group", feature_cols = NULL,
  positive_class = NULL, drop_na = TRUE)
}
\arguments{
\item{data}{A data frame containing one group column and feature columns.}
\item{group_col}{Name or index of the grouping column.}
\item{feature_cols}{Optional feature column names or indices. Defaults to all non-group columns.}
\item{positive_class}{Optional positive class label for binary methods.}
\item{drop_na}{Whether to remove samples with missing group or feature values.}
}
\value{
An \code{ikun_data} object containing numeric features, factor group labels, and
a mapping between original and internal feature names.
}
\description{
Converts user data into the internal format used by IKUNML. Feature names are
made syntactically safe internally and restored in exported results.
}

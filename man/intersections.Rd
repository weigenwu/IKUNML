\name{intersections}
\alias{feature_sets}
\alias{feature_intersection}
\alias{feature_hit_summary}
\title{Summarize Selected Feature Overlap}
\usage{
feature_sets(result, methods = NULL)

feature_intersection(result, methods = NULL, min_hits = NULL)

feature_hit_summary(result, methods = NULL)
}
\arguments{
\item{result}{An \code{ikunml_result} or \code{ikun_method_result} object.}
\item{methods}{Optional methods to include.}
\item{min_hits}{Optional minimum number of methods that must select a feature.}
}
\value{
\code{feature_sets()} returns a named list. \code{feature_intersection()}
returns a character vector. \code{feature_hit_summary()} returns a data frame.
}
\description{
Extract selected feature sets, compute complete intersections, or create a
feature-by-method hit summary table.
}

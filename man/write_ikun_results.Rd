\name{write_ikun_results}
\alias{write_ikun_results}
\title{Write IKUNML Result Tables}
\usage{
write_ikun_results(result, output_dir = "IKUNML_results", overwrite = TRUE)
}
\arguments{
\item{result}{An \code{ikunml_result} object.}
\item{output_dir}{Directory where result files are written.}
\item{overwrite}{Reserved for future overwrite checks.}
}
\value{
The output directory, invisibly.
}
\description{
Writes selected feature lists, rankings, importance tables, cross-validation
metrics, common features, and hit summaries to disk.
}

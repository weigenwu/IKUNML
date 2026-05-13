\name{write_ikun_results}
\alias{write_ikun_results}
\title{Write IKUNML Result Tables}
\usage{
write_ikun_results(result, output_dir = "IKUNML_results", overwrite = TRUE,
  write_plots = FALSE, save_models = FALSE)
}
\arguments{
\item{result}{An \code{ikunml_result} object.}
\item{output_dir}{Directory where result files are written.}
\item{overwrite}{Reserved for future overwrite checks.}
\item{write_plots}{Whether to also write method diagnostic PDF plots.}
\item{save_models}{Whether to save method result and model objects as RDS files.}
}
\value{
The output directory, invisibly.
}
\description{
Writes selected feature lists, rankings, importance tables, cross-validation
metrics, common features, and hit summaries to disk.
When requested, it also saves diagnostic plots and RDS model objects. This is
especially useful for GA runs because those are expensive to repeat.
}

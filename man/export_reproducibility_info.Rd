\name{export_reproducibility_info}
\alias{export_reproducibility_info}
\title{Export Reproducibility Information}
\usage{
export_reproducibility_info(output_dir = "IKUNML_reproducibility",
  include_installed_packages = TRUE, include_renv_lock = FALSE,
  renv_lockfile = "renv.lock")
}
\arguments{
\item{output_dir}{Directory where reproducibility files are written.}
\item{include_installed_packages}{Whether to export all installed package versions.}
\item{include_renv_lock}{Whether to create an \pkg{renv} lockfile. Requires \pkg{renv}.}
\item{renv_lockfile}{Name of the lockfile when \code{include_renv_lock = TRUE}.}
}
\value{
A list of output paths, invisibly.
}
\description{
Writes \code{sessionInfo()}, basic system metadata, installed package versions,
and optionally an \pkg{renv} lockfile for analysis reproducibility.
}

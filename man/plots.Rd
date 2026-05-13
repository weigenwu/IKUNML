\name{plots}
\alias{plot_upset}
\alias{plot_venn}
\alias{write_ikun_plots}
\title{Plot Feature Selection Overlaps}
\usage{
plot_upset(result, methods = NULL, file = NULL, width = 10, height = 6,
  nintersects = 30, ...)

plot_venn(result, methods = NULL, file = NULL, width = 8, height = 8,
  fill = NULL, alpha = 0.6, ...)

write_ikun_plots(result, output_dir = "IKUNML_results", methods = NULL,
  top_n = 30)
}
\arguments{
\item{result}{An \code{ikunml_result} object.}
\item{methods}{Optional methods to include.}
\item{file}{Optional PDF file path.}
\item{width}{PDF width.}
\item{height}{PDF height.}
\item{nintersects}{Number of intersections shown in the UpSet plot.}
\item{fill}{Optional Venn fill colors.}
\item{alpha}{Venn fill transparency.}
\item{...}{Additional arguments passed to the plotting backend.}
\item{top_n}{Number of top features shown in method diagnostic bar plots.}
}
\value{
The plotting data or grob object, invisibly.
}
\description{
Draw UpSet or Venn diagrams for selected feature overlaps. Use UpSet plots for
six or more methods.
\code{write_ikun_plots()} writes method-specific diagnostic plots such as
glmnet CV curves, SVM-RFE/mSVM-RFE error and accuracy curves, RF/XGBoost CV
accuracy curves, feature-importance bar plots, Boruta importance plots, and GA
evolution curves.
}

plot_upset <- function(result,
                       methods = NULL,
                       file = NULL,
                       width = 10,
                       height = 6,
                       nintersects = 30,
                       ...) {
  .require_pkg("UpSetR")
  sets <- feature_sets(result, methods)
  upset_data <- UpSetR::fromList(sets)

  if (!is.null(file)) {
    grDevices::pdf(file, width = width, height = height, onefile = FALSE)
    on.exit(grDevices::dev.off(), add = TRUE)
  }

  UpSetR::upset(
    upset_data,
    nsets = length(sets),
    nintersects = nintersects,
    order.by = "freq",
    keep.order = TRUE,
    ...
  )
  invisible(upset_data)
}

plot_venn <- function(result,
                      methods = NULL,
                      file = NULL,
                      width = 8,
                      height = 8,
                      fill = NULL,
                      alpha = 0.6,
                      ...) {
  .require_pkg("VennDiagram")
  .require_pkg("grid")
  sets <- feature_sets(result, methods)
  if (length(sets) > 5L) {
    stop("VennDiagram supports up to 5 sets here. Use plot_upset() for 6 or more methods.", call. = FALSE)
  }
  fill <- fill %||% c("#B2E5A0", "#F7CB65", "#EFA39F", "#A0D8EA", "#9C7FAE")[seq_along(sets)]

  venn_object <- VennDiagram::venn.diagram(
    x = sets,
    category.names = names(sets),
    filename = NULL,
    fill = fill,
    alpha = alpha,
    ...
  )

  if (!is.null(file)) {
    grDevices::pdf(file, width = width, height = height)
    on.exit(grDevices::dev.off(), add = TRUE)
  }

  grid::grid.draw(venn_object)
  invisible(venn_object)
}

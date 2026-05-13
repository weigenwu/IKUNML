run_boruta <- function(data,
                       group_col = "group",
                       feature_cols = NULL,
                       positive_class = NULL,
                       seed = 123,
                       ntree = 500,
                       maxRuns = 100,
                       pValue = 0.01,
                       mcAdj = TRUE,
                       doTrace = 0,
                       tentative_rough_fix = TRUE,
                       with_tentative = FALSE,
                       drop_na = TRUE,
                       ...) {
  .require_pkg("Boruta")
  prepared <- .ensure_ikun_data(data, group_col, feature_cols, positive_class, drop_na)
  analysis_data <- data.frame(Group = prepared$y, prepared$x, check.names = FALSE)

  .set_seed(seed)
  boruta_obj <- Boruta::Boruta(
    Group ~ .,
    data = analysis_data,
    ntree = ntree,
    maxRuns = maxRuns,
    pValue = pValue,
    mcAdj = mcAdj,
    doTrace = doTrace,
    ...
  )

  final_obj <- if (tentative_rough_fix) {
    Boruta::TentativeRoughFix(boruta_obj)
  } else {
    boruta_obj
  }

  selected <- Boruta::getSelectedAttributes(final_obj, withTentative = with_tentative)
  stats_table <- Boruta::attStats(final_obj)
  stats_table <- data.frame(
    feature_internal = rownames(stats_table),
    feature = .restore_feature_names(rownames(stats_table), prepared),
    stats_table,
    row.names = NULL,
    check.names = FALSE
  )

  .method_result(
    method = "boruta",
    selected_internal = selected,
    prepared = prepared,
    stats = stats_table,
    model = boruta_obj,
    final_model = final_obj,
    params = list(
      ntree = ntree,
      maxRuns = maxRuns,
      pValue = pValue,
      mcAdj = mcAdj,
      tentative_rough_fix = tentative_rough_fix,
      with_tentative = with_tentative,
      seed = seed
    )
  )
}

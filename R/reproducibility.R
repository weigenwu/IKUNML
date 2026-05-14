.installed_package_versions <- function() {
  pkgs <- utils::installed.packages()
  out <- data.frame(
    package = rownames(pkgs),
    version = pkgs[, "Version"],
    lib_path = pkgs[, "LibPath"],
    stringsAsFactors = FALSE
  )
  rownames(out) <- NULL
  out[order(out$package), , drop = FALSE]
}

export_reproducibility_info <- function(output_dir = "IKUNML_reproducibility",
                                        include_installed_packages = TRUE,
                                        include_renv_lock = FALSE,
                                        renv_lockfile = "renv.lock") {
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  session_path <- file.path(output_dir, "sessionInfo.txt")
  writeLines(utils::capture.output(utils::sessionInfo()), session_path)

  system_info <- data.frame(
    item = c("R.version", "platform", "system", "user", "working_directory", "created_at"),
    value = c(
      paste(R.version$major, R.version$minor, sep = "."),
      R.version$platform,
      paste(Sys.info()[c("sysname", "release", "version")], collapse = " "),
      Sys.info()[["user"]],
      getwd(),
      format(Sys.time(), "%Y-%m-%d %H:%M:%S")
    ),
    stringsAsFactors = FALSE
  )
  utils::write.csv(system_info, file.path(output_dir, "system_info.csv"), row.names = FALSE)

  if (include_installed_packages) {
    utils::write.csv(
      .installed_package_versions(),
      file.path(output_dir, "installed_packages.csv"),
      row.names = FALSE
    )
  }

  lockfile_path <- NA_character_
  if (include_renv_lock) {
    .require_pkg("renv")
    lockfile_path <- file.path(output_dir, renv_lockfile)
    renv::snapshot(lockfile = lockfile_path, prompt = FALSE)
  }

  out <- list(
    output_dir = normalizePath(output_dir, winslash = "/", mustWork = FALSE),
    session_info = session_path,
    system_info = file.path(output_dir, "system_info.csv"),
    installed_packages = if (include_installed_packages) file.path(output_dir, "installed_packages.csv") else NULL,
    renv_lockfile = if (include_renv_lock) lockfile_path else NULL
  )
  invisible(out)
}

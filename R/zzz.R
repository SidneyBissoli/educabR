# package initialization

.onLoad <- function(libname, pkgname) {
  # initialize cache directory from option if set
  cache_dir <- getOption("educabR.cache_dir")

  if (!is.null(cache_dir)) {
    .educabr_env$cache_dir <- cache_dir
  }

  invisible()
}

.onAttach <- function(libname, pkgname) {
  packageStartupMessage(
    "educabR: Download and Process Brazilian Education Data from INEP\n",
    "Use set_cache_dir() to configure a persistent cache directory."
  )
}

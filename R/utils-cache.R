# cache utilities for educabR
# handles local caching of downloaded files

# environment to store package options
.educabr_env <- new.env(parent = emptyenv())

#' Set the cache directory for educabR
#'
#' @description
#' Sets the directory where downloaded files will be cached. This avoids
#' repeated downloads of the same data.
#'
#' @param path A character string with the path to the cache directory.
#'   If `NULL`, uses a temporary directory (default).
#' @param persistent Logical. If `TRUE`, the cache directory setting is
#'   saved to the user's R profile for future sessions.
#'
#' @return Invisibly returns the cache directory path.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # set a persistent cache directory
#' set_cache_dir("~/educabR_cache")
#' }
set_cache_dir <- function(path = NULL, persistent = FALSE) {
  if (is.null(path)) {
    path <- file.path(tempdir(), "educabR_cache")
  }

  # expand path
  path <- normalizePath(path, mustWork = FALSE)

  # create directory if it doesn't exist
  if (!dir.exists(path)) {
    dir.create(path, recursive = TRUE, showWarnings = FALSE)
    cli::cli_alert_success("cache directory created: {.path {path}}")
  }

  # set in package environment
  .educabr_env$cache_dir <- path

  # set as option
  options(educabR.cache_dir = path)

  if (persistent) {
    cli::cli_alert_info(
      "to make this setting persistent, add to your .Rprofile:"
    )
    cli::cli_code('options(educabR.cache_dir = "{path}")')
  }

  invisible(path)
}

#' Get the current cache directory
#'
#' @description
#' Returns the current cache directory used by educabR.
#'
#' @return A character string with the path to the cache directory.
#'
#' @export
#'
#' @examples
#' get_cache_dir()
get_cache_dir <- function() {
  # check option first
  cache_dir <- getOption("educabR.cache_dir")

  # then check environment
  if (is.null(cache_dir)) {
    cache_dir <- .educabr_env$cache_dir
  }

  # default to temp directory
  if (is.null(cache_dir)) {
    cache_dir <- file.path(tempdir(), "educabR_cache")
    .educabr_env$cache_dir <- cache_dir
  }

  # ensure directory exists
  if (!dir.exists(cache_dir)) {
    dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  }

  cache_dir
}

#' Clear the educabR cache
#'
#' @description
#' Removes all cached files from the educabR cache directory.
#'
#' @param dataset Optional. A character string specifying which dataset
#'   cache to clear. If `NULL`, clears all caches.
#'
#' @return Invisibly returns `TRUE` if successful.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # clear all cached data
#' clear_cache()
#'
#' # clear only ENEM cache
#' clear_cache("enem")
#' }
clear_cache <- function(dataset = NULL) {
  cache_dir <- get_cache_dir()

  if (is.null(dataset)) {
    # clear all
    files <- list.files(cache_dir, full.names = TRUE, recursive = TRUE)
    if (length(files) > 0) {
      unlink(files, recursive = TRUE)
      cli::cli_alert_success("cleared {length(files)} cached file(s)")
    } else {
      cli::cli_alert_info("cache is already empty")
    }
  } else {
    # clear specific dataset
    dataset_dir <- file.path(cache_dir, dataset)
    if (dir.exists(dataset_dir)) {
      unlink(dataset_dir, recursive = TRUE)
      cli::cli_alert_success("cleared cache for {.val {dataset}}")
    } else {
      cli::cli_alert_info("no cache found for {.val {dataset}}")
    }
  }

  invisible(TRUE)
}

#' List cached files
#'
#' @description
#' Lists all files currently in the educabR cache.
#'
#' @param dataset Optional. Filter by dataset name.
#'
#' @return A tibble with information about cached files.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' list_cache()
#' }
list_cache <- function(dataset = NULL) {
  cache_dir <- get_cache_dir()

  if (!is.null(dataset)) {
    cache_dir <- file.path(cache_dir, dataset)
  }

  if (!dir.exists(cache_dir)) {
    return(
      dplyr::tibble(
        file = character(),
        size_mb = numeric(),
        modified = as.POSIXct(character())
      )
    )
  }

  files <- list.files(cache_dir, full.names = TRUE, recursive = TRUE)

  if (length(files) == 0) {
    return(
      dplyr::tibble(
        file = character(),
        size_mb = numeric(),
        modified = as.POSIXct(character())
      )
    )
  }

  info <- file.info(files)

  dplyr::tibble(
    file = basename(files),
    size_mb = round(info$size / 1024^2, 2),
    modified = info$mtime
  )
}

# internal function to get cache path for a specific file
cache_path <- function(dataset, filename) {
  cache_dir <- get_cache_dir()
  dataset_dir <- file.path(cache_dir, dataset)

  if (!dir.exists(dataset_dir)) {
    dir.create(dataset_dir, recursive = TRUE, showWarnings = FALSE)
  }

  file.path(dataset_dir, filename)
}

# internal function to check if file is cached
is_cached <- function(dataset, filename) {
  path <- cache_path(dataset, filename)
  file.exists(path)
}

# download utilities for educabR
# handles file downloads from INEP

# inep base urls
inep_base_url <- function() {
  "https://download.inep.gov.br"
}

#' Download a file from INEP
#'
#' @description
#' Internal function to download files from INEP's servers with
#' progress indication and error handling.
#'
#' @param url The URL to download from.
#' @param destfile The destination file path.
#' @param quiet Logical. If `TRUE`, suppresses progress messages.
#'
#' @return The path to the downloaded file.
#'
#' @keywords internal
download_inep_file <- function(url, destfile, quiet = FALSE) {
  if (!quiet) {
    cli::cli_alert_info("downloading from INEP...")
  }

  # create directory if needed
  dir.create(dirname(destfile), recursive = TRUE, showWarnings = FALSE)

  # use httr2 for better error handling
  tryCatch(
    {
      req <- httr2::request(url) |>
        httr2::req_timeout(seconds = 600) |>
        httr2::req_retry(max_tries = 3, backoff = ~ 5)

      resp <- httr2::req_perform(req)

      # write to file
      writeBin(httr2::resp_body_raw(resp), destfile)

      if (!quiet) {
        size_mb <- round(file.size(destfile) / 1024^2, 2)
        cli::cli_alert_success("downloaded {.val {size_mb}} MB")
      }

      destfile
    },
    error = function(e) {
      cli::cli_abort(
        c(
          "download failed",
          "x" = "url: {.url {url}}",
          "i" = "error: {conditionMessage(e)}"
        )
      )
    }
  )
}

#' Extract a ZIP file
#'
#' @description
#' Internal function to extract ZIP files with progress indication.
#'
#' @param zipfile Path to the ZIP file.
#' @param exdir Directory to extract to.
#' @param quiet Logical. If `TRUE`, suppresses progress messages.
#'
#' @return A character vector of extracted file paths.
#'
#' @keywords internal
extract_zip <- function(zipfile, exdir, quiet = FALSE) {
  if (!quiet) {
    cli::cli_alert_info("extracting files...")
  }

  # create directory if needed
  dir.create(exdir, recursive = TRUE, showWarnings = FALSE)

  # try standard unzip first, fall back to system command if encoding issues
  tryCatch(
    {
      files <- utils::unzip(zipfile, exdir = exdir)

      if (!quiet) {
        cli::cli_alert_success("extracted {.val {length(files)}} file(s)")
      }

      files
    },
    error = function(e) {
      # check if it's an encoding error (common with INEP files)
      if (grepl("multibyte|encoding|invalid", conditionMessage(e), ignore.case = TRUE)) {
        if (!quiet) {
          cli::cli_alert_warning(
            "standard extraction failed due to encoding, trying alternative method..."
          )
        }

        # try using system unzip command (Windows has tar that can handle zip)
        result <- tryCatch(
          {
            # use PowerShell Expand-Archive on Windows
            if (.Platform$OS.type == "windows") {
              cmd <- sprintf(
                'powershell -Command "Expand-Archive -Path \'%s\' -DestinationPath \'%s\' -Force"',
                normalizePath(zipfile, winslash = "/"),
                normalizePath(exdir, winslash = "/", mustWork = FALSE)
              )
              system(cmd, intern = FALSE, ignore.stdout = TRUE, ignore.stderr = TRUE)
            } else {
              # on unix, use unzip command
              system2("unzip", args = c("-o", "-q", shQuote(zipfile), "-d", shQuote(exdir)))
            }

            # list extracted files
            files <- list.files(exdir, recursive = TRUE, full.names = TRUE)

            if (length(files) > 0) {
              if (!quiet) {
                cli::cli_alert_success("extracted {.val {length(files)}} file(s)")
              }
              return(files)
            } else {
              stop("no files extracted")
            }
          },
          error = function(e2) {
            cli::cli_abort(
              c(
                "extraction failed with both methods",
                "x" = "file: {.path {zipfile}}",
                "i" = "original error: {conditionMessage(e)}",
                "i" = "alternative error: {conditionMessage(e2)}"
              )
            )
          }
        )

        return(result)
      }

      # not an encoding error, report original error
      cli::cli_abort(
        c(
          "extraction failed",
          "x" = "file: {.path {zipfile}}",
          "i" = "error: {conditionMessage(e)}"
        )
      )
    }
  )
}

#' Build INEP microdata URL
#'
#' @description
#' Internal function to construct URLs for INEP microdata.
#'
#' @param dataset The dataset name (e.g., "censo_escolar", "enem").
#' @param year The year of the data.
#' @param ... Additional parameters for URL construction.
#'
#' @return A character string with the URL.
#'
#' @keywords internal
build_inep_url <- function(dataset, year, ...) {
  base <- inep_base_url()

  url <- switch(
    dataset,
    "censo_escolar" = str_c(
      base, "/dados_abertos/microdados_censo_escolar_", year, ".zip"
    ),
    "enem" = str_c(
      base, "/microdados/microdados_enem_", year, ".zip"
    ),
    "ideb" = {
      # ideb has different structure, handled separately
      str_c(base, "/ideb/", year, "/")
    },
    cli::cli_abort("unknown dataset: {.val {dataset}}")
  )

  url
}

#' Check available years for a dataset
#'
#' @description
#' Returns the years available for a given INEP dataset.
#'
#' @param dataset The dataset name.
#'
#' @return An integer vector of available years.
#'
#' @export
#'
#' @examples
#' available_years("censo_escolar")
#' available_years("enem")
available_years <- function(dataset) {
  dataset <- match.arg(
    dataset,
    choices = c("censo_escolar", "enem", "ideb")
  )

  switch(
    dataset,
    "censo_escolar" = 1995:2024,
    "enem" = 1998:2024,
    "ideb" = c(2017L, 2019L, 2021L, 2023L)
  )
}

#' Validate year parameter
#'
#' @description
#' Internal function to validate that a year is available for a dataset.
#'
#' @param year The year to validate.
#' @param dataset The dataset name.
#'
#' @return The validated year (invisibly), or aborts with error.
#'
#' @keywords internal
validate_year <- function(year, dataset) {
  available <- available_years(dataset)

  if (!year %in% available) {
    cli::cli_abort(
      c(
        "year {.val {year}} not available for {.val {dataset}}",
        "i" = "available years: {.val {available}}"
      )
    )
  }

  invisible(year)
}

#' Find data files in extracted directory
#'
#' @description
#' Internal function to locate the main data files after extraction.
#'
#' @param exdir The extraction directory.
#' @param pattern Optional regex pattern to filter files.
#'
#' @return A character vector of file paths.
#'
#' @keywords internal
find_data_files <- function(exdir, pattern = "\\.(csv|CSV|txt|TXT)$") {
  files <- list.files(
    exdir,
    pattern = pattern,
    recursive = TRUE,
    full.names = TRUE
  )

  if (length(files) == 0) {
    cli::cli_abort(
      c(
        "no data files found",
        "i" = "directory: {.path {exdir}}",
        "i" = "pattern: {.val {pattern}}"
      )
    )
  }

  files
}

#' Detect file encoding
#'
#' @description
#' Internal function to detect the encoding of a text file.
#' INEP files typically use Latin-1 or UTF-8.
#'
#' @param file Path to the file.
#'
#' @return A character string with the encoding name.
#'
#' @keywords internal
detect_encoding <- function(file) {
  # read first few lines and check for encoding issues
  tryCatch(
    {
      lines <- readLines(file, n = 10, encoding = "UTF-8", warn = FALSE)
      # if no errors, likely UTF-8
      "UTF-8"
    },
    error = function(e) {
      # try Latin-1
      "Latin-1"
    }
  )
}

#' Read INEP data file
#'
#' @description
#' Internal function to read INEP data files with appropriate settings.
#'
#' @param file Path to the data file.
#' @param delim The delimiter character.
#' @param encoding The file encoding.
#' @param n_max Maximum number of rows to read.
#'
#' @return A tibble with the data.
#'
#' @keywords internal
read_inep_file <- function(file,
                           delim = ";",
                           encoding = NULL,
                           n_max = Inf) {
  # detect encoding if not specified
  if (is.null(encoding)) {
    encoding <- detect_encoding(file)
  }

  cli::cli_alert_info("reading file with encoding: {.val {encoding}}")

  # read with readr
  readr::read_delim(
    file,
    delim = delim,
    locale = readr::locale(encoding = encoding),
    show_col_types = FALSE,
    n_max = n_max,
    progress = TRUE
  )
}

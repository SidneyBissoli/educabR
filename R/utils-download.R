# download utilities for educabR
# handles file downloads from INEP

# inep base urls
inep_base_url <- function() {
  "https://download.inep.gov.br"
}

# get file size via HEAD request (returns NULL on failure)
get_remote_file_size <- function(url) {
  tryCatch(
    {
      req <- httr2::request(url) |>
        httr2::req_method("HEAD") |>
        httr2::req_timeout(seconds = 10)

      resp <- httr2::req_perform(req)
      size <- httr2::resp_header(resp, "content-length")

      if (!is.null(size)) as.numeric(size) else NULL
    },
    error = function(e) NULL
  )
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
  # create directory if needed
  dir.create(dirname(destfile), recursive = TRUE, showWarnings = FALSE)

  # check file size before downloading
  if (!quiet) {
    file_size <- get_remote_file_size(url)
    if (!is.null(file_size)) {
      size_mb <- round(file_size / 1024^2, 1)
      if (size_mb >= 1000) {
        size_label <- paste0(round(size_mb / 1024, 1), " GB")
      } else {
        size_label <- paste0(size_mb, " MB")
      }
      cli::cli_alert_info("downloading {.val {size_label}} from INEP...")
    } else {
      cli::cli_alert_info("downloading from INEP...")
    }
  }

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
      files <- withCallingHandlers(
        utils::unzip(zipfile, exdir = exdir),
        warning = function(w) {
          if (grepl("erro|error", conditionMessage(w), ignore.case = TRUE)) {
            invokeRestart("muffleWarning")
          }
        }
      )

      if (length(files) == 0) {
        stop("unzip extracted 0 files")
      }

      if (!quiet) {
        cli::cli_alert_success("extracted {.val {length(files)}} file(s)")
      }

      files
    },
    error = function(e) {
      # encoding errors or empty extraction — try alternative method
      if (TRUE) {
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

# find the 7z executable (checks PATH and common install locations)
find_7z <- function() {
  # try PATH first
  path_result <- Sys.which("7z")
  if (nzchar(path_result)) return(unname(path_result))

  # common install locations on Windows
  if (.Platform$OS.type == "windows") {
    candidates <- c(
      file.path(Sys.getenv("ProgramFiles"), "7-Zip", "7z.exe"),
      file.path(Sys.getenv("ProgramFiles(x86)"), "7-Zip", "7z.exe"),
      "C:/Program Files/7-Zip/7z.exe",
      "C:/Program Files (x86)/7-Zip/7z.exe"
    )
    for (path in candidates) {
      if (file.exists(path)) return(normalizePath(path, winslash = "/"))
    }
  }

  # not found — return "7z" and let system2 produce the error
  "7z"
}

#' Extract an archive file (ZIP, 7z, or RAR)
#'
#' @description
#' Internal function to extract archive files. Supports ZIP, 7z, and RAR
#' formats. For ZIP files, delegates to [extract_zip()]. For 7z and RAR
#' files, uses the system `7z` command.
#'
#' @param archive Path to the archive file.
#' @param exdir Directory to extract to.
#' @param quiet Logical. If `TRUE`, suppresses progress messages.
#'
#' @return A character vector of extracted file paths.
#'
#' @keywords internal
extract_archive <- function(archive, exdir, quiet = FALSE) {
  ext <- tools::file_ext(archive)

  if (tolower(ext) == "zip") {
    return(extract_zip(archive, exdir, quiet = quiet))
  }

  if (tolower(ext) %in% c("7z", "rar")) {
    if (!quiet) {
      cli::cli_alert_info("extracting {.val {ext}} archive...")
    }

    dir.create(exdir, recursive = TRUE, showWarnings = FALSE)

    # 7z handles both .7z and .rar formats
    sevenz_cmd <- find_7z()

    result <- tryCatch(
      {
        system2(
          sevenz_cmd,
          args = c("x", shQuote(normalizePath(archive, winslash = "/")),
                   paste0("-o", shQuote(normalizePath(exdir, winslash = "/", mustWork = FALSE))),
                   "-y"),
          stdout = TRUE, stderr = TRUE
        )
      },
      error = function(e) {
        cli::cli_abort(
          c(
            "failed to extract {.val {ext}} archive",
            "x" = "file: {.path {archive}}",
            "i" = "install 7-Zip ({.url https://www.7-zip.org/}) and ensure {.code 7z} is in PATH",
            "i" = "error: {conditionMessage(e)}"
          )
        )
      }
    )

    files <- list.files(exdir, recursive = TRUE, full.names = TRUE)

    if (length(files) == 0) {
      cli::cli_abort(
        c(
          "no files extracted from {.val {ext}} archive",
          "x" = "file: {.path {archive}}"
        )
      )
    }

    if (!quiet) {
      cli::cli_alert_success("extracted {.val {length(files)}} file(s)")
    }

    return(files)
  }

  cli::cli_abort("unsupported archive format: {.val {ext}}")
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
    "saeb" = {
      level <- list(...)$level %||% "fundamental_medio"
      if (year == 2021) {
        level_suffix <- switch(
          level,
          "fundamental_medio" = "_ensino_fundamental_e_medio",
          "educacao_infantil" = "_educacao_infantil"
        )
        str_c(base, "/microdados/microdados_saeb_", year, level_suffix, ".zip")
      } else {
        str_c(base, "/microdados/microdados_saeb_", year, ".zip")
      }
    },
    "censo_superior" = str_c(
      base, "/microdados/microdados_censo_da_educacao_superior_", year, ".zip"
    ),
    "enade" = str_c(
      base, "/microdados/microdados_enade_", year, ".zip"
    ),
    "encceja" = str_c(
      base, "/microdados/microdados_encceja_", year, ".zip"
    ),
    "enem_escola" = str_c(
      base, "/microdados/enem_por_escola/2005_a_2015/microdados_enem_por_escola.zip"
    ),
    "idd" = {
      ext <- if (year >= 2021) ".zip" else ".7z"
      str_c(base, "/microdados/microdados_IDD_", year, ext)
    },
    "ideb" = {
      # ideb has different structure, handled separately
      str_c(base, "/ideb/", year, "/")
    },
    cli::cli_abort("unknown dataset: {.val {dataset}}")
  )

  url
}

# hardcoded fallback years (used when dynamic discovery fails)
fallback_years <- function(dataset) {
  switch(
    dataset,
    "censo_escolar" = 1995:2024,
    "enem" = 1998:2024,
    "saeb" = c(2011L, 2013L, 2015L, 2017L, 2019L, 2021L, 2023L),
    "censo_superior" = 2009:2024,
    "enade" = c(2004L:2019L, 2021L:2023L),
    "encceja" = 2014:2024,
    "idd" = c(2014L:2019L, 2021L:2023L),
    "cpc" = c(2007L:2019L, 2021L:2023L),
    "igc" = c(2007L:2019L, 2021L:2023L),
    "capes" = 2013:2024,
    "ideb" = c(2017L, 2019L, 2021L, 2023L),
    "fundeb" = as.integer(names(fundeb_recursos_ids)),
    "fundeb_enrollment" = 2017:2018
  )
}

# candidate year range for HEAD-check discovery
# returns NULL for datasets that don't use HEAD discovery
candidate_year_range <- function(dataset) {
  current_year <- as.integer(format(Sys.Date(), "%Y"))
  switch(
    dataset,
    "censo_escolar" = 1995:current_year,
    "enem" = 1998:current_year,
    "saeb" = seq(2011L, current_year, by = 2L),
    "censo_superior" = 2009:current_year,
    "encceja" = 2014:current_year,
    "idd" = setdiff(2014:current_year, 2020L),
    NULL
  )
}

# discover available years via HEAD requests to INEP URLs
# only checks last 3 known years + new candidates (fast)
discover_inep_years <- function(dataset) {
  candidates <- candidate_year_range(dataset)
  if (is.null(candidates)) return(NULL)

  known <- fallback_years(dataset)
  max_known <- max(known)

  # only check: last 3 known years (re-verify) + new candidates beyond known
  to_check <- sort(unique(c(
    intersect(candidates, seq(max_known - 2L, max_known)),
    candidates[candidates > max_known]
  )))

  if (length(to_check) == 0) return(known)

  check_results <- vapply(to_check, function(year) {
    url <- tryCatch(
      build_inep_url(dataset, year),
      error = function(e) NA_character_
    )
    if (is.na(url)) return(FALSE)

    tryCatch(
      {
        req <- httr2::request(url) |>
          httr2::req_method("HEAD") |>
          httr2::req_timeout(seconds = 5) |>
          httr2::req_error(is_error = function(resp) FALSE)
        resp <- httr2::req_perform(req)
        httr2::resp_status(resp) < 400
      },
      error = function(e) FALSE
    )
  }, logical(1))

  confirmed <- to_check[check_results]
  not_confirmed <- to_check[!check_results]

  # known years (removing failed re-verifications) + newly confirmed
  sort(unique(c(setdiff(known, not_confirmed), confirmed)))
}

# discover available years for FUNDEB enrollment via OData API
# checks ALL candidate years (API data can change unpredictably)
discover_fundeb_enrollment_years <- function() {
  current_year <- as.integer(format(Sys.Date(), "%Y"))
  to_check <- 2007L:current_year

  base_url <- fundeb_enrollment_api_url()

  check_results <- vapply(to_check, function(year) {
    tryCatch(
      {
        req <- httr2::request(base_url) |>
          httr2::req_url_query(
            `$filter` = paste0("AnoCenso eq ", year),
            `$top` = 1,
            `$format` = "json"
          ) |>
          httr2::req_timeout(seconds = 10) |>
          httr2::req_error(is_error = function(resp) FALSE)
        resp <- httr2::req_perform(req)
        body <- httr2::resp_body_json(resp)
        length(body$value) > 0
      },
      error = function(e) FALSE
    )
  }, logical(1))

  sort(to_check[check_results])
}

# discover available years for ENADE (inconsistent URLs, needs map + pattern tries)
discover_enade_years <- function() {
  current_year <- as.integer(format(Sys.Date(), "%Y"))
  known_years <- sort(as.integer(names(enade_urls)))
  max_known <- max(known_years)

  # recheck last 3 known years + try new candidates
  to_recheck <- utils::tail(sort(known_years), 3)
  new_candidates <- setdiff((max_known + 1L):current_year, 2020L)
  all_to_check <- sort(unique(c(to_recheck, new_candidates)))

  base <- inep_base_url()

  check_results <- vapply(all_to_check, function(year) {
    # for years in the map, use the known URL
    # for new years, try multiple patterns
    if (as.character(year) %in% names(enade_urls)) {
      urls <- unname(enade_urls[as.character(year)])
    } else {
      urls <- c(
        str_c(base, "/microdados/microdados_enade_", year, ".zip"),
        str_c(base, "/microdados/microdados_enade_", year, "_LGPD.zip"),
        str_c(base, "/microdados/microdados_enade_", year, "_LGPD.rar")
      )
    }

    for (url in urls) {
      ok <- tryCatch(
        {
          req <- httr2::request(url) |>
            httr2::req_method("HEAD") |>
            httr2::req_timeout(seconds = 5) |>
            httr2::req_error(is_error = function(resp) FALSE)
          resp <- httr2::req_perform(req)
          httr2::resp_status(resp) < 400
        },
        error = function(e) FALSE
      )
      if (ok) return(TRUE)
    }
    FALSE
  }, logical(1))

  confirmed <- all_to_check[check_results]
  not_confirmed <- all_to_check[!check_results]

  sort(unique(c(setdiff(known_years, not_confirmed), confirmed)))
}

# main discovery dispatcher
discover_available_years <- function(dataset) {
  # datasets with HEAD-checkable INEP URLs (consistent patterns)
  head_check <- c("censo_escolar", "enem", "saeb", "censo_superior",
                   "encceja", "idd")

  if (dataset %in% head_check) {
    return(discover_inep_years(dataset))
  }

  # ENADE: inconsistent URLs, needs special handling
  if (dataset == "enade") {
    return(discover_enade_years())
  }

  # datasets with hardcoded URL maps (years = map keys)
  if (dataset == "cpc") return(sort(as.integer(names(cpc_urls))))
  if (dataset == "igc") return(sort(as.integer(names(igc_urls))))
  if (dataset == "fundeb") return(sort(as.integer(names(fundeb_recursos_ids))))

  # FUNDEB enrollment: query OData API
  if (dataset == "fundeb_enrollment") {
    return(discover_fundeb_enrollment_years())
  }

  # capes, ideb: discovery not practical, use fallback
  NULL
}

#' Check available years for a dataset
#'
#' @description
#' Returns the years available for a given dataset. On the first call in a
#' session, queries the data source to discover which years are actually
#' available (requires internet). Results are cached for the session.
#' Falls back to a known list if discovery fails.
#'
#' @param dataset The dataset name.
#'
#' @return An integer vector of available years.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' available_years("enem")
#' available_years("enade")
#' available_years("fundeb_enrollment")
#' }
available_years <- function(dataset) {
  dataset <- match.arg(
    dataset,
    choices = c("censo_escolar", "enem", "saeb", "censo_superior", "enade",
                "encceja", "idd", "cpc", "igc", "capes", "ideb",
                "fundeb", "fundeb_enrollment")
  )

  # check session cache

  cache_key <- paste0("available_years_", dataset)
  cached <- .educabr_env[[cache_key]]
  if (!is.null(cached)) return(cached)

  # skip discovery if disabled (e.g., during testing)
  skip_discovery <- identical(Sys.getenv("EDUCABR_SKIP_DISCOVERY"), "true")

  # try dynamic discovery
  years <- if (skip_discovery) NULL else tryCatch(
    discover_available_years(dataset),
    error = function(e) NULL
  )

  # fallback to hardcoded list if discovery fails
  if (is.null(years) || length(years) == 0) {
    years <- fallback_years(dataset)
  }

  # cache for the session
  .educabr_env[[cache_key]] <- years

  years
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

#' Detect file delimiter
#'
#' @description
#' Internal function to detect the delimiter used in a CSV file by reading
#' the first line and counting occurrences of common delimiters.
#'
#' @param file Path to the data file.
#'
#' @return The detected delimiter character.
#'
#' @keywords internal
detect_delim <- function(file) {
  first_line <- readLines(file, n = 1, warn = FALSE)

  counts <- c(
    ";" = str_count(first_line, ";"),
    "|" = str_count(first_line, "\\|"),
    "," = str_count(first_line, ","),
    "\t" = str_count(first_line, "\t")
  )

  names(which.max(counts))
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
  # read raw bytes from the first chunk of the file
  raw_bytes <- readBin(file, "raw", n = 10000)
  text <- rawToChar(raw_bytes)

  # iconv returns NA if input is not valid UTF-8
  result <- iconv(text, from = "UTF-8", to = "UTF-8")

  if (is.na(result)) {
    "latin1"
  } else {
    "UTF-8"
  }
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

  # read header to detect code columns (CO_*, CD_* should be character)
  header <- readr::read_delim(
    file,
    delim = delim,
    locale = readr::locale(encoding = encoding),
    show_col_types = FALSE,
    n_max = 0
  )

  col_names <- names(header)
  is_code <- grepl("^(CO_|CD_)", col_names, ignore.case = TRUE)

  col_spec <- NULL
  if (any(is_code)) {
    col_spec <- readr::cols(.default = readr::col_guess())
    for (name in col_names[is_code]) {
      col_spec$cols[[name]] <- readr::col_character()
    }
  }

  # read with readr
  readr::read_delim(
    file,
    delim = delim,
    locale = readr::locale(encoding = encoding),
    show_col_types = FALSE,
    n_max = n_max,
    col_types = col_spec,
    progress = TRUE
  )
}

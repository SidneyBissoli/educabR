# capes functions
# download and process CAPES graduate education data

# CKAN API base URL
capes_api_url <- function() {
  "https://dadosabertos.capes.gov.br/api/3/action"
}

# mapping of year ranges to CKAN dataset slug prefixes
# CAPES groups years into packages like "2021-a-2024-..."
capes_year_ranges <- list(
  list(years = 2021:2024, prefix = "2021-a-2024"),
  list(years = 2017:2020, prefix = "2017-a-2020"),
  list(years = 2013:2016, prefix = "2013-a-2016")
)

# mapping of data types to CKAN slug suffixes
capes_type_slugs <- c(
  "programas"  = "programas-da-pos-graduacao-stricto-sensu-no-brasil",
  "discentes"  = "discentes-da-pos-graduacao-stricto-sensu-do-brasil",
  "docentes"   = "docentes-da-pos-graduacao-stricto-sensu-no-brasil",
  "cursos"     = "cursos-da-pos-graduacao-stricto-sensu-no-brasil",
  "catalogo"   = "catalogo-de-teses-e-dissertacoes-brasil"
)

#' Get CAPES graduate education data
#'
#' @description
#' Downloads and processes data from CAPES (Coordenacao de Aperfeicoamento
#' de Pessoal de Nivel Superior) on Brazilian graduate programs (stricto sensu).
#' Data is retrieved from the CAPES Open Data Portal via the CKAN API.
#'
#' @param year The year of the data (2013-2024).
#' @param type The type of data to download. One of:
#'   - `"programas"`: Graduate programs
#'   - `"discentes"`: Students
#'   - `"docentes"`: Faculty
#'   - `"cursos"`: Courses
#'   - `"catalogo"`: Theses and dissertations catalog
#' @param n_max Maximum number of rows to read. Default is `Inf` (all rows).
#' @param keep_file Logical. If `TRUE`, keeps the downloaded file in cache.
#'   Default is `TRUE`.
#' @param quiet Logical. If `TRUE`, suppresses progress messages.
#'
#' @return A tibble with CAPES data in tidy format.
#'
#' @details
#' CAPES is the federal agency responsible for evaluating and regulating
#' graduate programs in Brazil. The data covers stricto sensu programs
#' (master's and doctoral).
#'
#' The data types include:
#'
#' - **programas**: Program identifiers, area, evaluation scores
#' - **discentes**: Student enrollment, demographics, scholarship status
#' - **docentes**: Faculty information, qualifications, employment
#' - **cursos**: Course details, modality, start dates
#' - **catalogo**: Catalog of theses and dissertations
#'
#' **Important notes:**
#'
#' - Data is sourced from the CAPES Open Data Portal (CKAN), not INEP.
#' - Files are large CSV files. Downloading may take several minutes.
#' - Column names are standardized to lowercase with underscores.
#' - Internet connection is required to discover download URLs via the
#'   CKAN API before downloading.
#'
#' @section Data source:
#' \url{https://dadosabertos.capes.gov.br}
#'
#' @family CAPES functions
#' @export
#'
#' @examples
#' \dontrun{
#' # get graduate programs for 2023
#' programas <- get_capes(2023, type = "programas")
#'
#' # get student data for 2022 with limited rows
#' discentes <- get_capes(2022, type = "discentes", n_max = 1000)
#' }
get_capes <- function(year,
                      type = c("programas", "discentes", "docentes",
                               "cursos", "catalogo"),
                      n_max = Inf,
                      keep_file = TRUE,
                      quiet = FALSE) {
  # validate arguments
  type <- match.arg(type)
  validate_year(year, "capes")

  # build cache filename
  filename <- str_c("capes_", type, "_", year, ".csv")
  file_path <- cache_path("capes", filename)

  # download if not cached
  if (!is_cached("capes", filename)) {
    if (!quiet) {
      cli::cli_alert_info("discovering download URL for CAPES {.val {type}} {.val {year}}...")
    }

    url <- discover_capes_url(year, type)

    if (!quiet) {
      cli::cli_alert_info("downloading CAPES {.val {type}} {.val {year}}...")
    }
    download_inep_file(url, file_path, quiet = quiet)
  } else if (!quiet) {
    cli::cli_alert_success("using cached file")
  }

  if (!quiet) {
    cli::cli_alert_info("reading CAPES data...")
  }

  # detect delimiter and read
  delim <- detect_delim(file_path)
  df <- read_inep_file(file_path, delim = delim, n_max = n_max)

  # standardize column names
  df <- standardize_names(df)

  # replace dash placeholders with NA
  df <- clean_dash_values(df)

  # parse SAS datetime columns (dt_*)
  df <- parse_sas_dates(df)

  # validate data structure
  validate_data(df, "capes", year)

  # clean up file if requested
  if (!keep_file && file.exists(file_path)) {
    unlink(file_path)
  }

  if (!quiet) {
    cli::cli_alert_success(
      "loaded {.val {nrow(df)}} rows and {.val {ncol(df)}} columns"
    )
  }

  df
}

#' Discover CAPES download URL via CKAN API
#'
#' @description
#' Internal function to discover the download URL for a specific CAPES
#' dataset and year using the CKAN API. CAPES URLs contain UUIDs and
#' cannot be predicted, so they must be discovered dynamically.
#'
#' @param year The year.
#' @param type The data type.
#'
#' @return A character string with the download URL.
#'
#' @keywords internal
discover_capes_url <- function(year, type) {
  # find the year range prefix
  range_prefix <- NULL
  for (range in capes_year_ranges) {
    if (year %in% range$years) {
      range_prefix <- range$prefix
      break
    }
  }

  if (is.null(range_prefix)) {
    cli::cli_abort(
      c(
        "could not determine CAPES dataset package for year {.val {year}}",
        "i" = "available years: {.val {available_years('capes')}}"
      )
    )
  }

  # build the CKAN package slug
  type_slug <- capes_type_slugs[[type]]
  package_slug <- str_c(range_prefix, "-", type_slug)

  # query CKAN API for package details
  api_url <- str_c(capes_api_url(), "/package_show?id=", package_slug)

  tryCatch(
    {
      req <- httr2::request(api_url) |>
        httr2::req_timeout(seconds = 300) |>
        httr2::req_retry(max_tries = 3, backoff = ~ 15)

      resp <- httr2::req_perform(req)
      body <- httr2::resp_body_json(resp)

      if (!body$success) {
        cli::cli_abort("CKAN API returned error for package {.val {package_slug}}")
      }

      # find the CSV resource for the requested year
      resources <- body$result$resources
      year_str <- as.character(year)

      for (res in resources) {
        is_csv <- tolower(res$format %||% "") == "csv"
        name_matches <- grepl(year_str, res$name %||% "", fixed = TRUE)

        if (is_csv && name_matches) {
          return(res$url)
        }
      }

      # fallback: try matching by URL filename
      for (res in resources) {
        is_csv <- tolower(res$format %||% "") == "csv"
        url_matches <- grepl(str_c("-", year_str, "-"), res$url %||% "")

        if (is_csv && url_matches) {
          return(res$url)
        }
      }

      cli::cli_abort(
        c(
          "no CSV resource found for CAPES {.val {type}} {.val {year}}",
          "i" = "package: {.val {package_slug}}",
          "i" = "try checking {.url https://dadosabertos.capes.gov.br/dataset/{package_slug}}"
        )
      )
    },
    error = function(e) {
      if (inherits(e, "rlang_error")) stop(e)

      cli::cli_abort(
        c(
          "failed to query CAPES API",
          "x" = "url: {.url {api_url}}",
          "i" = "error: {conditionMessage(e)}",
          "i" = "check your internet connection"
        )
      )
    }
  )
}

# censo escolar functions
# download and process school census data from INEP

#' Get School Census (Censo Escolar) data
#'
#' @description
#' Downloads and processes microdata from the Brazilian School Census
#' (Censo Escolar), conducted annually by INEP. Returns school-level data
#' with information about infrastructure, location, and administrative details.
#'
#' @param year The year of the census (2007-2024).
#' @param uf Optional. Filter by state (UF code or abbreviation).
#' @param n_max Maximum number of rows to read. Default is `Inf` (all rows).
#' @param keep_zip Logical. If `TRUE`, keeps the downloaded ZIP file in cache.
#' @param quiet Logical. If `TRUE`, suppresses progress messages.
#'
#' @return A tibble with school data in tidy format.
#'
#' @details
#' The School Census is the main statistical survey on basic education in
#' Brazil. It collects data from all public and private schools offering
#' basic education (early childhood, elementary, and high school).
#'
#' **Important notes:**
#'
#' - The microdata contains one row per school (~217,000 schools in 2023).
#' - Column names are standardized to lowercase with underscores.
#' - Use the `uf` parameter to filter by state for faster processing.
#'
#' @section Data dictionary:
#' For detailed information about variables, see INEP's documentation:
#' \url{https://www.gov.br/inep/pt-br/acesso-a-informacao/dados-abertos/microdados/censo-escolar}
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # get schools data for 2023
#' escolas <- get_censo_escolar(2023)
#'
#' # get schools from Sao Paulo state only
#' escolas_sp <- get_censo_escolar(2023, uf = "SP")
#'
#' # read only first 1000 rows for exploration
#' escolas_sample <- get_censo_escolar(2023, n_max = 1000)
#' }
get_censo_escolar <- function(year,
                              uf = NULL,
                              n_max = Inf,
                              keep_zip = TRUE,
                              quiet = FALSE) {
  # validate arguments
  validate_year(year, "censo_escolar")

  # build url and file paths
  url <- build_inep_url("censo_escolar", year)
  zip_filename <- str_c("microdados_censo_escolar_", year, ".zip")
  zip_path <- cache_path("censo_escolar", zip_filename)

  # download if not cached
  if (!is_cached("censo_escolar", zip_filename)) {
    if (!quiet) {
      cli::cli_alert_info(
        "downloading Censo Escolar {.val {year}}..."
      )
    }
    download_inep_file(url, zip_path, quiet = quiet)
  } else if (!quiet) {
    cli::cli_alert_success("using cached file")
  }

  # extract files
  exdir <- cache_path("censo_escolar", str_c("censo_", year))

  if (!dir.exists(exdir) || length(list.files(exdir, recursive = TRUE)) == 0) {
    extract_zip(zip_path, exdir, quiet = quiet)
  }

  # clean up zip if requested
  if (!keep_zip && file.exists(zip_path)) {
    unlink(zip_path)
  }

  # find the main data file (microdados_ed_basica_{year}.csv)
  data_file <- find_censo_file(exdir, year)

  if (!quiet) {
    cli::cli_alert_info("reading school data...")
  }

  # read the file
  df <- read_inep_file(data_file, delim = ";", n_max = n_max)

  # standardize column names
  df <- standardize_names(df)

  # filter by UF if requested
  if (!is.null(uf) && "co_uf" %in% names(df)) {
    uf_code <- uf_to_code(uf)
    df <- df |>
      dplyr::filter(.data$co_uf == uf_code)
  }

  if (!quiet) {
    cli::cli_alert_success(
      "loaded {.val {nrow(df)}} rows and {.val {ncol(df)}} columns"
    )
  }

  df
}

#' Find the Censo Escolar data file
#'
#' @description
#' Internal function to locate the main data file within the
#' extracted census directory.
#'
#' @param exdir The extraction directory.
#' @param year The year.
#'
#' @return The path to the data file.
#'
#' @keywords internal
find_censo_file <- function(exdir, year) {
  # look for the main microdados file
  # pattern: microdados_ed_basica_{year}.csv
  patterns <- c(
    str_c("microdados_ed_basica_", year),
    "microdados_ed_basica",
    "microdados"
  )

  for (pattern in patterns) {
    files <- list.files(
      exdir,
      pattern = str_c(pattern, ".*\\.(csv|CSV)$"),
      recursive = TRUE,
      full.names = TRUE,
      ignore.case = TRUE
    )

    if (length(files) > 0) {
      # prefer main data file (not suplemento)
      main_files <- files[!str_detect(str_to_lower(files), "suplemento")]
      if (length(main_files) > 0) {
        return(main_files[1])
      }
      return(files[1])
    }
  }

  cli::cli_abort(
    c(
      "no data file found",
      "i" = "directory: {.path {exdir}}"
    )
  )
}

#' Convert UF abbreviation to code
#'
#' @description
#' Internal function to convert state abbreviations to IBGE codes.
#'
#' @param uf UF abbreviation or code.
#'
#' @return The numeric UF code.
#'
#' @keywords internal
uf_to_code <- function(uf) {
  # if already numeric, return as is
  if (is.numeric(uf)) {
    return(uf)
  }

  # uf mapping
  uf_map <- c(
    "RO" = 11, "AC" = 12, "AM" = 13, "RR" = 14, "PA" = 15,
    "AP" = 16, "TO" = 17, "MA" = 21, "PI" = 22, "CE" = 23,
    "RN" = 24, "PB" = 25, "PE" = 26, "AL" = 27, "SE" = 28,
    "BA" = 29, "MG" = 31, "ES" = 32, "RJ" = 33, "SP" = 35,
    "PR" = 41, "SC" = 42, "RS" = 43, "MS" = 50, "MT" = 51,
    "GO" = 52, "DF" = 53
  )

  uf_upper <- toupper(uf)

  if (!uf_upper %in% names(uf_map)) {
    cli::cli_abort("invalid UF: {.val {uf}}")
  }

  unname(uf_map[uf_upper])
}

#' Standardize column names
#'
#' @description
#' Internal function to standardize column names to lowercase
#' with underscores.
#'
#' @param df A data frame.
#'
#' @return The data frame with standardized names.
#'
#' @keywords internal
standardize_names <- function(df) {
  names(df) <- names(df) |>
    str_to_lower() |>
    str_replace_all("[^a-z0-9]", "_") |>
    str_replace_all("_+", "_") |>
    str_remove("^_") |>
    str_remove("_$")

  df
}

#' List available Censo Escolar files
#'
#' @description
#' Lists the data files available in a downloaded School Census.
#'
#' @param year The year of the census.
#'
#' @return A character vector of file names found.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' list_censo_files(2023)
#' }
list_censo_files <- function(year) {
  validate_year(year, "censo_escolar")

  exdir <- cache_path("censo_escolar", str_c("censo_", year))

  if (!dir.exists(exdir)) {
    cli::cli_abort(
      c(
        "censo {.val {year}} not downloaded",
        "i" = "use {.fun get_censo_escolar} to download first"
      )
    )
  }

  files <- list.files(exdir, pattern = "\\.(csv|CSV)$", recursive = TRUE)

  basename(files)
}

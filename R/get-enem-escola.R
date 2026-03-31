# enem por escola functions
# download and process ENEM by School data from INEP

#' Get ENEM por Escola (ENEM by School) data
#'
#' @description
#' Downloads and processes ENEM results aggregated by school.
#' This dataset contains average ENEM scores, participation rates,
#' and other indicators for each school in Brazil.
#'
#' @param n_max Maximum number of rows to read. Default is `Inf` (all rows).
#' @param keep_zip Logical. If `TRUE`, keeps the downloaded ZIP file in cache.
#' @param quiet Logical. If `TRUE`, suppresses progress messages.
#'
#' @return A tibble with ENEM by School data in tidy format.
#'
#' @details
#' ENEM por Escola is a single bundled dataset covering years 2005 to 2015.
#' It was discontinued by INEP after 2015 and no per-year files exist.
#'
#' The data includes:
#'
#' - School identification (code, name, municipality, state)
#' - Average ENEM scores by knowledge area
#' - Number of participants and participation rates
#' - School-level indicators
#'
#' **Important notes:**
#'
#' - This is a single file covering all years (2005-2015), not per-year.
#' - Column names are standardized to lowercase with underscores.
#' - Data was discontinued after 2015.
#'
#' @section Data dictionary:
#' For detailed information about variables, see INEP's documentation:
#' \url{https://www.gov.br/inep/pt-br/acesso-a-informacao/dados-abertos/microdados/enem-por-escola}
#'
#' @family ENEM functions
#' @export
#'
#' @examples
#' \dontrun{
#' # get all ENEM by School data (2005-2015)
#' enem_escola <- get_enem_escola()
#'
#' # read only first 1000 rows for exploration
#' enem_escola_sample <- get_enem_escola(n_max = 1000)
#' }
get_enem_escola <- function(n_max = Inf,
                            keep_zip = TRUE,
                            quiet = FALSE) {
  # build url and file paths
  url <- build_inep_url("enem_escola", year = NULL)
  zip_filename <- "microdados_enem_por_escola.zip"
  zip_path <- cache_path("enem_escola", zip_filename)

  # download if not cached
  if (!is_cached("enem_escola", zip_filename)) {
    if (!quiet) {
      cli::cli_alert_info("downloading ENEM por Escola (2005-2015)...")
    }
    download_inep_file(url, zip_path, quiet = quiet)
  } else if (!quiet) {
    cli::cli_alert_success("using cached file")
  }

  # extract files
  exdir <- cache_path("enem_escola", "microdados_enem_por_escola")

  if (!dir.exists(exdir) || length(list.files(exdir, recursive = TRUE)) == 0) {
    extract_zip(zip_path, exdir, quiet = quiet)
  }

  # clean up zip if requested
  if (!keep_zip && file.exists(zip_path)) {
    unlink(zip_path)
  }

  # find the data file
  data_file <- find_enem_escola_file(exdir)

  if (!quiet) {
    cli::cli_alert_info("reading ENEM por Escola data...")
  }

  # detect delimiter
  delim <- detect_delim(data_file)

  # read the file
  df <- read_inep_file(data_file, delim = delim, n_max = n_max)

  # standardize column names
  df <- standardize_names(df)

  # replace dash placeholders with NA
  df <- clean_dash_values(df)

  # validate data structure
  validate_data(df, "enem_escola", year = NULL)

  if (!quiet) {
    cli::cli_alert_success(
      "loaded {.val {nrow(df)}} rows and {.val {ncol(df)}} columns"
    )
  }

  df
}

#' Find the ENEM por Escola data file
#'
#' @description
#' Internal function to locate the ENEM por Escola data file within
#' the extracted directory.
#'
#' @param exdir The extraction directory.
#'
#' @return The path to the data file.
#'
#' @keywords internal
find_enem_escola_file <- function(exdir) {
  patterns <- c(
    "microdados_enem_por_escola",
    "enem_por_escola",
    "microdados"
  )

  for (pattern in patterns) {
    files <- list.files(
      exdir,
      pattern = str_c(pattern, ".*\\.(csv|CSV|txt|TXT)$"),
      recursive = TRUE,
      full.names = TRUE,
      ignore.case = TRUE
    )

    if (length(files) > 0) {
      return(files[1])
    }
  }

  cli::cli_abort(
    c(
      "no ENEM por Escola data file found",
      "i" = "directory: {.path {exdir}}"
    )
  )
}

# idd functions
# download and process IDD data from INEP

#' Get IDD (Indicador de Diferença entre os Desempenhos Observado e Esperado) data
#'
#' @description
#' Downloads and processes microdata from IDD, an indicator that measures
#' the value added by an undergraduate course to student performance. It
#' compares ENADE scores with expected performance based on students'
#' prior achievement (ENEM scores at admission).
#'
#' @param year The year of the indicator (2014-2019, 2021-2023).
#'   Note: there is no 2020 edition.
#' @param n_max Maximum number of rows to read. Default is `Inf` (all rows).
#' @param keep_zip Logical. If `TRUE`, keeps the downloaded ZIP file in cache.
#' @param quiet Logical. If `TRUE`, suppresses progress messages.
#'
#' @return A tibble with IDD data in tidy format.
#'
#' @details
#' IDD is calculated by INEP as part of the higher education quality
#' assessment system. It complements ENADE by isolating the contribution
#' of the course itself to student learning, controlling for student
#' input quality.
#'
#' The data includes:
#'
#' - Course and institution identifiers
#' - IDD scores (continuous and categorical)
#' - Number of students considered in the calculation
#' - Related ENADE and ENEM metrics
#'
#' **Important notes:**
#'
#' - IDD is published alongside ENADE results, following the same
#'   rotating cycle of course areas.
#' - Column names are standardized to lowercase with underscores.
#' - Not all courses have IDD values (minimum sample requirements apply).
#'
#' @section Data dictionary:
#' For detailed information about variables, see INEP's documentation:
#' \url{https://www.gov.br/inep/pt-br/acesso-a-informacao/dados-abertos/microdados/idd}
#'
#' @family IDD functions
#' @export
#'
#' @examples
#' \dontrun{
#' # get IDD data for 2023
#' idd <- get_idd(2023)
#'
#' # get IDD data for 2021 with limited rows
#' idd_2021 <- get_idd(2021, n_max = 1000)
#' }
get_idd <- function(year,
                    n_max = Inf,
                    keep_zip = TRUE,
                    quiet = FALSE) {
  # validate arguments
  validate_year(year, "idd")

  # build url and file paths
  url <- build_inep_url("idd", year)
  ext <- if (year >= 2021) ".zip" else ".7z"
  archive_filename <- str_c("microdados_IDD_", year, ext)
  archive_path <- cache_path("idd", archive_filename)

  # download if not cached
  if (!is_cached("idd", archive_filename)) {
    if (!quiet) {
      cli::cli_alert_info("downloading IDD {.val {year}}...")
    }
    download_inep_file(url, archive_path, quiet = quiet)
  } else if (!quiet) {
    cli::cli_alert_success("using cached file")
  }

  # extract files
  exdir_name <- gsub("\\.(zip|7z)$", "", archive_filename)
  exdir <- cache_path("idd", exdir_name)

  if (!dir.exists(exdir) || length(list.files(exdir, recursive = TRUE)) == 0) {
    extract_archive(archive_path, exdir, quiet = quiet)
  }

  # clean up archive if requested
  if (!keep_zip && file.exists(archive_path)) {
    unlink(archive_path)
  }

  # find the data file
  data_file <- find_idd_file(exdir, year)

  if (!quiet) {
    cli::cli_alert_info("reading IDD data...")
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
  validate_data(df, "idd", year)

  if (!quiet) {
    cli::cli_alert_success(
      "loaded {.val {nrow(df)}} rows and {.val {ncol(df)}} columns"
    )
  }

  df
}

#' Find the IDD data file
#'
#' @description
#' Internal function to locate the IDD data file within the extracted
#' directory.
#'
#' @param exdir The extraction directory.
#' @param year The year.
#'
#' @return The path to the data file.
#'
#' @keywords internal
find_idd_file <- function(exdir, year) {
  patterns <- c(
    str_c("microdados_idd_", year),
    str_c("idd_", year),
    "microdados_idd",
    "idd"
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
      "no IDD data file found for {.val {year}}",
      "i" = "directory: {.path {exdir}}"
    )
  )
}

# enade functions
# download and process ENADE data from INEP

# hardcoded URL map — INEP uses inconsistent naming for ENADE files
enade_urls <- c(
  "2004" = "https://download.inep.gov.br/microdados/microdados_enade_2004.zip",
  "2005" = "https://download.inep.gov.br/microdados/microdados_enade_2005.zip",
  "2006" = "https://download.inep.gov.br/microdados/microdados_enade_2006.zip",
  "2007" = "https://download.inep.gov.br/microdados/microdados_enade_2007.zip",
  "2008" = "https://download.inep.gov.br/microdados/microdados_enade_2008.zip",
  "2009" = "https://download.inep.gov.br/microdados/microdados_enade_2009.zip",
  "2010" = "https://download.inep.gov.br/microdados/microdados_enade_2010.zip",
  "2011" = "https://download.inep.gov.br/microdados/microdados_enade_2011.zip",
  "2012" = "https://download.inep.gov.br/microdados/microdados_enade_2012_LGPD.zip",
  "2013" = "https://download.inep.gov.br/microdados/microdados_enade_2013_LGPD.zip",
  "2014" = "https://download.inep.gov.br/microdados/microdados_enade_2014_LGPD.zip",
  "2015" = "https://download.inep.gov.br/microdados/microdados_enade_2015_LGPD.zip",
  "2016" = "https://download.inep.gov.br/microdados/microdados_enade_2016_LGPD.zip",
  "2017" = "https://download.inep.gov.br/microdados/microdados_enade_2017_LGPD.zip",
  "2018" = "https://download.inep.gov.br/microdados/microdados_enade_2018_LGPD.zip",
  "2019" = "https://download.inep.gov.br/microdados/microdados_enade_2019_LGPD.zip",
  "2021" = "https://download.inep.gov.br/microdados/microdados_enade_2021.zip",
  "2022" = "https://download.inep.gov.br/microdados/microdados_enade_2022_LGPD.rar",
  "2023" = "https://download.inep.gov.br/microdados/microdados_enade_2023.zip"
)

#' Get ENADE (Exame Nacional de Desempenho dos Estudantes) data
#'
#' @description
#' Downloads and processes microdata from ENADE, the Brazilian National
#' Student Performance Exam. ENADE evaluates the performance of
#' undergraduate students in higher education.
#'
#' @param year The year of the exam (2004-2024).
#' @param n_max Maximum number of rows to read. Default is `Inf` (all rows).
#'   Consider using a smaller value for exploration.
#' @param keep_zip Logical. If `TRUE`, keeps the downloaded ZIP file in cache.
#' @param quiet Logical. If `TRUE`, suppresses progress messages.
#'
#' @return A tibble with ENADE microdata in tidy format.
#'
#' @details
#' ENADE is conducted annually by INEP and evaluates undergraduate students
#' nearing the end of their programs. Each year, a different set of course
#' areas is assessed on a rotating cycle (typically every 3 years per area).
#'
#' The microdata includes:
#'
#' - Student performance scores (general and specific knowledge)
#' - Socioeconomic questionnaire responses
#' - Course and institution identifiers
#'
#' **Important notes:**
#'
#' - ENADE files can be large (several hundred MB for recent years).
#' - Use `n_max` to read a sample first for exploration.
#' - Column names are standardized to lowercase with underscores.
#' - Not all course areas are assessed every year due to the rotating cycle.
#'
#' @section Data dictionary:
#' For detailed information about variables, see INEP's documentation:
#' \url{https://www.gov.br/inep/pt-br/acesso-a-informacao/dados-abertos/microdados/enade}
#'
#' @family ENADE functions
#' @export
#'
#' @examples
#' \dontrun{
#' # get ENADE data for 2023
#' enade <- get_enade(2023, n_max = 10000)
#'
#' # get full dataset for 2021
#' enade_2021 <- get_enade(2021)
#' }
get_enade <- function(year,
                      n_max = Inf,
                      keep_zip = TRUE,
                      quiet = FALSE) {
  # validate arguments
  validate_year(year, "enade")

  # get url from map (or build for unknown years)
  url <- enade_urls[as.character(year)]
  if (is.na(url)) {
    url <- build_inep_url("enade", year)
  }
  url <- unname(url)

  # file paths — use actual filename from URL
  archive_filename <- basename(url)
  archive_path <- cache_path("enade", archive_filename)

  # download if not cached
  if (!is_cached("enade", archive_filename)) {
    if (!quiet) {
      cli::cli_alert_info("downloading ENADE {.val {year}}...")
    }
    download_inep_file(url, archive_path, quiet = quiet)
  } else if (!quiet) {
    cli::cli_alert_success("using cached file")
  }

  # extract files
  exdir_name <- tools::file_path_sans_ext(archive_filename)
  exdir <- cache_path("enade", exdir_name)

  if (!dir.exists(exdir) || length(list.files(exdir, recursive = TRUE)) == 0) {
    extract_archive(archive_path, exdir, quiet = quiet)
  }

  # clean up archive if requested
  if (!keep_zip && file.exists(archive_path)) {
    unlink(archive_path)
  }

  # find the data file
  data_file <- find_enade_file(exdir, year)

  if (!quiet) {
    cli::cli_alert_info("reading ENADE data...")
    if (is.infinite(n_max)) {
      cli::cli_alert_warning(
        "reading full file. use {.arg n_max} to limit rows if needed."
      )
    }
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
  validate_data(df, "enade", year)

  if (!quiet) {
    cli::cli_alert_success(
      "loaded {.val {nrow(df)}} rows and {.val {ncol(df)}} columns"
    )
  }

  df
}

#' Find the ENADE data file
#'
#' @description
#' Internal function to locate the ENADE data file within the extracted
#' directory.
#'
#' @param exdir The extraction directory.
#' @param year The year.
#'
#' @return The path to the data file.
#'
#' @keywords internal
find_enade_file <- function(exdir, year) {
  patterns <- c(
    str_c("microdados_enade_", year),
    str_c("microdados", year),
    "microdados_enade",
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
      "no ENADE data file found for {.val {year}}",
      "i" = "directory: {.path {exdir}}"
    )
  )
}

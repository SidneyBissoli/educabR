# enem functions
# download and process ENEM data from INEP

#' Get ENEM (Exame Nacional do Ensino Médio) data
#'
#' @description
#' Downloads and processes microdata from ENEM, the Brazilian National
#' High School Exam. ENEM is used for university admissions and as a
#' high school equivalency exam.
#'
#' @param year The year of the exam (2009-2023).
#' @param n_max Maximum number of rows to read. Default is `Inf` (all rows).
#'   Consider using a smaller value for exploration, as ENEM files
#'   contain millions of rows.
#' @param keep_zip Logical. If `TRUE`, keeps the downloaded ZIP file in cache.
#' @param quiet Logical. If `TRUE`, suppresses progress messages.
#'
#' @return A tibble with the ENEM microdata in tidy format.
#'
#' @details
#' ENEM is conducted annually by INEP and is the largest exam in Brazil,
#' with millions of participants. The microdata includes:
#'
#' - Participant demographics (age, sex, race, etc.)
#' - Socioeconomic questionnaire responses
#' - Scores for each test area
#' - Essay scores
#' - School information (when applicable)
#'
#' **Important notes:**
#'
#' - ENEM files are very large (several GB when extracted).
#' - Use `n_max` to read a sample first for exploration.
#' - Column names are standardized to lowercase with underscores.
#' - Score variables start with `nu_nota_` prefix.
#'
#' @section Data dictionary:
#' For detailed information about variables, see INEP's documentation:
#' \url{https://www.gov.br/inep/pt-br/acesso-a-informacao/dados-abertos/microdados/enem}
#'
#' @export
#'
#' @examples
#' \donttest{
#' # get a sample of 10000 rows for exploration
#' enem_sample <- get_enem(2023, n_max = 10000)
#'
#' # get full data (warning: large file)
#' enem_2023 <- get_enem(2023)
#' }
get_enem <- function(year,
                     n_max = Inf,
                     keep_zip = TRUE,
                     quiet = FALSE) {
  # validate arguments
  validate_year(year, "enem")

  # build url and file paths
  url <- build_inep_url("enem", year)
  zip_filename <- str_c("microdados_enem_", year, ".zip")
  zip_path <- cache_path("enem", zip_filename)

  # download if not cached
  if (!is_cached("enem", zip_filename)) {
    if (!quiet) {
      cli::cli_alert_info("downloading ENEM {.val {year}}...")
      cli::cli_alert_warning(
        "ENEM files are large (1-3 GB). this may take a while..."
      )
    }
    download_inep_file(url, zip_path, quiet = quiet)
  } else if (!quiet) {
    cli::cli_alert_success("using cached file")
  }

  # extract files
  exdir <- cache_path("enem", str_c("enem_", year))

  if (!dir.exists(exdir) || length(list.files(exdir, recursive = TRUE)) == 0) {
    extract_zip(zip_path, exdir, quiet = quiet)
  }

  # clean up zip if requested
  if (!keep_zip && file.exists(zip_path)) {
    unlink(zip_path)
  }

  # find the main data file
  data_file <- find_enem_file(exdir, year)

  if (!quiet) {
    cli::cli_alert_info("reading ENEM data...")
    if (is.infinite(n_max)) {
      cli::cli_alert_warning(
        "reading full file. use {.arg n_max} to limit rows if needed."
      )
    }
  }

  # read the file
  df <- read_inep_file(data_file, delim = ";", n_max = n_max)

  # standardize column names
  df <- standardize_names(df)

  if (!quiet) {
    cli::cli_alert_success(
      "loaded {.val {nrow(df)}} rows and {.val {ncol(df)}} columns"
    )
  }

  df
}

#' Find the ENEM data file
#'
#' @description
#' Internal function to locate the main ENEM data file within the
#' extracted directory.
#'
#' @param exdir The extraction directory.
#' @param year The year.
#'
#' @return The path to the data file.
#'
#' @keywords internal
find_enem_file <- function(exdir, year) {
  # look for the main microdados file
  patterns <- c(
    str_c("MICRODADOS_ENEM_", year),
    "MICRODADOS_ENEM",
    "DADOS"
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
      # prefer files without "ITENS" (item response data)
      main_files <- files[!str_detect(str_to_upper(files), "ITENS")]
      if (length(main_files) > 0) {
        return(main_files[1])
      }
      return(files[1])
    }
  }

  cli::cli_abort(
    c(
      "no ENEM data file found",
      "i" = "directory: {.path {exdir}}"
    )
  )
}

#' Get ENEM item response data
#'
#' @description
#' Downloads and processes ENEM item response (gabarito) data,
#' which contains detailed information about each question.
#'
#' @param year The year of the exam (2009-2023).
#' @param n_max Maximum number of rows to read.
#' @param quiet Logical. If `TRUE`, suppresses progress messages.
#'
#' @return A tibble with item response data.
#'
#' @export
#'
#' @examples
#' \donttest{
#' # get item data for 2023
#' itens <- get_enem_itens(2023)
#' }
get_enem_itens <- function(year, n_max = Inf, quiet = FALSE) {
  # validate arguments
  validate_year(year, "enem")

  # first ensure main file is downloaded
  zip_filename <- str_c("microdados_enem_", year, ".zip")

  if (!is_cached("enem", zip_filename)) {
    if (!quiet) {
      cli::cli_alert_info("downloading ENEM {.val {year}}...")
    }
    url <- build_inep_url("enem", year)
    zip_path <- cache_path("enem", zip_filename)
    download_inep_file(url, zip_path, quiet = quiet)
  }

  # extract if needed
  exdir <- cache_path("enem", str_c("enem_", year))

  if (!dir.exists(exdir)) {
    zip_path <- cache_path("enem", zip_filename)
    extract_zip(zip_path, exdir, quiet = quiet)
  }

  # find item file
  files <- list.files(
    exdir,
    pattern = "ITENS.*\\.(csv|CSV)$",
    recursive = TRUE,
    full.names = TRUE,
    ignore.case = TRUE
  )

  if (length(files) == 0) {
    cli::cli_abort(
      c(
        "no item response file found for ENEM {.val {year}}",
        "i" = "item data may not be available for this year"
      )
    )
  }

  if (!quiet) {
    cli::cli_alert_info("reading ENEM item data...")
  }

  # read the file
  df <- read_inep_file(files[1], delim = ";", n_max = n_max)

  # standardize column names
  df <- standardize_names(df)

  if (!quiet) {
    cli::cli_alert_success(
      "loaded {.val {nrow(df)}} rows and {.val {ncol(df)}} columns"
    )
  }

  df
}

#' Summary statistics for ENEM scores
#'
#' @description
#' Calculates summary statistics for ENEM scores, optionally grouped
#' by demographic variables.
#'
#' @param data A tibble with ENEM data (from [get_enem()]).
#' @param by Optional grouping variable(s) as character vector.
#'
#' @return A tibble with summary statistics for each score area.
#'
#' @export
#'
#' @examples
#' \donttest{
#' enem <- get_enem(2023, n_max = 10000)
#'
#' # overall summary
#' enem_summary(enem)
#'
#' # summary by sex
#' enem_summary(enem, by = "tp_sexo")
#' }
enem_summary <- function(data, by = NULL) {
  # identify score columns
  score_cols <- names(data)[str_detect(names(data), "^nu_nota_")]

  if (length(score_cols) == 0) {
    cli::cli_abort("no score columns found (expected columns starting with 'nu_nota_')")
  }

  # group if requested
  if (!is.null(by)) {
    data <- data |>
      dplyr::group_by(dplyr::across(dplyr::all_of(by)))
  }

  # calculate summary for each score column
  summary_list <- purrr::map(score_cols, function(col) {
    data |>
      dplyr::summarise(
        variable = col,
        n = dplyr::n(),
        n_valid = sum(!is.na(.data[[col]])),
        mean = mean(.data[[col]], na.rm = TRUE),
        sd = sd(.data[[col]], na.rm = TRUE),
        min = min(.data[[col]], na.rm = TRUE),
        q25 = quantile(.data[[col]], 0.25, na.rm = TRUE),
        median = median(.data[[col]], na.rm = TRUE),
        q75 = quantile(.data[[col]], 0.75, na.rm = TRUE),
        max = max(.data[[col]], na.rm = TRUE),
        .groups = "drop"
      )
  })

  dplyr::bind_rows(summary_list)
}

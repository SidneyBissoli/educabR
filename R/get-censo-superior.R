# censo da educacao superior functions
# download and process higher education census data from INEP

#' Get Higher Education Census (Censo da Educação Superior) data
#'
#' @description
#' Downloads and processes microdata from the Brazilian Higher Education
#' Census (Censo da Educação Superior), conducted annually by INEP.
#' Returns data on institutions, courses, students, or faculty.
#'
#' @param year The year of the census (2009-2024).
#' @param type Type of data to load. Options:
#'   - `"ies"`: Higher education institutions (default)
#'   - `"cursos"`: Undergraduate courses
#'   - `"alunos"`: Student enrollment
#'   - `"docentes"`: Faculty/professors
#' @param uf Optional. Filter by state (UF code or abbreviation).
#' @param n_max Maximum number of rows to read. Default is `Inf` (all rows).
#'   Consider using a smaller value for exploration.
#' @param keep_zip Logical. If `TRUE`, keeps the downloaded ZIP file in cache.
#' @param quiet Logical. If `TRUE`, suppresses progress messages.
#'
#' @return A tibble with Higher Education Census microdata in tidy format.
#'
#' @details
#' The Higher Education Census is the most comprehensive statistical survey
#' on higher education institutions (HEIs) in Brazil. It collects data from
#' all HEIs offering undergraduate and graduate programs.
#'
#' **Data types:**
#'
#' - `"ies"`: One row per institution — administrative data, location,
#'   academic organization, funding type.
#' - `"cursos"`: One row per undergraduate course — area of study, modality
#'   (in-person/distance), enrollment counts.
#' - `"alunos"`: One row per student enrollment — demographics, program,
#'   admission type, enrollment status.
#' - `"docentes"`: One row per faculty member — education level, employment
#'   type, teaching regime.
#'
#' **Important notes:**
#'
#' - Student files (`"alunos"`) can be very large (several GB).
#'   Use `n_max` to read a sample first.
#' - Column names are standardized to lowercase with underscores.
#' - Use the `uf` parameter to filter by state for faster processing.
#'
#' @section Data dictionary:
#' For detailed information about variables, see INEP's documentation:
#' \url{https://www.gov.br/inep/pt-br/acesso-a-informacao/dados-abertos/microdados/censo-da-educacao-superior}
#'
#' @family Higher Education Census functions
#' @export
#'
#' @examples
#' \dontrun{
#' # get institution data for 2023
#' ies <- get_censo_superior(2023)
#'
#' # get course data for Sao Paulo
#' cursos_sp <- get_censo_superior(2023, type = "cursos", uf = "SP")
#'
#' # get a sample of student data
#' alunos <- get_censo_superior(2023, type = "alunos", n_max = 10000)
#'
#' # get faculty data
#' docentes <- get_censo_superior(2023, type = "docentes")
#' }
get_censo_superior <- function(year,
                               type = c("ies", "cursos", "alunos", "docentes"),
                               uf = NULL,
                               n_max = Inf,
                               keep_zip = TRUE,
                               quiet = FALSE) {
  # validate arguments
  validate_year(year, "censo_superior")
  type <- match.arg(type)

  # build url and file paths
  url <- build_inep_url("censo_superior", year)
  zip_filename <- str_c("microdados_censo_da_educacao_superior_", year, ".zip")
  zip_path <- cache_path("censo_superior", zip_filename)

  # download if not cached
  if (!is_cached("censo_superior", zip_filename)) {
    if (!quiet) {
      cli::cli_alert_info(
        "downloading Censo da Educa\u00e7\u00e3o Superior {.val {year}}..."
      )
    }
    download_inep_file(url, zip_path, quiet = quiet)
  } else if (!quiet) {
    cli::cli_alert_success("using cached file")
  }

  # extract files
  exdir_name <- gsub("\\.zip$", "", zip_filename)
  exdir <- cache_path("censo_superior", exdir_name)

  if (!dir.exists(exdir) || length(list.files(exdir, recursive = TRUE)) == 0) {
    extract_zip(zip_path, exdir, quiet = quiet)
  }

  # clean up zip if requested
  if (!keep_zip && file.exists(zip_path)) {
    unlink(zip_path)
  }

  # find the data file
  data_file <- find_censo_superior_file(exdir, year, type)

  if (!quiet) {
    cli::cli_alert_info("reading Higher Education Census data ({.val {type}})...")
    if (is.infinite(n_max) && type == "alunos") {
      cli::cli_alert_warning(
        "student files can be very large. use {.arg n_max} to limit rows if needed."
      )
    }
  }

  # detect delimiter
  delim <- detect_delim(data_file)

  # read the file
  df <- read_inep_file(data_file, delim = delim, n_max = n_max)

  # standardize column names
  df <- standardize_names(df)

  # replace dash placeholders with NA in character columns
  df <- clean_dash_values(df)

  # validate data structure
  validate_data(df, "censo_superior", year)

  # filter by UF if requested
  if (!is.null(uf) && "co_uf_ies" %in% names(df)) {
    uf_code <- as.character(uf_to_code(uf))
    df <- df |>
      dplyr::filter(.data$co_uf_ies == uf_code)
  }

  if (!quiet) {
    cli::cli_alert_success(
      "loaded {.val {nrow(df)}} rows and {.val {ncol(df)}} columns"
    )
  }

  df
}

#' Clean dash placeholder values
#'
#' @description
#' Internal function to replace dash placeholders (`"-"`, `"\u2013"`) with
#' `NA` in all character columns. Common in INEP datasets where missing
#' values are encoded as dashes.
#'
#' @param df A data frame.
#'
#' @return The data frame with dashes replaced by `NA`.
#'
#' @keywords internal
clean_dash_values <- function(df) {
  dash_values <- c("-", "\u2013", "\u2014")

  for (col in names(df)) {
    if (is.character(df[[col]])) {
      df[[col]][trimws(df[[col]]) %in% dash_values] <- NA_character_
    }
  }

  df
}

#' Find the Higher Education Census data file
#'
#' @description
#' Internal function to locate a Higher Education Census data file within
#' the extracted directory based on the requested type.
#'
#' @param exdir The extraction directory.
#' @param year The year.
#' @param type The data type ("ies", "cursos", "alunos", "docentes").
#'
#' @return The path to the data file.
#'
#' @keywords internal
find_censo_superior_file <- function(exdir, year, type = "ies") {
  # map type to file patterns
  # INEP file naming varies across years; try multiple patterns
  type_patterns <- switch(
    type,
    "ies" = c(
      str_c("MICRODADOS_CADASTRO_IES_", year),
      str_c("DM_IES_", year),
      "MICRODADOS_CADASTRO_IES",
      "DM_IES",
      "IES"
    ),
    "cursos" = c(
      str_c("MICRODADOS_CADASTRO_CURSO_", year),
      str_c("DM_CURSO_", year),
      "MICRODADOS_CADASTRO_CURSO",
      "DM_CURSO",
      "CURSO"
    ),
    "alunos" = c(
      str_c("MICRODADOS_CADASTRO_ALUNO_", year),
      str_c("DM_ALUNO_", year),
      "MICRODADOS_CADASTRO_ALUNO",
      "DM_ALUNO",
      "ALUNO"
    ),
    "docentes" = c(
      str_c("MICRODADOS_CADASTRO_DOCENTE_", year),
      str_c("DM_DOCENTE_", year),
      "MICRODADOS_CADASTRO_DOCENTE",
      "DM_DOCENTE",
      "DOCENTE"
    )
  )

  for (pattern in type_patterns) {
    files <- list.files(
      exdir,
      pattern = str_c(pattern, ".*\\.(csv|CSV)$"),
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
      "no Higher Education Census {.val {type}} data file found for {.val {year}}",
      "i" = "directory: {.path {exdir}}",
      "i" = "use {.fun list_censo_superior_files} to see available files"
    )
  )
}

#' List available Higher Education Census files
#'
#' @description
#' Lists the data files available in a downloaded Higher Education Census.
#' Useful for exploring the contents of the ZIP file.
#'
#' @param year The year of the census.
#'
#' @return A character vector of file names found.
#'
#' @family Higher Education Census functions
#' @export
#'
#' @examples
#' \dontrun{
#' list_censo_superior_files(2023)
#' }
list_censo_superior_files <- function(year) {
  validate_year(year, "censo_superior")

  zip_filename <- str_c("microdados_censo_da_educacao_superior_", year, ".zip")
  exdir_name <- gsub("\\.zip$", "", zip_filename)
  exdir <- cache_path("censo_superior", exdir_name)

  if (!dir.exists(exdir)) {
    cli::cli_abort(
      c(
        "Higher Education Census {.val {year}} not downloaded",
        "i" = "use {.fun get_censo_superior} to download first"
      )
    )
  }

  files <- list.files(exdir, pattern = "\\.(csv|CSV)$", recursive = TRUE)

  basename(files)
}

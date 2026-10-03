# saeb functions
# download and process SAEB data from INEP

#' Get SAEB (Sistema de Avaliação da Educação Básica) data
#'
#' @description
#' Downloads and processes microdata from SAEB, the Brazilian Basic Education
#' Assessment System. SAEB evaluates educational quality through student
#' performance assessments in Portuguese and Mathematics.
#'
#' @param year The year of the assessment (2011, 2013, 2015, 2017, 2019,
#'   2021, 2023).
#' @param type Type of data to load. Options:
#'   - `"aluno"`: Student results (default)
#'   - `"escola"`: School questionnaire
#'   - `"diretor"`: Principal questionnaire
#'   - `"professor"`: Teacher questionnaire
#' @param level For 2021 only, SAEB was split into two files:
#'   - `"fundamental_medio"`: Elementary and High School (default)
#'   - `"educacao_infantil"`: Early Childhood Education
#'   Ignored for other years.
#' @param serie For `type = "aluno"`, the grade to load. Since 2013 INEP
#'   publishes one student file per grade (`TS_ALUNO_<serie>.csv`), so
#'   `get_saeb()` reads one grade per call. Use INEP's codes, in any case:
#'   - `"2ef"`: 2nd grade of elementary school (2019, 2021, 2023)
#'   - `"5ef"`: 5th grade of elementary school (2013-2023)
#'   - `"9ef"`: 9th grade of elementary school (2013-2023)
#'   - `"3em"`: 3rd grade of high school (2013, 2015)
#'   - `"3em_ag"`, `"3em_esc"`: 3rd grade of high school, aggregated and
#'     school samples (2017)
#'   - `"34em"`: 3rd and 4th grades of high school (2019, 2021, 2023)
#'
#'   The numbers `2`, `5` and `9` are accepted as shortcuts for `"2ef"`,
#'   `"5ef"` and `"9ef"`. Required when the edition has more than one
#'   student file; the error message lists the grades available for the
#'   year. Ignored for 2011 (a single results file covers all grades) and
#'   for the 2021 early childhood file.
#' @param n_max Maximum number of rows to read. Default is `Inf` (all rows).
#'   Consider using a smaller value for exploration.
#' @param keep_zip Logical. If `TRUE`, keeps the downloaded ZIP file in cache.
#' @param quiet Logical. If `TRUE`, suppresses progress messages.
#'
#' @return A tibble with SAEB microdata in tidy format.
#'
#' @details
#' SAEB is conducted biennially by INEP and assesses students in grades 5
#' and 9 of elementary school, and grade 3 of high school. The data includes:
#'
#' - Student performance scores in Portuguese and Mathematics
#' - School infrastructure and management questionnaires
#' - Teacher and principal profiles
#'
#' **Important notes:**
#'
#' - SAEB files can be large (several hundred MB).
#' - Use `n_max` to read a sample first for exploration.
#' - Column names are standardized to lowercase with underscores.
#' - In 2021, INEP split SAEB into two separate downloads (elementary/high
#'   school and early childhood). Use the `level` parameter to choose.
#' - Student files are split by grade from 2013 on; choose one with
#'   `serie`. The 5th and 9th grade files are about 1 GB of CSV each. To
#'   combine grades, call once per grade, e.g.
#'   `purrr::map(c("5ef", "9ef"), function(s) get_saeb(2023, serie = s))`.
#' - For 2011, `type = "aluno"` reads `TS_RESULTADO_ALUNO` (proficiency
#'   results), which covers all grades in one file.
#'
#' @section Data dictionary:
#' For detailed information about variables, see INEP's documentation:
#' \url{https://www.gov.br/inep/pt-br/acesso-a-informacao/dados-abertos/microdados/saeb}
#'
#' @family SAEB functions
#' @export
#'
#' @examples
#' \dontrun{
#' # get 5th grade student results for 2023
#' saeb_5ef <- get_saeb(2023, serie = "5ef", n_max = 10000)
#'
#' # 5th and 9th grades, one call per grade
#' saeb_ef <- purrr::map(c("5ef", "9ef"), function(s) get_saeb(2023, serie = s))
#'
#' # get school questionnaire data
#' saeb_escola <- get_saeb(2023, type = "escola")
#'
#' # SAEB 2021: early childhood education
#' saeb_infantil <- get_saeb(2021, level = "educacao_infantil", n_max = 1000)
#' }
get_saeb <- function(year,
                     type = c("aluno", "escola", "diretor", "professor"),
                     level = c("fundamental_medio", "educacao_infantil"),
                     serie = NULL,
                     n_max = Inf,
                     keep_zip = TRUE,
                     quiet = FALSE) {
  # validate arguments
  validate_year(year, "saeb")
  type <- match.arg(type)
  level <- match.arg(level)

  # warn if level is used for years other than 2021
  if (year != 2021 && level != "fundamental_medio") {
    cli::cli_alert_warning(
      "{.arg level} is only available for SAEB 2021. Ignored."
    )
    level <- "fundamental_medio"
  }

  serie <- normalize_saeb_serie(serie)
  if (!is.null(serie) && type != "aluno") {
    cli::cli_alert_warning(
      "{.arg serie} only applies to {.code type = \"aluno\"}. Ignored."
    )
    serie <- NULL
  }

  # build url and file paths
  url <- build_inep_url("saeb", year, level = level)
  zip_filename <- build_saeb_zip_filename(year, level)
  zip_path <- cache_path("saeb", zip_filename)

  # download if not cached
  if (!is_cached("saeb", zip_filename)) {
    if (!quiet) {
      cli::cli_alert_info("downloading SAEB {.val {year}}...")
    }
    download_inep_file(url, zip_path, quiet = quiet)
  } else if (!quiet) {
    cli::cli_alert_success("using cached file")
  }

  # extract files
  exdir_name <- gsub("\\.zip$", "", zip_filename)
  exdir <- cache_path("saeb", exdir_name)

  if (!dir.exists(exdir) || length(list.files(exdir, recursive = TRUE)) == 0) {
    extract_zip(zip_path, exdir, quiet = quiet)
  }

  # clean up zip if requested
  if (!keep_zip && file.exists(zip_path)) {
    unlink(zip_path)
  }

  # find the data file
  data_file <- find_saeb_file(exdir, year, type, serie = serie)

  if (!quiet) {
    cli::cli_alert_info("reading SAEB data ({.file {basename(data_file)}})...")
    if (is.infinite(n_max)) {
      cli::cli_alert_warning(
        "reading full file. use {.arg n_max} to limit rows if needed."
      )
    }
  }

  # detect delimiter (SAEB files use ";" or "|" depending on year/level)
  delim <- detect_delim(data_file)

  # read the file
  df <- read_inep_file(data_file, delim = delim, n_max = n_max, quiet = quiet)

  # standardize column names
  df <- standardize_names(df)

  # validate data structure
  validate_data(df, "saeb", year)

  if (!quiet) {
    cli::cli_alert_success(
      "loaded {.val {nrow(df)}} rows and {.val {ncol(df)}} columns"
    )
  }

  df
}

#' Build SAEB ZIP filename
#'
#' @description
#' Internal function to build the correct ZIP filename for SAEB data.
#' Handles the special case of 2021 (split into two files).
#'
#' @param year The year.
#' @param level The level (only relevant for 2021).
#'
#' @return The ZIP filename.
#'
#' @keywords internal
build_saeb_zip_filename <- function(year, level = "fundamental_medio") {
  if (year == 2021) {
    level_suffix <- switch(
      level,
      "fundamental_medio" = "_ensino_fundamental_e_medio",
      "educacao_infantil" = "_educacao_infantil"
    )
    str_c("microdados_saeb_", year, level_suffix, ".zip")
  } else {
    str_c("microdados_saeb_", year, ".zip")
  }
}

#' Find the SAEB data file
#'
#' @description
#' Internal function to locate a SAEB data file within the extracted
#' directory based on the requested type.
#'
#' @param exdir The extraction directory.
#' @param year The year.
#' @param type The data type ("aluno", "escola", "diretor", "professor").
#' @param serie For `"aluno"`, the normalized grade code (e.g. `"5ef"`), or
#'   `NULL`.
#'
#' @details
#' Since 2013 INEP ships one student file per grade (`TS_ALUNO_2EF.csv`,
#' `TS_ALUNO_5EF.csv`, ...). These are matched by exact name: with more than
#' one grade available and no `serie`, the function aborts listing the
#' grades instead of picking one silently.
#'
#' @return The path to the data file.
#'
#' @keywords internal
find_saeb_file <- function(exdir, year, type = "aluno", serie = NULL) {
  if (type == "aluno") {
    per_grade <- find_saeb_aluno_by_serie(exdir, year, serie)
    if (!is.null(per_grade)) {
      return(per_grade)
    }
    if (!is.null(serie)) {
      cli::cli_alert_warning(
        "SAEB {.val {year}} has no per-grade student files; {.arg serie} ignored."
      )
    }
  }

  # map type to file pattern
  type_patterns <- switch(
    type,
    "aluno" = c(
      # 2011: proficiency results for all grades in one file
      "TS_RESULTADO_ALUNO",
      str_c("TS_EDUCACAO_INFANTIL_", year),
      "TS_EDUCACAO_INFANTIL",
      "ALUNO",
      "MICRODADOS_SAEB"
    ),
    "escola" = c(
      str_c("TS_ESCOLA_", year),
      "TS_ESCOLA",
      str_c("TS_SECRETARIO_MUNICIPAL_", year),
      "TS_SECRETARIO_MUNICIPAL",
      "ESCOLA"
    ),
    "diretor" = c(
      str_c("TS_DIRETOR_", year),
      "TS_DIRETOR",
      "DIRETOR"
    ),
    "professor" = c(
      str_c("TS_PROFESSOR_", year),
      "TS_PROFESSOR",
      "PROFESSOR"
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
      "no SAEB {.val {type}} data file found for {.val {year}}",
      "i" = "directory: {.path {exdir}}"
    )
  )
}

#' Normalize the SAEB grade argument
#'
#' @description
#' Internal function that turns the user's `serie` into INEP's lowercase
#' grade code: `5` becomes `"5ef"`, `"5EF"` becomes `"5ef"`.
#'
#' @param serie A single grade code or number, or `NULL`.
#'
#' @return A lowercase string, or `NULL`.
#'
#' @keywords internal
normalize_saeb_serie <- function(serie) {
  if (is.null(serie)) {
    return(NULL)
  }

  if (length(serie) != 1 || is.na(serie)) {
    cli::cli_abort(
      c(
        "{.arg serie} must be a single grade code, e.g. {.val 5ef}",
        "i" = "to combine grades, call {.fun get_saeb} once per grade"
      )
    )
  }

  if (is.numeric(serie)) {
    if (!serie %in% c(2, 5, 9)) {
      cli::cli_abort(
        c(
          "numeric {.arg serie} must be 2, 5 or 9",
          "i" = "for high school use INEP's code, e.g. {.val 34em} or {.val 3em}"
        )
      )
    }
    return(str_c(serie, "ef"))
  }

  if (!is.character(serie)) {
    cli::cli_abort("{.arg serie} must be a character code, e.g. {.val 5ef}")
  }

  tolower(trimws(serie))
}

#' Find the per-grade SAEB student file
#'
#' @description
#' Internal function that matches `TS_ALUNO_<serie>.csv` by exact name.
#'
#' @inheritParams find_saeb_file
#'
#' @return The path to the file, or `NULL` when the edition has no
#'   per-grade student files.
#'
#' @keywords internal
find_saeb_aluno_by_serie <- function(exdir, year, serie = NULL) {
  files <- list.files(
    exdir,
    pattern = "^TS_ALUNO_.+\\.csv$",
    recursive = TRUE,
    full.names = TRUE,
    ignore.case = TRUE
  )

  if (length(files) == 0) {
    return(NULL)
  }

  available <- tolower(
    sub("^TS_ALUNO_(.+)\\.csv$", "\\1", basename(files), ignore.case = TRUE)
  )

  if (is.null(serie)) {
    if (length(files) == 1) {
      return(files)
    }
    cli::cli_abort(
      c(
        "SAEB {.val {year}} has one student file per grade; choose one with {.arg serie}",
        "i" = "available grades: {.val {available}}",
        "i" = "e.g. {.code get_saeb({year}, serie = \"{available[length(available)]}\")}"
      )
    )
  }

  match <- which(available == serie)
  if (length(match) == 0) {
    cli::cli_abort(
      c(
        "grade {.val {serie}} not found in SAEB {.val {year}}",
        "i" = "available grades: {.val {available}}"
      )
    )
  }

  files[match[1]]
}

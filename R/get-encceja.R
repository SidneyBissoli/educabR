# encceja functions
# download and process ENCCEJA data from INEP

#' Get ENCCEJA (Exame Nacional para Certificação de Competências de Jovens e Adultos) data
#'
#' @description
#' Downloads and processes microdata from ENCCEJA, the Brazilian National
#' Exam for Youth and Adult Education Certification. ENCCEJA assesses
#' competencies of young people and adults who did not complete basic
#' education at the regular age.
#'
#' @param year The year of the exam (2014, 2017-2020, 2022-2025; INEP
#'   published no microdata for 2015, 2016 and 2021).
#' @param type Which participants to load. INEP ships two microdata files
#'   per edition:
#'   - `"regular"`: the national regular exam (`REG_NAC` / `REGULAR`
#'     file), with almost all participants (default)
#'   - `"ppl"`: the exam applied to people deprived of liberty
#'     (`PPL_NAC` / `PPL` file)
#' @param n_max Maximum number of rows to read. Default is `Inf` (all rows).
#'   Consider using a smaller value for exploration.
#' @param keep_zip Logical. If `TRUE`, keeps the downloaded ZIP file in cache.
#' @param quiet Logical. If `TRUE`, suppresses progress messages.
#'
#' @return A tibble with ENCCEJA microdata in tidy format.
#'
#' @details
#' ENCCEJA is conducted by INEP and provides certification for elementary
#' and high school equivalency for youth and adults (EJA). The exam covers
#' four knowledge areas:
#'
#' - Natural Sciences (Ciências Naturais)
#' - Mathematics (Matemática)
#' - Portuguese Language (Língua Portuguesa)
#' - Social Sciences (Ciências Humanas)
#'
#' **Important notes:**
#'
#' - ENCCEJA files can be large (several hundred MB).
#' - Use `n_max` to read a sample first for exploration.
#' - Column names are standardized to lowercase with underscores.
#'
#' @section Data dictionary:
#' For detailed information about variables, see INEP's documentation:
#' \url{https://www.gov.br/inep/pt-br/acesso-a-informacao/dados-abertos/microdados/encceja}
#'
#' @family ENCCEJA functions
#' @export
#'
#' @examples
#' \dontrun{
#' # get ENCCEJA data for 2023
#' encceja <- get_encceja(2023, n_max = 10000)
#'
#' # get full dataset for 2022
#' encceja_2022 <- get_encceja(2022)
#'
#' # participants deprived of liberty (PPL)
#' encceja_ppl <- get_encceja(2023, type = "ppl")
#' }
get_encceja <- function(year,
                        type = c("regular", "ppl"),
                        n_max = Inf,
                        keep_zip = TRUE,
                        quiet = FALSE) {
  # validate arguments
  validate_year(year, "encceja")
  type <- match.arg(type)

  # build url and file paths
  url <- build_inep_url("encceja", year)
  zip_filename <- str_c("microdados_encceja_", year, ".zip")
  zip_path <- cache_path("encceja", zip_filename)

  # download if not cached
  if (!is_cached("encceja", zip_filename)) {
    if (!quiet) {
      cli::cli_alert_info("downloading ENCCEJA {.val {year}}...")
    }
    download_inep_file(url, zip_path, quiet = quiet)
  } else if (!quiet) {
    cli::cli_alert_success("using cached file")
  }

  # extract files
  exdir_name <- gsub("\\.zip$", "", zip_filename)
  exdir <- cache_path("encceja", exdir_name)

  if (!dir.exists(exdir) || length(list.files(exdir, recursive = TRUE)) == 0) {
    extract_zip(zip_path, exdir, quiet = quiet)
  }

  # clean up zip if requested
  if (!keep_zip && file.exists(zip_path)) {
    unlink(zip_path)
  }

  # find the data file
  data_file <- find_encceja_file(exdir, year, type = type)

  if (!quiet) {
    cli::cli_alert_info("reading ENCCEJA data ({.file {basename(data_file)}})...")
    if (is.infinite(n_max)) {
      cli::cli_alert_warning(
        "reading full file. use {.arg n_max} to limit rows if needed."
      )
    }
  }

  # detect delimiter
  delim <- detect_delim(data_file)

  # read the file
  df <- read_inep_file(data_file, delim = delim, n_max = n_max, quiet = quiet)

  # standardize column names
  df <- standardize_names(df)

  # replace dash placeholders with NA
  df <- clean_dash_values(df)

  # validate data structure
  validate_data(df, "encceja", year)

  if (!quiet) {
    cli::cli_alert_success(
      "loaded {.val {nrow(df)}} rows and {.val {ncol(df)}} columns"
    )
  }

  df
}

#' Find the ENCCEJA data file
#'
#' @description
#' Internal function to locate the ENCCEJA data file within the extracted
#' directory.
#'
#' @param exdir The extraction directory.
#' @param year The year.
#' @param type `"regular"` or `"ppl"`.
#'
#' @details
#' Every published edition ships a regular file (`REG_NAC` or `REGULAR`)
#' and a PPL file (`PPL_NAC` or `PPL`), plus PPL questionnaire and item
#' files. The participant file is chosen by type, so the small PPL file is
#' never returned in place of the regular one. Layouts without either
#' marker fall back to the generic name patterns.
#'
#' @return The path to the data file.
#'
#' @keywords internal
find_encceja_file <- function(exdir, year, type = "regular") {
  # list all data files
  all_files <- list.files(
    exdir,
    pattern = "\\.(csv|CSV|txt|TXT)$",
    recursive = TRUE,
    full.names = TRUE,
    ignore.case = TRUE
  )

  # exclude item/question files (itens_prova, itens, gabarito)
  exclude_pattern <- "itens|gabarito"
  candidate_files <- all_files[!str_detect(str_to_lower(all_files), exclude_pattern)]

  # if all files were excluded, fall back to all files
  if (length(candidate_files) == 0) {
    candidate_files <- all_files
  }

  # participant files: regular exam vs people deprived of liberty (PPL);
  # questionnaires (QSE, QUESTIONARIO) are not participant files
  names_upper <- str_to_upper(basename(candidate_files))
  participant <- !str_detect(names_upper, "QSE|QUESTIONARIO")
  is_ppl <- participant & str_detect(names_upper, "(^|_)PPL(_|\\.)")
  is_regular <- participant & str_detect(names_upper, "(^|_)REG(ULAR)?(_|\\.)")

  if (any(is_ppl | is_regular)) {
    wanted <- if (type == "ppl") is_ppl else is_regular
    if (!any(wanted)) {
      cli::cli_abort(
        c(
          "no ENCCEJA {.val {type}} file found for {.val {year}}",
          "i" = "participant files: {.file {basename(candidate_files[is_ppl | is_regular])}}"
        )
      )
    }
    return(candidate_files[wanted][1])
  }

  # try patterns in priority order on the filtered list
  patterns <- c(
    str_c("microdados_encceja_", year),
    str_c("microdados", year),
    "microdados_encceja",
    "microdados"
  )

  for (pattern in patterns) {
    matched <- candidate_files[str_detect(
      str_to_lower(candidate_files),
      str_to_lower(pattern)
    )]

    if (length(matched) > 0) {
      return(matched[1])
    }
  }

  # last resort: return first candidate
  if (length(candidate_files) > 0) {
    return(candidate_files[1])
  }

  cli::cli_abort(
    c(
      "no ENCCEJA data file found for {.val {year}}",
      "i" = "directory: {.path {exdir}}"
    )
  )
}

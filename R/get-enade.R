# enade functions
# download and process ENADE data from INEP

# hardcoded URL map — INEP uses inconsistent naming for ENADE files
enade_urls <- c(
  "2004" = "https://download.inep.gov.br/microdados/microdados_enade_2004_LGPD.zip",
  "2005" = "https://download.inep.gov.br/microdados/microdados_enade_2005_LGPD.zip",
  "2006" = "https://download.inep.gov.br/microdados/microdados_enade_2006_LGPD.zip",
  "2007" = "https://download.inep.gov.br/microdados/microdados_enade_2007_LGPD.zip",
  "2008" = "https://download.inep.gov.br/microdados/microdados_enade_2008_LGPD.zip",
  "2009" = "https://download.inep.gov.br/microdados/microdados_enade_2009_LGPD.zip",
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
#' Every edition is published as several files (`arq1`, `arq2`, ...), each
#' with one group of variables. **The files cannot be joined student by
#' student**: to comply with the LGPD, INEP sorts each file by different
#' variables, so the first row of one file is not the same student as the
#' first row of another. `get_enade()` therefore reads one file per call;
#' use [list_enade_files()] to see which variables each file holds.
#'
#' @param year The year of the exam (2004-2019, 2021-2023).
#' @param arquivo The file to read: the number in its name
#'   (`microdados2023_arq3.txt` is `arquivo = 3`). Default `NULL` reads
#'   file 1 (course and institution identifiers) and warns that the
#'   edition is split.
#' @param n_max Maximum number of rows to read. Default is `Inf` (all rows).
#'   Consider using a smaller value for exploration.
#' @param keep_zip Logical. If `TRUE`, keeps the downloaded ZIP file in cache.
#' @param quiet Logical. If `TRUE`, suppresses progress messages.
#'
#' @return A tibble with the microdata of one ENADE file.
#'
#' @details
#' ENADE is conducted annually by INEP and evaluates undergraduate students
#' nearing the end of their programs. Each year, a different set of course
#' areas is assessed on a rotating cycle (typically every 3 years per area).
#'
#' Every file carries `nu_ano` and `co_curso`, so files can be combined at
#' the course level (for example, averages by `co_curso`), as INEP's user
#' manual recommends. Combining them row by row produces records that mix
#' different students; up to educabR 1.2.0, `get_enade()` did exactly that.
#' Student-level linkage is only available through INEP's protected data
#' service (Sedap).
#'
#' **Important notes:**
#'
#' - Use `n_max` to read a sample first for exploration.
#' - Column names are standardized to lowercase with underscores.
#' - Not all course areas are assessed every year due to the rotating cycle.
#' - The numbering of files can skip numbers (2013 has no `arq3`).
#'
#' @section Data dictionary:
#' Each edition ships a dictionary of files and variables
#' (`Dicionario_arquivos_variaveis_microdados_Enade_<year>.xlsx`) in the
#' downloaded archive. See also INEP's documentation:
#' \url{https://www.gov.br/inep/pt-br/acesso-a-informacao/dados-abertos/microdados/enade}
#'
#' @family ENADE functions
#' @export
#'
#' @examples
#' \dontrun{
#' # which variables are in which file?
#' list_enade_files(2023)
#'
#' # read one file
#' arq3 <- get_enade(2023, arquivo = 3)
#'
#' # combine files at the course level (co_curso), never row by row
#' scores <- get_enade(2023, arquivo = 3)
#' by_course <- aggregate(nt_ger ~ co_curso, data = scores, FUN = mean)
#' }
get_enade <- function(
  year,
  arquivo = NULL,
  n_max = Inf,
  keep_zip = TRUE,
  quiet = FALSE
) {
  # validate arguments
  validate_year(year, "enade")
  if (
    !is.null(arquivo) &&
      (length(arquivo) != 1L || !is.numeric(arquivo) || is.na(arquivo))
  ) {
    cli::cli_abort(c(
      "{.arg arquivo} must be a single file number",
      "i" = "see the files of an edition with {.code list_enade_files({year})}"
    ))
  }

  exdir <- enade_prepare(year, keep_zip = keep_zip, quiet = quiet)
  data_files <- find_enade_files(exdir, year)
  numbers <- enade_file_number(data_files)

  if (is.null(arquivo)) {
    arquivo <- 1L
    if (length(data_files) > 1L) {
      cli::cli_warn(
        c(
          "ENADE {.val {year}} is split into {.val {length(data_files)}} files that cannot be joined by student; reading {.code arquivo = 1}",
          "i" = "see which variables each file holds with {.code list_enade_files({year})}",
          "i" = "then read one with {.code get_enade({year}, arquivo = n)}"
        ),
        .frequency = "regularly",
        .frequency_id = "educabR_enade_arquivo"
      )
    }
  }

  if (!arquivo %in% numbers) {
    cli::cli_abort(c(
      "ENADE {.val {year}} has no file {.val {arquivo}}",
      "i" = "available files: {.val {numbers}}",
      "i" = "see their variables with {.code list_enade_files({year})}"
    ))
  }

  data_file <- data_files[match(arquivo, numbers)]

  if (!quiet) {
    cli::cli_alert_info(
      "reading ENADE {.val {year}} file {.val {basename(data_file)}}..."
    )
  }

  delim <- detect_delim(data_file)
  df <- read_inep_file(data_file, delim = delim, n_max = n_max, quiet = quiet)
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

#' List the files of an ENADE edition
#'
#' @description
#' Downloads (if needed) the microdata of an ENADE edition and lists its
#' data files with the variables each one holds. Use the `arquivo` number
#' with [get_enade()].
#'
#' @param year The year of the exam.
#' @param quiet Logical. If `TRUE`, suppresses progress messages.
#'
#' @return A tibble with one row per file: `arquivo` (number to pass to
#'   [get_enade()]), `nome` (file name), `n_variaveis` and `variaveis`
#'   (the variables other than `nu_ano` and `co_curso`, comma-separated).
#'
#' @family ENADE functions
#' @export
#'
#' @examples
#' \dontrun{
#' files <- list_enade_files(2023)
#'
#' # which file has the overall score?
#' files[grepl("nt_ger", files$variaveis), ]
#' }
list_enade_files <- function(year, quiet = FALSE) {
  validate_year(year, "enade")
  exdir <- enade_prepare(year, keep_zip = TRUE, quiet = quiet)
  data_files <- find_enade_files(exdir, year)

  vars <- lapply(data_files, function(f) {
    header <- suppressMessages(readr::read_delim(
      f,
      delim = detect_delim(f),
      n_max = 0,
      locale = readr::locale(encoding = detect_encoding(f)),
      show_col_types = FALSE
    ))
    setdiff(names(standardize_names(header)), c("nu_ano", "co_curso"))
  })

  dplyr::tibble(
    arquivo = enade_file_number(data_files),
    nome = basename(data_files),
    n_variaveis = lengths(vars),
    variaveis = vapply(vars, paste, character(1), collapse = ", ")
  )
}

#' Download and extract an ENADE edition
#'
#' @description
#' Internal function shared by [get_enade()] and [list_enade_files()].
#'
#' @param year The year.
#' @param keep_zip Logical. Keep the downloaded archive.
#' @param quiet Logical. Suppress messages.
#'
#' @return The extraction directory.
#'
#' @keywords internal
enade_prepare <- function(year, keep_zip = TRUE, quiet = FALSE) {
  # get url from map (or build for unknown years)
  url <- enade_urls[as.character(year)]
  if (is.na(url)) {
    url <- build_inep_url("enade", year)
  }
  url <- unname(url)

  archive_filename <- basename(url)
  archive_path <- cache_path("enade", archive_filename)

  if (!is_cached("enade", archive_filename)) {
    if (!quiet) {
      cli::cli_alert_info("downloading ENADE {.val {year}}...")
    }
    download_inep_file(url, archive_path, quiet = quiet)
  } else if (!quiet) {
    cli::cli_alert_success("using cached file")
  }

  exdir <- cache_path("enade", tools::file_path_sans_ext(archive_filename))
  if (!dir.exists(exdir) || length(list.files(exdir, recursive = TRUE)) == 0) {
    extract_archive(archive_path, exdir, quiet = quiet)
  }

  if (!keep_zip && file.exists(archive_path)) {
    unlink(archive_path)
  }

  exdir
}

#' Number of an ENADE data file
#'
#' @description
#' Internal function. `microdados2023_arq12.txt` is file 12; a file without
#' an `arq` number counts as file 1.
#'
#' @param files File paths.
#'
#' @return An integer vector.
#'
#' @keywords internal
enade_file_number <- function(files) {
  n <- as.integer(str_extract(basename(files), "(?<=arq)[0-9]+"))
  n[is.na(n)] <- 1L
  n
}

#' Find ENADE data files
#'
#' @description
#' Internal function to locate all ENADE data files within the extracted
#' directory. INEP distributes ENADE microdata split across multiple files
#' (`arq1.txt`, `arq2.txt`, ...) that share the columns `NU_ANO` and
#' `CO_CURSO` but are sorted differently (they cannot be joined by row).
#'
#' @param exdir The extraction directory.
#' @param year The year.
#'
#' @return A character vector of file paths, sorted by split number.
#'
#' @keywords internal
find_enade_files <- function(exdir, year) {
  patterns <- c(
    str_c("microdados", year, "_arq"),
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
      # sort split files numerically (arq1, arq2, ..., arq10, arq11, ...)
      nums <- as.integer(str_extract(basename(files), "(?<=arq)\\d+"))
      if (!all(is.na(nums))) {
        files <- files[order(nums)]
      }
      return(files)
    }
  }

  cli::cli_abort(
    c(
      "no ENADE data file found for {.val {year}}",
      "i" = "directory: {.path {exdir}}"
    )
  )
}

# conceito enade functions
# download and process Conceito Enade spreadsheets from INEP

# hardcoded URL map: INEP has no consistent naming pattern for these files.
# 2007-2011 are not listed: INEP publishes the Conceito Enade of those
# editions inside the combined Enade/CPC table, so the CPC file is used
# (see conceito_enade_source()).
conceito_enade_urls <- c(
  "2004" = "https://download.inep.gov.br/download/enade/planilhas/2004_Enade.xls",
  "2005" = "https://download.inep.gov.br/download/enade/planilhas/2005_Enade.xls",
  "2006" = "https://download.inep.gov.br/download/enade/planilhas/Conceito_Enade_2006_29_03_2018.xls",
  "2012" = "https://download.inep.gov.br/educacao_superior/enade/planilhas/2012/conceito_enade_2012.xlsx",
  "2013" = "https://download.inep.gov.br/educacao_superior/enade/planilhas/2013/conceito_enade_2013.xlsx",
  "2014" = "https://download.inep.gov.br/educacao_superior/enade/planilhas/2014/conceito_enade_2014_atualizado_em_04122017.xlsx",
  "2015" = "https://download.inep.gov.br/educacao_superior/indicadores/legislacao/2017/conceito_enade_2015_portal_atualizado_03_10_2017.xls",
  "2016" = "https://download.inep.gov.br/educacao_superior/indicadores/legislacao/2017/resultado_enade2016_portal_06_09_2017.xlsx",
  "2017" = "https://download.inep.gov.br/educacao_superior/indicadores/legislacao/2018/resultados_conceito_enade_2017.xlsx",
  "2018" = "https://download.inep.gov.br/educacao_superior/indicadores/legislacao/2019/resultados_conceito_enade_2018.xlsx",
  "2019" = "https://download.inep.gov.br/educacao_superior/indicadores/resultados/2019/Conceito_Enade_2019.xlsx",
  "2021" = "https://download.inep.gov.br/educacao_superior/indicadores/resultados/2021/conceito_enade_2021.xlsx",
  "2022" = "https://download.inep.gov.br/educacao_superior/indicadores/resultados/2022/conceito_enade_2022.xlsx",
  "2023" = "https://download.inep.gov.br/educacao_superior/indicadores/resultados/2023/conceito_enade_2023.xlsx"
)

# 2025: one file per exam (Enade das Licenciaturas, Enade Medicina)
conceito_enade_2025_urls <- c(
  "licenciaturas" = "https://download.inep.gov.br/educacao_superior/indicadores/resultados/2025/conceito_enade_licenciaturas.xlsx",
  "medicina" = "https://download.inep.gov.br/educacao_superior/indicadores/resultados/2025/conceito_enade_medicina_2025.xlsx"
)

# sheets that are not the first one in the file
conceito_enade_sheets <- c(
  # the 2021 file opens on a 4-row scratch sheet ("Planilha2")
  "2021" = "PLANILHA_ENADE"
)

#' Get Conceito Enade data
#'
#' @description
#' Downloads and processes the Conceito Enade spreadsheets published by
#' INEP. The Conceito Enade is the course-level quality indicator derived
#' from the performance of graduating students in ENADE, on a continuous
#' scale and in five levels (faixas 1 to 5).
#'
#' Unlike [get_enade()], which returns student-level microdata, this
#' function returns one row per course (or per course unit, before 2015)
#' with the official indicator.
#'
#' @param year The year of the indicator (2004-2019, 2021-2023, 2025).
#'   There is no 2020 edition (ENADE was not held) and no 2024 edition.
#' @param type Only for 2025, which INEP publishes as two files with
#'   their own methodology: `"licenciaturas"` (Enade das Licenciaturas)
#'   or `"medicina"` (Enade Medicina). Must be `NULL` for other years.
#' @param n_max Maximum number of rows to read. Default is `Inf` (all rows).
#' @param keep_file Logical. If `TRUE`, keeps the downloaded file in cache.
#'   Default is `TRUE`.
#' @param quiet Logical. If `TRUE`, suppresses progress messages.
#'
#' @return A tibble with Conceito Enade data in tidy format.
#'
#' @details
#' **Unit of observation.** Up to 2014 a row is a "course unit": all
#' courses of the same institution, municipality and evaluation area,
#' identified by the institution, municipality and area codes (the number
#' of courses grouped is in a column such as `numero_de_cursos_da_unidade`).
#' From 2015 on, a row is a course, identified by `codigo_do_curso` (the
#' e-MEC course code).
#'
#' **Sources by edition.**
#'
#' - 2004-2006 and 2012-2023: INEP's Conceito Enade spreadsheet.
#' - 2007-2011: INEP publishes the Conceito Enade inside the combined
#'   Enade/CPC table, so this function returns that table (the same one
#'   as [get_cpc()]). The Conceito Enade is in `conceito_enade` (2007,
#'   2008) or `conceito_enade_faixa` (2009-2011).
#' - 2025: see `type`. These files report the share of graduates at or
#'   above a proficiency standard and the faixa, with no continuous score.
#'
#' **Important notes:**
#'
#' - Column names change across editions and are standardized to
#'   lowercase with underscores, not harmonized: map them to a common set
#'   before stacking years.
#' - Faixa and continuous columns are numeric; "SC" (sem conceito) and
#'   similar markers become `NA`.
#' - Files are in Excel format (xls/xlsx).
#'
#' @section Data dictionary:
#' For detailed information about variables, see INEP's documentation:
#' \url{https://www.gov.br/inep/pt-br/areas-de-atuacao/pesquisas-estatisticas-e-indicadores/indicadores-de-qualidade-da-educacao-superior}
#'
#' @family CPC/IGC functions
#' @export
#'
#' @examples
#' \dontrun{
#' # Conceito Enade 2023
#' ce <- get_conceito_enade(2023)
#'
#' # 2025 comes in two files
#' ce_lic <- get_conceito_enade(2025, type = "licenciaturas")
#'
#' # a series: one call per year, then harmonize column names
#' series <- purrr::map(c(2017, 2018, 2019), get_conceito_enade)
#' }
get_conceito_enade <- function(
  year,
  type = NULL,
  n_max = Inf,
  keep_file = TRUE,
  quiet = FALSE
) {
  # validate arguments
  validate_year(year, "conceito_enade")
  source <- conceito_enade_source(year, type)

  ext <- tools::file_ext(source$url)
  suffix <- if (is.null(type)) "" else str_c("_", source$type)
  filename <- str_c("conceito_enade_", year, suffix, ".", ext)
  file_path <- cache_path("conceito_enade", filename)

  # download if not cached
  if (!is_cached("conceito_enade", filename)) {
    if (!quiet) {
      cli::cli_alert_info("downloading Conceito Enade {.val {year}}...")
    }
    download_inep_file(source$url, file_path, quiet = quiet)
  } else if (!quiet) {
    cli::cli_alert_success("using cached file")
  }

  if (!quiet) {
    cli::cli_alert_info("reading Conceito Enade data...")
  }

  df <- read_excel_safe(file_path, n_max = n_max, sheet = source$sheet)

  # standardize column names
  df <- standardize_names(df)

  # replace dash placeholders with NA
  df <- clean_dash_values(df)

  # convert faixa and continuo columns to numeric
  df <- convert_faixa_columns(df)

  # validate data structure
  validate_data(df, "conceito_enade", year)

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

#' Resolve the source file of a Conceito Enade edition
#'
#' @description
#' Internal function. Returns the URL, the sheet and the resolved `type`
#' for a year: the Conceito Enade spreadsheet, the combined Enade/CPC
#' table for 2007-2011, or one of the two 2025 files.
#'
#' @param year The year.
#' @param type `NULL`, or `"licenciaturas"` / `"medicina"` for 2025.
#'
#' @return A list with `url`, `sheet` and `type`.
#'
#' @keywords internal
conceito_enade_source <- function(year, type = NULL) {
  key <- as.character(year)

  if (year == 2025) {
    options <- names(conceito_enade_2025_urls)
    if (is.null(type)) {
      cli::cli_abort(
        c(
          "the 2025 Conceito Enade is published as two files",
          "i" = "choose one with {.arg type}: {.val {options}}"
        )
      )
    }
    type <- match.arg(type, options)
    return(list(url = conceito_enade_2025_urls[[type]], sheet = 1, type = type))
  }

  if (!is.null(type)) {
    cli::cli_abort(
      c(
        "{.arg type} only applies to the 2025 edition",
        "i" = "use {.code get_conceito_enade({year})} without {.arg type}"
      )
    )
  }

  url <- if (key %in% names(conceito_enade_urls)) {
    conceito_enade_urls[[key]]
  } else {
    cpc_urls[[key]]
  }
  sheet <- if (key %in% names(conceito_enade_sheets)) {
    conceito_enade_sheets[[key]]
  } else {
    1
  }

  list(url = url, sheet = sheet, type = NULL)
}

# cpc functions
# download and process CPC data from INEP

# hardcoded URL map — INEP has no consistent naming pattern for CPC files
cpc_urls <- c(
  "2007" = "https://download.inep.gov.br/educacao_superior/enade/planilhas/2007/cpc_2007_decomposto_23_05_2011.xls",
  "2008" = "https://download.inep.gov.br/educacao_superior/enade/planilhas/2008/2008_enade_cpc_decomposto_23_05_2011.xls",

  "2009" = "https://download.inep.gov.br/download/enade/2009/cpc_decomposto_2009.xls",
  "2010" = "https://download.inep.gov.br/educacao_superior/enade/planilhas/2010/tabela_enade_cpc_2010.xls",
  "2011" = "https://download.inep.gov.br/educacao_superior/enade/planilhas/2011/tabela_enade_cpc_2011_retificado_08_02_13.xls",
  "2012" = "https://download.inep.gov.br/educacao_superior/enade/planilhas/2012/cpc_2012_site_2014_03_14.xls",
  "2013" = "https://download.inep.gov.br/educacao_superior/enade/planilhas/2013/cpc2013_atualizado_em_27112017.xls",
  "2014" = "https://download.inep.gov.br/educacao_superior/enade/planilhas/2014/cpc2014_atualizado_em_04122017.xlsx",
  "2015" = "https://download.inep.gov.br/educacao_superior/indicadores/legislacao/2017/cpc_2015_portal_atualizado_03_10_2017.xls",
  "2016" = "https://download.inep.gov.br/educacao_superior/indicadores/legislacao/2017/Resultado_CPC_2016_portal_23_02_2018.xls",
  "2017" = "https://download.inep.gov.br/educacao_superior/igc_cpc/2018/resultado_cpc_2017.xlsx",
  "2018" = "https://download.inep.gov.br/educacao_superior/igc_cpc/2018/portal_CPC_edicao2018.xlsx",
  "2019" = "https://download.inep.gov.br/educacao_superior/indicadores/resultados/2019/resultados_cpc_2019.xlsx",
  "2021" = "https://download.inep.gov.br/educacao_superior/indicadores/resultados/2021/CPC_2021.xlsx",
  "2022" = "https://download.inep.gov.br/educacao_superior/indicadores/resultados/2022/cpc_2022.xlsx",
  "2023" = "https://download.inep.gov.br/educacao_superior/indicadores/resultados/2023/CPC_2023.xlsx"
)

#' Get CPC (Conceito Preliminar de Curso) data
#'
#' @description
#' Downloads and processes CPC data from INEP. The CPC is a quality
#' indicator for undergraduate courses in Brazil, composed of ENADE
#' scores, IDD, faculty qualifications, pedagogical resources, and
#' other institutional factors.
#'
#' @param year The year of the indicator (2007-2019, 2021-2023).
#'   Note: there is no 2020 edition. Years 2004-2006 used a different
#'   indicator ("Conceito Enade").
#' @param n_max Maximum number of rows to read. Default is `Inf` (all rows).
#' @param keep_file Logical. If `TRUE`, keeps the downloaded file in cache.
#'   Default is `TRUE`.
#' @param quiet Logical. If `TRUE`, suppresses progress messages.
#'
#' @return A tibble with CPC data in tidy format.
#'
#' @details
#' CPC is calculated by INEP as part of the higher education quality
#' assessment system (SINAES). It serves as a preliminary indicator
#' used to determine which courses require on-site evaluation.
#'
#' The data includes:
#'
#' - Course and institution identifiers
#' - CPC scores (continuous and categorical/faixa)
#' - Component scores (ENADE, IDD, faculty, infrastructure, etc.)
#' - Number of students evaluated
#'
#' **Important notes:**
#'
#' - CPC follows ENADE's rotating cycle of course areas, so each year
#'   covers a specific set of fields.
#' - There is no 2020 edition (COVID-19 suspension).
#' - Column names are standardized to lowercase with underscores.
#' - Files are in Excel format (xls/xlsx), not CSV.
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
#' # get CPC data for 2023
#' cpc <- get_cpc(2023)
#'
#' # get CPC data for 2021 with limited rows
#' cpc_2021 <- get_cpc(2021, n_max = 1000)
#' }
get_cpc <- function(year,
                    n_max = Inf,
                    keep_file = TRUE,
                    quiet = FALSE) {
  # validate arguments
  validate_year(year, "cpc")

  # get url from lookup table
  url <- cpc_urls[[as.character(year)]]
  ext <- tools::file_ext(url)
  filename <- str_c("cpc_", year, ".", ext)
  file_path <- cache_path("cpc", filename)

  # download if not cached
  if (!is_cached("cpc", filename)) {
    if (!quiet) {
      cli::cli_alert_info("downloading CPC {.val {year}}...")
    }
    download_inep_file(url, file_path, quiet = quiet)
  } else if (!quiet) {
    cli::cli_alert_success("using cached file")
  }

  if (!quiet) {
    cli::cli_alert_info("reading CPC data...")
  }

  # read the excel file
  df <- read_excel_safe(file_path, n_max = n_max)

  # standardize column names
  df <- standardize_names(df)

  # replace dash placeholders with NA
  df <- clean_dash_values(df)

  # convert faixa columns to numeric
  df <- convert_faixa_columns(df)

  # validate data structure
  validate_data(df, "cpc", year)

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

#' Read Excel file safely
#'
#' @description
#' Internal function to read Excel files (xls/xlsx) with error handling.
#' Tries to read the first sheet by default.
#'
#' @param file Path to the Excel file.
#' @param n_max Maximum number of rows to read.
#'
#' @return A tibble with the data.
#'
#' @keywords internal
read_excel_safe <- function(file, n_max = Inf) {
  if (!requireNamespace("readxl", quietly = TRUE)) {
    cli::cli_abort(
      c(
        "the {.pkg readxl} package is required to read CPC/IGC data",
        "i" = "install it with {.code install.packages(\"readxl\")}"
      )
    )
  }

  n_max_arg <- if (is.infinite(n_max)) Inf else n_max

  df <- tryCatch(
    {
      readxl::read_excel(file, n_max = n_max_arg, .name_repair = "minimal")
    },
    error = function(e) {
      cli::cli_abort(
        c(
          "failed to read Excel file",
          "x" = "file: {.path {file}}",
          "i" = "error: {conditionMessage(e)}"
        )
      )
    }
  )

  # force code columns (CO_*, CD_*) to character to preserve leading zeros
  code_cols <- grep("^(CO_|CD_)", names(df), ignore.case = TRUE, value = TRUE)
  for (col in code_cols) {
    df[[col]] <- as.character(df[[col]])
  }

  df
}

#' Convert faixa columns to numeric
#'
#' @description
#' Internal function to convert columns ending in `_faixa` from character
#' to numeric. Values like `"SC"` (Sem Conceito) are converted to `NA`.
#'
#' @param df A data frame.
#'
#' @return The data frame with faixa columns as numeric.
#'
#' @keywords internal
convert_faixa_columns <- function(df) {
  faixa_cols <- names(df)[grepl("_faixa$", names(df))]

  for (col in faixa_cols) {
    df[[col]] <- suppressWarnings(as.numeric(df[[col]]))
  }

  df
}

# igc functions
# download and process IGC data from INEP

# hardcoded URL map — INEP has no consistent naming pattern for IGC files
igc_urls <- c(
  "2007" = "https://download.inep.gov.br/download/areaigc/Downloads/igc_2007_03_04_2018.7z",
  "2008" = "https://download.inep.gov.br/download/areaigc/Downloads/igc_2008_03_04_2018.xlsx",
  "2009" = "https://download.inep.gov.br/download/areaigc/Downloads/igc_2009.xls",
  "2010" = "https://download.inep.gov.br/educacao_superior/enade/igc/tabela_igc_2010_16_10_2012.xls",
  "2011" = "https://download.inep.gov.br/educacao_superior/enade/igc/tabela_igc_2011_15_01_2013.xls",
  "2012" = "https://download.inep.gov.br/educacao_superior/enade/igc/tabela_igc_2012_30012014.xls",
  "2013" = "https://download.inep.gov.br/educacao_superior/enade/igc/2013/igc_2013_09022015.xlsx",
  "2014" = "https://download.inep.gov.br/educacao_superior/enade/igc/2014/igc_2014.xlsx",
  "2015" = "https://download.inep.gov.br/educacao_superior/indicadores/legislacao/2017/igc_2015_portal_04_12_2017.xlsx",
  "2016" = "https://download.inep.gov.br/educacao_superior/igc_cpc/2016/resultado_igc_2016_11042018.xlsx",
  "2017" = "https://download.inep.gov.br/educacao_superior/igc_cpc/2018/resultado_igc_2017.xlsx",
  "2018" = "https://download.inep.gov.br/educacao_superior/igc_cpc/2018/portal_IGC_edicao2018.xlsx",
  "2019" = "https://download.inep.gov.br/educacao_superior/indicadores/resultados/2019/IGC_2019.xlsx",
  "2021" = "https://download.inep.gov.br/educacao_superior/indicadores/resultados/2021/IGC_2021.xlsx",
  "2022" = "https://download.inep.gov.br/educacao_superior/indicadores/resultados/2022/igc_2022.xlsx",
  "2023" = "https://download.inep.gov.br/educacao_superior/indicadores/resultados/2023/IGC_2023.xlsx"
)

#' Get IGC (Indice Geral de Cursos) data
#'
#' @description
#' Downloads and processes IGC data from INEP. The IGC is a quality
#' indicator for higher education institutions in Brazil, calculated
#' as a weighted average of CPC scores across all evaluated courses
#' plus CAPES scores for graduate programs.
#'
#' @param year The year of the indicator (2007-2019, 2021-2023).
#'   Note: there is no 2020 edition. Years 2004-2006 used a different
#'   indicator ("Conceito Enade").
#' @param n_max Maximum number of rows to read. Default is `Inf` (all rows).
#' @param keep_file Logical. If `TRUE`, keeps the downloaded file in cache.
#'   Default is `TRUE`.
#' @param quiet Logical. If `TRUE`, suppresses progress messages.
#'
#' @return A tibble with IGC data in tidy format.
#'
#' @details
#' IGC is calculated by INEP as part of the higher education quality
#' assessment system (SINAES). It provides an overall quality measure
#' for institutions, considering both undergraduate and graduate programs.
#'
#' The data includes:
#'
#' - Institution identifiers (code, name, organization type)
#' - IGC scores (continuous and categorical/faixa)
#' - Number of courses and students considered
#' - Component breakdown (undergraduate CPC average, graduate CAPES scores)
#'
#' **Important notes:**
#'
#' - IGC is published annually based on the last three ENADE cycles.
#' - There is no 2020 edition (COVID-19 suspension).
#' - Column names are standardized to lowercase with underscores.
#' - Files are in Excel format (xls/xlsx), except 2007 which is 7z.
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
#' # get IGC data for 2023
#' igc <- get_igc(2023)
#'
#' # get IGC data for 2021 with limited rows
#' igc_2021 <- get_igc(2021, n_max = 1000)
#' }
get_igc <- function(year,
                    n_max = Inf,
                    keep_file = TRUE,
                    quiet = FALSE) {
  # validate arguments
  validate_year(year, "igc")

  # get url from lookup table
  url <- igc_urls[[as.character(year)]]
  ext <- tools::file_ext(url)

  # igc 2007 is a 7z archive
  is_archive <- tolower(ext) == "7z"

  filename <- str_c("igc_", year, ".", ext)
  file_path <- cache_path("igc", filename)

  # download if not cached
  if (!is_cached("igc", filename)) {
    if (!quiet) {
      cli::cli_alert_info("downloading IGC {.val {year}}...")
    }
    download_inep_file(url, file_path, quiet = quiet)
  } else if (!quiet) {
    cli::cli_alert_success("using cached file")
  }

  if (!quiet) {
    cli::cli_alert_info("reading IGC data...")
  }

  if (is_archive) {
    # extract the 7z archive and find the excel file inside
    exdir <- cache_path("igc", str_c("igc_", year))

    if (!dir.exists(exdir) || length(list.files(exdir, recursive = TRUE)) == 0) {
      extract_archive(file_path, exdir, quiet = quiet)
    }

    # find excel file inside extracted directory
    excel_files <- list.files(
      exdir,
      pattern = "\\.(xlsx|xls|XLS|XLSX)$",
      recursive = TRUE,
      full.names = TRUE
    )

    if (length(excel_files) == 0) {
      cli::cli_abort(
        c(
          "no Excel file found in IGC {.val {year}} archive",
          "i" = "directory: {.path {exdir}}"
        )
      )
    }

    df <- read_excel_safe(excel_files[1], n_max = n_max)
  } else {
    df <- read_excel_safe(file_path, n_max = n_max)
  }

  # standardize column names
  df <- standardize_names(df)

  # replace dash placeholders with NA
  df <- clean_dash_values(df)

  # convert faixa columns to numeric
  df <- convert_faixa_columns(df)

  # validate data structure
  validate_data(df, "igc", year)

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

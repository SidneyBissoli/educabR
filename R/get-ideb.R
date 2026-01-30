# ideb functions
# download and process IDEB data from INEP

#' Get IDEB (Índice de Desenvolvimento da Educação Básica) data
#'
#' @description
#' Downloads and processes IDEB data from INEP. IDEB is the main indicator
#' of education quality in Brazil, combining student performance (from SAEB)
#' with grade promotion rates.
#'
#' @param year The year of the IDEB (available: 2017, 2019, 2021, 2023).
#' @param level The aggregation level:
#'   - `"escola"`: School level
#'   - `"municipio"`: Municipality level
#' @param stage The education stage:
#'   - `"anos_iniciais"`: Early elementary (1st-5th grade)
#'   - `"anos_finais"`: Late elementary (6th-9th grade)
#'   - `"ensino_medio"`: High school
#' @param uf Optional. Filter by state (UF code or abbreviation).
#' @param quiet Logical. If `TRUE`, suppresses progress messages.
#'
#' @return A tibble with IDEB data in tidy format.
#'
#' @details
#' IDEB is calculated every two years since 2005 based on:
#'
#' - **Learning**: Average scores in Portuguese and Mathematics from SAEB
#' - **Flow**: Grade promotion rate (inverse of repetition/dropout)
#'
#' The index ranges from 0 to 10. Brazil's national goal is to reach 6.0
#' by 2022 (the level of developed countries in PISA).
#'
#' **Note:** IDEB data is relatively small compared to other INEP datasets,
#' so no `n_max` parameter is provided.
#'
#' @section Data source:
#' Official IDEB portal: \url{https://www.gov.br/inep/pt-br/areas-de-atuacao/pesquisas-estatisticas-e-indicadores/ideb}
#'
#' @export
#'
#' @examples
#' \donttest{
#' # get school-level IDEB for early elementary in 2021
#' ideb_escolas <- get_ideb(2021, level = "escola", stage = "anos_iniciais")
#'
#' # get municipality-level IDEB for São Paulo state
#' ideb_sp <- get_ideb(2021, level = "municipio", stage = "anos_iniciais", uf = "SP")
#'
#' # get high school IDEB for all municipalities
#' ideb_em <- get_ideb(2023, level = "municipio", stage = "ensino_medio")
#' }
get_ideb <- function(year,
                     level = c("escola", "municipio"),
                     stage = c("anos_iniciais", "anos_finais", "ensino_medio"),
                     uf = NULL,
                     quiet = FALSE) {
  # validate arguments
  level <- match.arg(level)
  stage <- match.arg(stage)

  # validate year (IDEB available for 2017, 2019, 2021, 2023)
  valid_years <- c(2017L, 2019L, 2021L, 2023L)
  if (!year %in% valid_years) {
    cli::cli_abort(
      c(
        "year {.val {year}} not available for IDEB downloads",
        "i" = "available years: {.val {valid_years}}"
      )
    )
  }

  # map level names to url format
  level_url <- switch(
    level,
    "escola" = "escolas",
    "municipio" = "municipios"

  )

  # build url based on year

# URL structure varies by year:
  # 2023: https://download.inep.gov.br/ideb/resultados/divulgacao_{stage}_{level}_{year}.xlsx
  # 2017-2021: https://download.inep.gov.br/educacao_basica/portal_ideb/planilhas_para_download/{year}/divulgacao_{stage}_{level}_{year}.xlsx
  if (year == 2023L) {
    base_url <- "https://download.inep.gov.br/ideb/resultados"
    filename <- str_c("divulgacao_", stage, "_", level_url, "_", year, ".xlsx")
  } else {
    base_url <- str_c(
      "https://download.inep.gov.br/educacao_basica/portal_ideb/planilhas_para_download/",
      year
    )
    filename <- str_c("divulgacao_", stage, "_", level_url, "_", year, ".xlsx")
  }

  url <- str_c(base_url, "/", filename)

  # cache path for xlsx file
  xlsx_path <- cache_path("ideb", filename)

  # download if not cached
  if (!file.exists(xlsx_path)) {
    if (!quiet) {
      cli::cli_alert_info(
        "downloading IDEB {.val {year}} - {.val {stage}} - {.val {level}}..."
      )
    }
    download_inep_file(url, xlsx_path, quiet = quiet)
  } else if (!quiet) {
    cli::cli_alert_success("using cached file")
  }

  if (!quiet) {
    cli::cli_alert_info("reading IDEB data...")
  }

  # read the xlsx file directly
  df <- read_ideb_excel(xlsx_path)

  # standardize column names
  df <- standardize_names(df)

  # filter by UF if requested
  if (!is.null(uf) && level %in% c("escola", "municipio")) {
    uf_code <- uf_to_code(uf)

    # find uf column (might be sg_uf, co_uf, uf, etc.)
    uf_cols <- names(df)[str_detect(names(df), "uf|estado")]

    if (length(uf_cols) > 0) {
      # try to filter
      if ("sg_uf" %in% uf_cols) {
        df <- df |>
          dplyr::filter(str_to_upper(.data$sg_uf) == toupper(uf))
      } else if ("co_uf" %in% uf_cols) {
        df <- df |>
          dplyr::filter(.data$co_uf == uf_code)
      }
    }
  }

  if (!quiet) {
    cli::cli_alert_success(
      "loaded {.val {nrow(df)}} rows and {.val {ncol(df)}} columns"
    )
  }

  df
}

#' Read IDEB Excel file
#'
#' @description
#' Internal function to read IDEB Excel files.
#'
#' @param file Path to the Excel file.
#'
#' @return A tibble with the data.
#'
#' @keywords internal
read_ideb_excel <- function(file) {
  # check if readxl is available
  if (!requireNamespace("readxl", quietly = TRUE)) {
    cli::cli_abort(
      c(
        "package {.pkg readxl} is required to read IDEB Excel files",
        "i" = "install with: {.code install.packages('readxl')}"
      )
    )
  }

  # IDEB Excel files have 9 header rows before the actual column names
  # Row 10 contains the column names (SG_UF, CO_MUNICIPIO, etc.)
  readxl::read_excel(file, skip = 9)
}

#' Get IDEB historical series
#'
#' @description
#' Downloads and combines IDEB data across multiple years to create
#' a historical series.
#'
#' @param years Vector of years to include (default: all available).
#' @param level The aggregation level.
#' @param stage The education stage.
#' @param uf Optional. Filter by state.
#' @param quiet Logical. If `TRUE`, suppresses progress messages.
#'
#' @return A tibble with IDEB data for all requested years.
#'
#' @export
#'
#' @examples
#' \donttest{
#' # get IDEB history for municipalities
#' ideb_hist <- get_ideb_series(
#'   years = c(2017, 2019, 2021),
#'   level = "municipio",
#'   stage = "anos_iniciais"
#' )
#' }
get_ideb_series <- function(years = NULL,
                            level = c("escola", "municipio"),
                            stage = c("anos_iniciais", "anos_finais", "ensino_medio"),
                            uf = NULL,
                            quiet = FALSE) {
  level <- match.arg(level)
  stage <- match.arg(stage)

  # default to all available years for download
  valid_years <- c(2017L, 2019L, 2021L, 2023L)
  if (is.null(years)) {
    years <- valid_years
  }

  # validate years
  invalid <- setdiff(years, valid_years)
  if (length(invalid) > 0) {
    cli::cli_abort(
      c(
        "year(s) {.val {invalid}} not available for IDEB downloads",
        "i" = "available years: {.val {valid_years}}"
      )
    )
  }

  if (!quiet) {
    cli::cli_alert_info(
      "downloading IDEB data for {.val {length(years)}} year(s)..."
    )
  }

  # download and combine
  df_list <- purrr::map(years, function(y) {
    tryCatch(
      {
        df <- get_ideb(y, level = level, stage = stage, uf = uf, quiet = TRUE)
        df$ano_ideb <- y
        df
      },
      error = function(e) {
        cli::cli_alert_warning("failed to get IDEB {.val {y}}: {e$message}")
        NULL
      }
    )
  })

  # remove NULLs
  df_list <- purrr::compact(df_list)

  if (length(df_list) == 0) {
    cli::cli_abort("no data retrieved")
  }

  # combine
  df <- dplyr::bind_rows(df_list)

  if (!quiet) {
    cli::cli_alert_success(
      "loaded {.val {nrow(df)}} rows for {.val {length(df_list)}} year(s)"
    )
  }

  df
}

#' List available IDEB data
#'
#' @description
#' Lists the IDEB data files available in the INEP portal.
#'
#' @return A tibble with available IDEB datasets.
#'
#' @export
#'
#' @examples
#' list_ideb_available()
list_ideb_available <- function() {
  years <- c(2017L, 2019L, 2021L, 2023L)
  levels <- c("escola", "municipio")
  stages <- c("anos_iniciais", "anos_finais", "ensino_medio")

  tidyr::expand_grid(
    year = years,
    level = levels,
    stage = stages
  ) |>
    dplyr::arrange(.data$year, .data$level, .data$stage)
}

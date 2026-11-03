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
get_cpc <- function(year, n_max = Inf, keep_file = TRUE, quiet = FALSE) {
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
#' Reads the first sheet by default. Three INEP layout quirks are handled:
#'
#' - a title row above the header (e.g. IGC 2009) is skipped, by taking as
#'   header the first row where at least half of the columns are filled;
#' - a sub-header row below the header (e.g. IGC 2008: "IGC" over
#'   "Continuo" and "Faixas") is merged into the column names;
#' - blank, footnote and total rows (e.g. CPC 2021 and 2022, IGC 2021),
#'   i.e. rows with at most one filled cell, are dropped.
#'
#' @param file Path to the Excel file.
#' @param n_max Maximum number of rows to read.
#' @param sheet Sheet name or position. Default is the first sheet.
#'
#' @return A tibble with the data.
#'
#' @keywords internal
read_excel_safe <- function(file, n_max = Inf, sheet = 1) {
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
      skip <- excel_header_skip(file, sheet)
      readxl::read_excel(
        file,
        sheet = sheet,
        skip = skip,
        n_max = n_max_arg,
        # guess types from every row: INEP columns can be empty for the
        # first 1000 rows (Conceito Enade 2006 "Sub Area"), and the default
        # guess turns them into logical, silently dropping later values
        guess_max = if (is.infinite(n_max)) 1e6 else n_max,
        .name_repair = "minimal",
        na = c("", "-", "ND", "\u2013", "\u2014")
      )
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

  df <- drop_footer_rows(df)
  df <- merge_subheader_row(df)

  # force code columns (CO_*, CD_*) to character to preserve leading zeros
  code_cols <- grep("^(CO_|CD_)", names(df), ignore.case = TRUE, value = TRUE)
  for (col in code_cols) {
    df[[col]] <- as.character(df[[col]])
  }

  normalize_utf8_nfc(df)
}

#' Find how many title rows precede the header of an Excel sheet
#'
#' @description
#' Internal function. Returns the number of rows to skip so that the
#' header is the first row where at least half of the columns are filled.
#' A sheet whose first row is already the header returns 0.
#'
#' @param file Path to the Excel file.
#' @param sheet Sheet name or position.
#'
#' @return An integer.
#'
#' @keywords internal
excel_header_skip <- function(file, sheet = 1) {
  top <- suppressMessages(
    readxl::read_excel(file, sheet = sheet, col_names = FALSE, n_max = 15)
  )
  if (nrow(top) == 0 || ncol(top) == 0) {
    return(0L)
  }
  filled <- rowSums(!is.na(top))
  header <- which(filled >= max(2, ncol(top) / 2))[1]
  if (is.na(header)) 0L else as.integer(header - 1L)
}

#' Drop blank, footnote and total rows from a sheet read with readxl
#'
#' @description
#' Internal function. INEP spreadsheets end with blank rows, footnotes
#' written in the first column, or a lone total in one column (CPC 2022).
#' A data row always fills several columns, so rows with at most one
#' filled cell are dropped.
#'
#' @param df A data frame.
#'
#' @return The data frame without those rows.
#'
#' @keywords internal
drop_footer_rows <- function(df) {
  if (ncol(df) < 2 || nrow(df) == 0) {
    return(df)
  }
  df[rowSums(!is.na(df)) > 1, , drop = FALSE]
}

#' Merge a sub-header row into the column names
#'
#' @description
#' Internal function. Some INEP sheets have a second header row: IGC 2008
#' has "IGC" over two columns, with "Continuo" and "Faixas" below it, and
#' repeats "Cod. IES". That row is detected as a first row that fills less
#' than half of the columns and holds only text. Each of its cells
#' completes the name of its column (a cell under an empty header
#' completes the nearest named header to its left; a cell that repeats the
#' header is ignored). The row is then dropped and the affected columns are
#' re-typed.
#'
#' @param df A data frame.
#'
#' @return The data frame.
#'
#' @keywords internal
merge_subheader_row <- function(df) {
  if (nrow(df) < 2 || ncol(df) < 2) {
    return(df)
  }

  first <- vapply(df[1, ], function(x) as.character(x[[1]]), character(1))
  filled <- !is.na(first)
  numeric_like <- !is.na(suppressWarnings(as.numeric(first[filled])))
  if (sum(filled) < 1 || sum(filled) >= ncol(df) / 2 || any(numeric_like)) {
    return(df)
  }

  fold <- function(x) {
    tolower(gsub("[^A-Za-z0-9]", "", ascii_fold(x)))
  }

  header <- names(df)
  new <- header
  for (j in which(filled)) {
    if (!is.na(header[j]) && header[j] != "") {
      if (fold(first[j]) != fold(header[j])) {
        new[j] <- str_c(header[j], " ", first[j])
      }
    } else {
      named <- which(!is.na(header[seq_len(j)]) & header[seq_len(j)] != "")
      left <- if (length(named) > 0) header[max(named)] else ""
      new[j] <- str_trim(str_c(left, " ", first[j]))
    }
  }

  df <- df[-1, , drop = FALSE]
  names(df) <- new
  affected <- names(df)[filled & vapply(df, is.character, logical(1))]
  if (length(affected) > 0) {
    df[affected] <- readr::type_convert(
      df[affected],
      col_types = readr::cols(.default = readr::col_guess()),
      na = c("", "NA")
    )
  }
  df
}

#' Convert faixa and continuo columns to numeric
#'
#' @description
#' Internal function to convert score columns (names ending in `_faixa`,
#' `_faixas` or `_continuo`) from character to numeric. Non-numeric
#' markers such as `"SC"` (Sem Conceito) and `"sub judice"` are converted
#' to `NA`. Stacking the sheets of the IGC 2007-2016 can turn these
#' columns into text when only one sheet carries such a marker.
#'
#' @param df A data frame.
#'
#' @return The data frame with score columns as numeric.
#'
#' @keywords internal
convert_faixa_columns <- function(df) {
  faixa_cols <- names(df)[
    grepl("(_faixas?|_continuo)$", names(df)) &
      vapply(df, is.character, logical(1))
  ]

  for (col in faixa_cols) {
    df[[col]] <- suppressWarnings(as.numeric(df[[col]]))
  }

  df
}

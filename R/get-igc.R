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
#' - Files are in Excel format (xls/xlsx), except 2007, a 7z archive of
#'   CSV files.
#' - From 2007 to 2016, INEP splits the table by type of institution
#'   (one sheet or CSV each for universities, university centers and
#'   faculties); all parts are read and stacked into one tibble.
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
get_igc <- function(year, n_max = Inf, keep_file = TRUE, quiet = FALSE) {
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

    if (
      !dir.exists(exdir) || length(list.files(exdir, recursive = TRUE)) == 0
    ) {
      extract_archive(file_path, exdir, quiet = quiet)
    }

    # the 2007 archive holds one CSV per type of institution
    # (Universidade, Centro Universitario, Outros), not an Excel file
    data_files <- list.files(
      exdir,
      pattern = "\\.(csv|xlsx|xls)$",
      recursive = TRUE,
      full.names = TRUE,
      ignore.case = TRUE
    )

    if (length(data_files) == 0) {
      cli::cli_abort(
        c(
          "no data file found in IGC {.val {year}} archive",
          "i" = "directory: {.path {exdir}}"
        )
      )
    }

    parts <- lapply(data_files, function(f) {
      if (grepl("\\.csv$", f, ignore.case = TRUE)) {
        suppressMessages(read_inep_file(
          f,
          delim = detect_delim(f),
          n_max = n_max,
          quiet = TRUE
        ))
      } else {
        read_excel_safe(f, n_max = n_max)
      }
    })
    df <- bind_igc_parts(parts)
  } else {
    # 2008-2016 spread the institutions over one sheet per type of
    # institution (Universidades / Centros Universitarios / Faculdades);
    # later sheets hold course- or program-level inputs, not IGC rows
    sheets <- igc_institution_sheets(file_path)
    parts <- lapply(sheets, function(s) {
      read_excel_safe(file_path, n_max = n_max, sheet = s)
    })
    df <- bind_igc_parts(parts)
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

#' Find the institution-level sheets of an IGC spreadsheet
#'
#' @description
#' Internal function. From 2008 to 2016, INEP splits the IGC table into
#' one sheet per type of institution ("Universidades", "Centros
#' Universitarios", "Faculdades" or "Outros"), followed by sheets with
#' course- or program-level inputs. Returns the institution sheets, or the
#' first sheet when the file is not split (2017 onwards).
#'
#' @param file Path to the Excel file.
#'
#' @return A character vector of sheet names.
#'
#' @keywords internal
igc_institution_sheets <- function(file) {
  if (!requireNamespace("readxl", quietly = TRUE)) {
    cli::cli_abort(
      c(
        "the {.pkg readxl} package is required to read CPC/IGC data",
        "i" = "install it with {.code install.packages(\"readxl\")}"
      )
    )
  }
  sheets <- readxl::excel_sheets(file)
  folded <- tolower(ascii_fold(sheets))
  is_inst <- grepl("^(universidade|centro|faculdade|outros)", folded)
  if (any(is_inst)) sheets[is_inst] else sheets[1]
}

#' Stack the parts of an IGC table
#'
#' @description
#' Internal function. Stacks the per-institution-type parts of an IGC
#' table. Parts with the same number of columns take the column names of
#' the first part, because INEP sometimes words the same header
#' differently across sheets (IGC 2010: "Porcentagem de" in one sheet,
#' "%" in the others). Otherwise parts are stacked by name. Columns whose
#' type differs across parts are converted to character.
#'
#' @param parts A list of data frames.
#'
#' @return A tibble.
#'
#' @keywords internal
bind_igc_parts <- function(parts) {
  if (length(parts) == 1) {
    return(parts[[1]])
  }

  widths <- vapply(parts, ncol, integer(1))
  if (all(widths == widths[1])) {
    first_names <- names(parts[[1]])
    parts <- lapply(parts, function(p) {
      names(p) <- first_names
      p
    })
  }

  all_cols <- unique(unlist(lapply(parts, names)))
  for (col in all_cols) {
    classes <- unique(unlist(lapply(parts, function(p) {
      if (col %in% names(p)) class(p[[col]])[1]
    })))
    # an all-empty column comes back as logical and binds with any type
    if (length(setdiff(classes, "logical")) > 1) {
      parts <- lapply(parts, function(p) {
        if (col %in% names(p)) {
          p[[col]] <- as.character(p[[col]])
        }
        p
      })
    }
  }

  dplyr::bind_rows(parts)
}

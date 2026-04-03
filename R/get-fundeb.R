# fundeb functions
# download and process FUNDEB data
# distribution: STN (Secretaria do Tesouro Nacional) Excel files
# enrollment: FNDE OData API

# hardcoded URL map for FUNDEB distribution (STN transfers)
# base: https://thot-arquivos.tesouro.gov.br/publicacao/{id}
fundeb_recursos_ids <- c(
  "2007" = "28512",
  "2008" = "28513",
  "2009" = "28514",
  "2010" = "28515",
  "2011" = "28516",
  "2012" = "28517",
  "2013" = "28518",
  "2014" = "28519",
  "2015" = "28520",
  "2016" = "28521",
  "2017" = "28522",
  "2018" = "28523",
  "2019" = "29102",
  "2020" = "31597",
  "2021" = "37244",
  "2022" = "42670",
  "2023" = "46131",
  "2024" = "48848",
  "2025" = "51322",
  "2026" = "53824"
)

# valid FUNDEB transfer sources (sheet name suffixes)
fundeb_sources <- c("FPE", "FPM", "IPI", "ITR", "VAAF", "VAAT", "VAAR",
                     "ICMS", "IPVA", "ITCMD")

# Portuguese month names to month numbers (ASCII only, input is normalized)
fundeb_month_map <- c(
  "JANEIRO" = 1L, "FEVEREIRO" = 2L, "MARCO" = 3L,
  "ABRIL" = 4L, "MAIO" = 5L, "JUNHO" = 6L,
  "JULHO" = 7L, "AGOSTO" = 8L, "SETEMBRO" = 9L,
  "OUTUBRO" = 10L, "NOVEMBRO" = 11L, "DEZEMBRO" = 12L
)

# strip common diacriticals to ASCII (avoids encoding issues on Windows)
strip_diacriticals <- function(x) {
  x <- gsub("\u00c7|\u00e7", "C", x)  # Ç/ç -> C
  x <- gsub("\u00e3|\u00c3", "A", x)  # ã/Ã -> A
  x <- gsub("\u00e9|\u00c9", "E", x)  # é/É -> E
  x <- gsub("\u00ed|\u00cd", "I", x)  # í/Í -> I
  x <- gsub("\u00f3|\u00d3", "O", x)  # ó/Ó -> O
  x <- gsub("\u00fa|\u00da", "U", x)  # ú/Ú -> U
  x
}

# OData API base URL for FUNDEB matriculas (FNDE)
fundeb_enrollment_api_url <- function() {
  "https://www.fnde.gov.br/olinda-ide/servico/FUNDEB_Matriculas/versao/v1/odata/FUNDEBMatriculas"
}

#' Get FUNDEB distribution data
#'
#' @description
#' Downloads and processes FUNDEB resource distribution data from STN
#' (Secretaria do Tesouro Nacional). Each year's Excel file contains
#' multiple sheets with monthly transfer data by state/municipality,
#' broken down by funding source.
#'
#' @param year The year of the data (2007-2026).
#' @param uf Optional. A UF code (e.g., `"SP"`, `"RJ"`) to filter by state.
#'   Default is `NULL` (all states).
#' @param source Optional. The funding source to filter by. One of:
#'   `"FPE"`, `"FPM"`, `"IPI"`, `"ITR"`, `"VAAF"`, `"VAAT"`, `"VAAR"`,
#'   `"ICMS"`, `"IPVA"`, `"ITCMD"`. Default is `NULL` (all sources).
#' @param destination Optional. The transfer destination. One of:
#'   - `"uf"`: Transfers to states and the Federal District
#'   - `"municipio"`: Transfers to municipalities
#'
#'   Default is `NULL` (both).
#' @param n_max Maximum number of rows to return. Default is `Inf` (all rows).
#' @param keep_file Logical. If `TRUE`, keeps the downloaded file in cache.
#'   Default is `TRUE`.
#' @param quiet Logical. If `TRUE`, suppresses progress messages.
#'
#' @return A tibble in tidy (long) format with columns:
#'   \describe{
#'     \item{estados}{State name}
#'     \item{uf}{State code (UF)}
#'     \item{mes_ano}{Date (last day of the month)}
#'     \item{origem}{Funding source (FPE, FPM, ICMS, etc.)}
#'     \item{destino}{Transfer destination ("UF" or "Municipio")}
#'     \item{tabela}{Table type ("Fundeb" or "Ajuste Fundeb")}
#'     \item{valor}{Transfer amount in BRL (numeric)}
#'   }
#'
#' @details
#' FUNDEB (Fundo de Manutencao e Desenvolvimento da Educacao Basica e de
#' Valorizacao dos Profissionais da Educacao) is the main funding mechanism
#' for basic education in Brazil.
#'
#' Each Excel file from STN contains ~20 data sheets named with a prefix
#' indicating the destination (`E_` for states, `M_` for municipalities)
#' and a suffix indicating the funding source (e.g., `E_FPE`, `M_ICMS`).
#' Each sheet contains two tables: the main FUNDEB transfers and a
#' FUNDEB adjustment table.
#'
#' **Important notes:**
#'
#' - Data is sourced from STN (Tesouro Nacional), not INEP.
#' - Files are in Excel format (XLS) — requires the `readxl` package.
#' - Column names are standardized to lowercase with underscores.
#' - Summary sheets (Resumo, Total, etc.) are automatically excluded.
#'
#' @section Data source:
#' \url{https://www.tesourotransparente.gov.br}
#'
#' @family FUNDEB functions
#' @export
#'
#' @examples
#' \dontrun{
#' # get all FUNDEB distribution data for 2023
#' dist_2023 <- get_fundeb_distribution(2023)
#'
#' # get only FPE transfers to states
#' fpe_estados <- get_fundeb_distribution(2023, source = "FPE",
#'                                         destination = "uf")
#'
#' # get data for Sao Paulo only
#' sp <- get_fundeb_distribution(2023, uf = "SP")
#' }
get_fundeb_distribution <- function(year,
                                    uf = NULL,
                                    source = NULL,
                                    destination = NULL,
                                    n_max = Inf,
                                    keep_file = TRUE,
                                    quiet = FALSE) {
  # validate arguments
  validate_year(year, "fundeb")

  if (!is.null(source)) {
    source <- toupper(source)
    if (!source %in% fundeb_sources) {
      cli::cli_abort(
        c(
          "invalid source: {.val {source}}",
          "i" = "valid sources: {.val {fundeb_sources}}"
        )
      )
    }
  }

  if (!is.null(destination)) {
    destination <- match.arg(destination, choices = c("uf", "municipio"))
    # map parameter value to internal label
    destination <- if (destination == "uf") "UF" else "Munic\u00edpio"
  }

  if (!requireNamespace("readxl", quietly = TRUE)) {
    cli::cli_abort(
      c(
        "the {.pkg readxl} package is required to read FUNDEB distribution data",
        "i" = "install it with {.code install.packages(\"readxl\")}"
      )
    )
  }

  # download if not cached
  url <- build_fundeb_url(year)
  filename <- str_c("fundeb_distribution_", year, ".xls")
  file_path <- cache_path("fundeb", filename)

  if (!is_cached("fundeb", filename)) {
    if (!quiet) {
      cli::cli_alert_info("downloading FUNDEB distribution {.val {year}}...")
    }
    download_inep_file(url, file_path, quiet = quiet)
  } else if (!quiet) {
    cli::cli_alert_success("using cached file")
  }

  # read all sheets and combine into tidy format
  if (!quiet) {
    cli::cli_alert_info("reading FUNDEB distribution data...")
  }

  df <- read_fundeb_sheets(file_path, year, source = source,
                           destination = destination, quiet = quiet)

  # filter by UF if requested
  if (!is.null(uf)) {
    uf <- toupper(uf)
    df <- df[toupper(df$uf) == uf, ]
  }

  # enforce n_max
  if (!is.infinite(n_max) && nrow(df) > n_max) {
    df <- df[seq_len(n_max), ]
  }

  # validate data structure
  validate_data(df, "fundeb", year)

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

# column name mapping for FUNDEB enrollment (OData CamelCase -> snake_case)
fundeb_enrollment_col_names <- c(
  "anocenso"                   = "ano_censo",
  "uf"                         = "uf",
  "municipioge"                = "municipio",
  "tiporedeeducacao"           = "tipo_rede_educacao",
  "descricaotipoeducacao"      = "descricao_tipo_educacao",
  "descricaotipoensino"        = "descricao_tipo_ensino",
  "descricaotipoturma"         = "descricao_tipo_turma",
  "descricaotipocargahoraria"  = "descricao_tipo_carga_horaria",
  "descricaotipolocalizacao"   = "descricao_tipo_localizacao",
  "qtdmatricula"               = "qtd_matricula"
)

#' Get FUNDEB enrollment data
#'
#' @description
#' Downloads and processes FUNDEB enrollment data from FNDE's OData API.
#' These are the enrollment counts considered for FUNDEB funding calculation.
#'
#' @param year The year of the data (2007-2026).
#' @param uf Optional. A UF code (e.g., `"SP"`, `"RJ"`) to filter by state.
#'   The filter is applied at the API level for efficiency. Default is `NULL`
#'   (all states).
#' @param n_max Maximum number of rows to read. Default is `Inf` (all rows).
#' @param keep_file Logical. If `TRUE`, caches the API result as a local CSV
#'   file. Default is `TRUE`.
#' @param quiet Logical. If `TRUE`, suppresses progress messages.
#'
#' @return A tibble with columns:
#'   \describe{
#'     \item{ano_censo}{Census year}
#'     \item{uf}{State code (UF)}
#'     \item{municipio}{Municipality name}
#'     \item{tipo_rede_educacao}{Education network type}
#'     \item{descricao_tipo_educacao}{Education type description}
#'     \item{descricao_tipo_ensino}{Teaching type description}
#'     \item{descricao_tipo_turma}{Class type description}
#'     \item{descricao_tipo_carga_horaria}{Class hours type description}
#'     \item{descricao_tipo_localizacao}{Location type description}
#'     \item{qtd_matricula}{Number of enrollments}
#'   }
#'
#' @details
#' Enrollment data comes from FNDE (Fundo Nacional de Desenvolvimento da
#' Educacao) via its OData API. It includes the number of enrollments
#' considered for FUNDEB funding, broken down by state, municipality,
#' education type, school network, class type, and location.
#'
#' **Important notes:**
#'
#' - Data is sourced from FNDE, not INEP.
#' - Requires the `jsonlite` package.
#' - Results are cached locally as CSV after first download.
#' - Column names are standardized to lowercase with underscores.
#' - When `uf` is used with a cached file, filtering is done locally.
#'
#' @section Data source:
#' FNDE: \code{https://www.fnde.gov.br}
#'
#' @family FUNDEB functions
#' @export
#'
#' @examples
#' \dontrun{
#' # get FUNDEB enrollment data for 2023
#' mat_2023 <- get_fundeb_enrollment(2023)
#'
#' # get enrollment data for Sao Paulo only
#' mat_sp <- get_fundeb_enrollment(2023, uf = "SP")
#'
#' # get enrollment data with limited rows
#' mat_sample <- get_fundeb_enrollment(2023, n_max = 1000)
#' }
get_fundeb_enrollment <- function(year,
                                  uf = NULL,
                                  n_max = Inf,
                                  keep_file = TRUE,
                                  quiet = FALSE) {
  # validate arguments
  validate_year(year, "fundeb_enrollment")

  # check for jsonlite
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    cli::cli_abort(
      c(
        "the {.pkg jsonlite} package is required to read FUNDEB enrollment data",
        "i" = "install it with {.code install.packages(\"jsonlite\")}"
      )
    )
  }

  # check cache first
  filename <- str_c("fundeb_enrollment_", year, ".csv")
  file_path <- cache_path("fundeb", filename)

  if (is_cached("fundeb", filename)) {
    if (!quiet) {
      cli::cli_alert_success("using cached file")
      cli::cli_alert_info("reading FUNDEB enrollment data...")
    }

    delim <- detect_delim(file_path)
    df <- read_inep_file(file_path, delim = delim, n_max = n_max)
    df <- rename_fundeb_enrollment(df)

    # filter by UF locally on cached data
    if (!is.null(uf)) {
      uf <- toupper(uf)
      df <- df[toupper(df$uf) == uf, ]
    }

    validate_data(df, "fundeb_enrollment", year)

    if (!quiet) {
      cli::cli_alert_success(
        "loaded {.val {nrow(df)}} rows and {.val {ncol(df)}} columns"
      )
    }

    return(df)
  }

  # fetch from OData API with pagination
  if (!quiet) {
    cli::cli_alert_info("fetching FUNDEB enrollment {.val {year}} from FNDE API...")
  }

  df <- fetch_fundeb_enrollment(year, uf = uf, n_max = n_max, quiet = quiet)
  df <- rename_fundeb_enrollment(df)

  validate_data(df, "fundeb_enrollment", year)

  # cache as CSV for future use
  if (keep_file) {
    dir.create(dirname(file_path), recursive = TRUE, showWarnings = FALSE)
    readr::write_csv(df, file_path)
    if (!quiet) {
      cli::cli_alert_success("cached result as {.path {filename}}")
    }
  }

  if (!quiet) {
    cli::cli_alert_success(
      "loaded {.val {nrow(df)}} rows and {.val {ncol(df)}} columns"
    )
  }

  df
}

# --- internal helpers ---

#' Build FUNDEB distribution URL from lookup table
#'
#' @description
#' Internal function to construct the download URL for FUNDEB distribution
#' data from STN. Uses a hardcoded lookup table of publication IDs.
#'
#' @param year The year.
#'
#' @return A character string with the download URL.
#'
#' @keywords internal
build_fundeb_url <- function(year) {
  year_str <- as.character(year)
  id <- fundeb_recursos_ids[year_str]

  if (is.na(id)) {
    cli::cli_abort(
      c(
        "no FUNDEB distribution URL found for year {.val {year}}",
        "i" = "available years: {.val {names(fundeb_recursos_ids)}}"
      )
    )
  }

  str_c("https://thot-arquivos.tesouro.gov.br/publicacao/", id)
}

# read all valid sheets from the FUNDEB Excel file and combine into tidy format
read_fundeb_sheets <- function(file_path, year, source = NULL,
                               destination = NULL, quiet = FALSE) {
  sheets <- readxl::excel_sheets(file_path)

  # keep only data sheets: E_ or M_ prefix + valid source suffix
  # excludes summary sheets (Tot1, Tot2, Total) and non-standard sheets (COUN)
  # match sheets starting with E_ or M_ and ending with a valid source
  # handles both E_FPE and E_COUN_VAAR patterns
  valid_suffix_pattern <- str_c("(", str_c(fundeb_sources, collapse = "|"), ")$")
  valid_sheets <- sheets[grepl(
    str_c("^[EM]_.*", valid_suffix_pattern),
    toupper(sheets)
  )]

  if (length(valid_sheets) == 0) {
    cli::cli_abort(
      c(
        "no valid data sheets found in FUNDEB Excel file",
        "i" = "expected sheets with E_ or M_ prefix",
        "i" = "sheets found: {.val {sheets}}"
      )
    )
  }

  all_data <- list()

  for (sheet in valid_sheets) {
    # parse sheet name: E_FPE -> dest="UF", src="FPE"
    # some sheets have 3 parts: E_COUN_VAAR -> dest="UF", src="VAAR"
    parts <- strsplit(toupper(sheet), "_", fixed = TRUE)[[1]]
    dest_name <- if (parts[1] == "E") "UF" else "Munic\u00edpio"
    src_name <- parts[length(parts)]

    # filter by destination/source before reading (efficiency)
    if (!is.null(destination) && dest_name != destination) next
    if (!is.null(source) && src_name != toupper(source)) next

    if (!quiet) {
      cli::cli_alert_info("processing sheet {.val {sheet}}...")
    }

    sheet_data <- tryCatch(
      parse_fundeb_sheet(file_path, sheet, year, src_name, dest_name),
      error = function(e) {
        if (!quiet) {
          cli::cli_alert_warning(
            "skipping sheet {.val {sheet}}: {conditionMessage(e)}"
          )
        }
        NULL
      }
    )

    if (!is.null(sheet_data) && nrow(sheet_data) > 0) {
      all_data <- c(all_data, list(sheet_data))
    }
  }

  if (length(all_data) == 0) {
    cli::cli_abort("no data could be read from FUNDEB Excel file")
  }

  dplyr::bind_rows(all_data)
}

# parse a single sheet from the FUNDEB Excel file
# each sheet has two tables: main fundeb + ajuste fundeb
parse_fundeb_sheet <- function(file_path, sheet_name, year,
                               source_name, dest_name) {
  raw <- readxl::read_excel(file_path, sheet = sheet_name,
                            col_names = FALSE, .name_repair = "minimal")

  # find all header rows (rows containing "UF")
  header_rows <- integer(0)
  for (i in seq_len(nrow(raw))) {
    vals <- toupper(trimws(as.character(unlist(raw[i, ]))))
    if ("UF" %in% vals) {
      header_rows <- c(header_rows, i)
    }
  }

  if (length(header_rows) == 0) return(dplyr::tibble())

  table_names <- c("Fundeb", "Ajuste Fundeb")
  tables <- list()

  for (t in seq_along(header_rows)) {
    h <- header_rows[t]

    # determine end of this table section
    if (t < length(header_rows)) {
      end_row <- header_rows[t + 1] - 1
    } else {
      end_row <- nrow(raw)
    }

    if (h >= end_row) next

    # column names from header row
    col_names <- trimws(as.character(unlist(raw[h, ])))

    # data rows
    data_section <- raw[(h + 1):end_row, ]
    names(data_section) <- col_names

    tabela <- if (t <= length(table_names)) table_names[t] else str_c("tabela_", t)

    tidy <- tidy_fundeb_table(data_section, year, source_name, dest_name, tabela)
    if (nrow(tidy) > 0) {
      tables <- c(tables, list(tidy))
    }
  }

  if (length(tables) == 0) return(dplyr::tibble())
  dplyr::bind_rows(tables)
}

# clean a single table section and pivot months to long format
tidy_fundeb_table <- function(df, year, source_name, dest_name, tabela) {
  upper_names <- toupper(trimws(names(df)))

  # remove TOTAL column
  total_idx <- which(upper_names == "TOTAL")
  if (length(total_idx) > 0) {
    df <- df[, -total_idx]
    upper_names <- upper_names[-total_idx]
  }

  # normalize month names to ASCII before matching
  upper_names <- strip_diacriticals(upper_names)

  # identify month columns
  month_idx <- which(upper_names %in% names(fundeb_month_map))

  if (length(month_idx) == 0) return(dplyr::tibble())

  # find estado (first column) and UF column
  uf_idx <- which(upper_names == "UF")[1]
  estado_idx <- 1L

  if (is.na(uf_idx)) return(dplyr::tibble())

  # remove non-data rows (summary, observations, empty, repeated headers)
  first_col <- toupper(trimws(as.character(df[[estado_idx]])))
  skip <- is.na(first_col) |
    grepl("^(REPASSE|OBSERVA|AJUSTE|ESTADOS|$)", first_col)
  df <- df[!skip, ]

  if (nrow(df) == 0) return(dplyr::tibble())

  # select columns: estado, uf, months
  month_cols <- names(df)[month_idx]
  estados_col <- names(df)[estado_idx]
  uf_col <- names(df)[uf_idx]

  df_select <- df[, c(estados_col, uf_col, month_cols)]
  names(df_select)[1:2] <- c("estados", "uf")

  # pivot months to long
  month_col_names <- names(df_select)[3:ncol(df_select)]

  df_long <- tidyr::pivot_longer(
    df_select,
    cols = dplyr::all_of(month_col_names),
    names_to = "mes_nome",
    values_to = "valor"
  )

  # convert valor to numeric
  df_long$valor <- suppressWarnings(as.numeric(df_long$valor))

  # convert month names to dates (last day of each month)
  month_num <- fundeb_month_map[strip_diacriticals(toupper(trimws(df_long$mes_nome)))]
  next_month <- ifelse(month_num == 12L, 1L, month_num + 1L)
  next_year <- ifelse(month_num == 12L, year + 1L, year)
  df_long$mes_ano <- as.Date(
    paste(next_year, next_month, "01", sep = "-")
  ) - 1L

  # add metadata columns
  df_long$origem <- source_name
  df_long$destino <- dest_name
  df_long$tabela <- tabela

  # select and order final columns
  df_long <- df_long[, c("estados", "uf", "mes_ano", "origem", "destino",
                          "tabela", "valor")]

  dplyr::as_tibble(df_long)
}

# rename FUNDEB enrollment columns from CamelCase to snake_case
rename_fundeb_enrollment <- function(df) {
  df <- standardize_names(df)
  current <- names(df)
  matched <- fundeb_enrollment_col_names[current]
  names(df) <- ifelse(is.na(matched), current, matched)
  df
}

#' Fetch FUNDEB enrollment data from FNDE OData API
#'
#' @description
#' Internal function to fetch FUNDEB enrollment data from FNDE's OData API
#' with pagination support.
#'
#' @param year The year.
#' @param uf Optional UF code to filter at the API level.
#' @param n_max Maximum number of rows to fetch.
#' @param quiet Logical. If `TRUE`, suppresses progress messages.
#'
#' @return A tibble with enrollment data.
#'
#' @keywords internal
fetch_fundeb_enrollment <- function(year, uf = NULL, n_max = Inf, quiet = FALSE) {
  base_url <- fundeb_enrollment_api_url()
  page_size <- 10000L
  all_rows <- list()
  skip <- 0L
  total_fetched <- 0L

  # build OData filter clause
  filter_clause <- str_c("AnoCenso eq ", year)
  if (!is.null(uf)) {
    filter_clause <- str_c(filter_clause, " and Uf eq '", toupper(uf), "'")
  }

  repeat {
    # determine how many to fetch this page
    remaining <- if (is.infinite(n_max)) page_size else min(page_size, n_max - total_fetched)
    if (remaining <= 0) break

    if (!quiet) {
      cli::cli_alert_info("fetching records {.val {skip + 1}} to {.val {skip + remaining}}...")
    }

    # perform request (use req_url_query for proper URL encoding)
    page_data <- tryCatch(
      {
        req <- httr2::request(base_url) |>
          httr2::req_url_query(
            `$filter` = filter_clause,
            `$top` = remaining,
            `$skip` = skip,
            `$format` = "json"
          ) |>
          httr2::req_timeout(seconds = 300) |>
          httr2::req_retry(max_tries = 3, backoff = ~ 15)

        resp <- httr2::req_perform(req)
        body <- httr2::resp_body_json(resp)

        body$value
      },
      error = function(e) {
        cli::cli_abort(
          c(
            "failed to fetch FUNDEB enrollment data from FNDE API",
            "x" = "year: {.val {year}}, skip: {.val {skip}}",
            "i" = "error: {conditionMessage(e)}",
            "i" = "check your internet connection"
          )
        )
      }
    )

    # no more data
    if (length(page_data) == 0) break

    # convert list of lists to tibble
    page_df <- dplyr::bind_rows(lapply(page_data, as.data.frame))
    all_rows <- c(all_rows, list(page_df))

    total_fetched <- total_fetched + nrow(page_df)
    skip <- skip + nrow(page_df)

    if (!quiet) {
      cli::cli_alert_success("fetched {.val {total_fetched}} records so far")
    }

    # stop if we got fewer rows than requested (last page)
    if (nrow(page_df) < remaining) break

    # stop if we reached n_max
    if (!is.infinite(n_max) && total_fetched >= n_max) break
  }

  if (length(all_rows) == 0) {
    cli::cli_abort(
      c(
        "no FUNDEB enrollment data found for year {.val {year}}",
        "i" = "the API may not have data for this year"
      )
    )
  }

  df <- dplyr::bind_rows(all_rows)

  # enforce n_max
  if (!is.infinite(n_max) && nrow(df) > n_max) {
    df <- df[seq_len(n_max), ]
  }

  dplyr::as_tibble(df)
}

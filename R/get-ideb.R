# ideb functions
# download and process IDEB data from INEP

#' Get IDEB (Índice de Desenvolvimento da Educação Básica) data
#'
#' @description
#' Downloads and processes IDEB data from INEP in tidy (long) format.
#' IDEB is the main indicator of education quality in Brazil, combining
#' student performance (from SAEB) with grade promotion rates.
#'
#' @param level The geographic level. **Required.**
#'   - `"escola"`: School level
#'   - `"municipio"`: Municipality level
#'   - `"estado"`: State level
#'   - `"regiao"`: Region level (Norte, Nordeste, Sudeste, Sul, Centro-Oeste)
#'   - `"brasil"`: National level
#' @param stage The education stage. **Required.**
#'   - `"anos_iniciais"`: Early elementary (1st-5th grade)
#'   - `"anos_finais"`: Late elementary (6th-9th grade)
#'   - `"ensino_medio"`: High school
#' @param metric The type of data to return. **Required.**
#'   - `"indicador"`: IDEB components (rendimento, nota padronizada, ideb)
#'   - `"aprovacao"`: Approval rates by school year
#'   - `"nota"`: SAEB scores by subject (math/portuguese)
#'   - `"meta"`: IDEB targets/projections
#' @param year Optional. Integer vector of IDEB editions to filter
#'   (e.g., `c(2019, 2021, 2023)`). `NULL` returns all available editions.
#' @param quiet Logical. If `TRUE`, suppresses progress messages.
#'
#' @return A tibble in tidy (long) format. Columns vary by `level` and `metric`:
#'
#' **ID columns** (vary by `level`):
#' - `escola`: `uf_sigla`, `municipio_codigo`, `municipio_nome`, `escola_id`, `escola_nome`, `rede`
#' - `municipio`: `uf_sigla`, `municipio_codigo`, `municipio_nome`, `rede`
#' - `brasil`: `rede`
#' - `estado`: `uf_nome`, `uf_sigla`, `rede`
#' - `regiao`: `regiao`, `rede`
#'
#' **Value columns** (vary by `metric`):
#' - `indicador`: `ano`, `indicador`, `valor`
#' - `aprovacao`: `ano`, `ano_escolar` or `serie` (ensino_medio), `taxa_aprovacao`
#' - `nota`: `ano`, `disciplina`, `nota`
#' - `meta`: `ano`, `meta`
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
#' The function always downloads the most recent IDEB file available from
#' INEP, which contains the full historical series (2005-2023).
#'
#' @section Data source:
#' Official IDEB portal: \url{https://www.gov.br/inep/pt-br/areas-de-atuacao/pesquisas-estatisticas-e-indicadores/ideb}
#'
#' @family IDEB functions
#' @export
#'
#' @examples
#' \dontrun{
#' # school-level IDEB indicators for early elementary
#' ideb <- get_ideb("escola", "anos_iniciais", "indicador")
#'
#' # municipality-level approval rates, only 2021 and 2023
#' aprov <- get_ideb("municipio", "anos_finais", "aprovacao", year = c(2021, 2023))
#'
#' # national IDEB targets
#' metas <- get_ideb("brasil", "ensino_medio", "meta")
#'
#' # state-level SAEB scores
#' notas <- get_ideb("estado", "anos_iniciais", "nota")
#'
#' # region-level IDEB indicators
#' regioes <- get_ideb("regiao", "anos_finais", "indicador")
#' }
get_ideb <- function(level,
                     stage,
                     metric,
                     year = NULL,
                     quiet = FALSE) {
  # backward compatibility: detect old positional usage get_ideb(2023, "escola", "anos_iniciais")
  if (is.numeric(level)) {
    lifecycle::deprecate_warn(
      "1.0.0",
      "get_ideb(year = )",
      details = paste0(
        "The old signature get_ideb(year, level, stage) is deprecated. ",
        "Use get_ideb(level, stage, metric) instead. ",
        "The year parameter is now used to filter IDEB editions."
      )
    )
    old_level <- stage
    old_stage <- metric
    level <- old_level
    stage <- old_stage
    metric <- "indicador"
  }

  # validate arguments
  level <- match.arg(level, c("escola", "municipio", "estado", "regiao", "brasil"))
  stage <- match.arg(stage, c("anos_iniciais", "anos_finais", "ensino_medio"))
  metric <- match.arg(metric, c("indicador", "aprovacao", "nota", "meta"))

  # estado and regiao share the same file
  file_level <- if (level %in% c("estado", "regiao")) "regiao_uf" else level

  # build url and download
  ideb_year <- max(available_years("ideb"))
  url <- build_ideb_url(file_level, stage, ideb_year)
  filename <- basename(url)
  xlsx_path <- cache_path("ideb", filename)

  if (!file.exists(xlsx_path)) {
    if (!quiet) {
      cli::cli_alert_info(
        "downloading IDEB - {.val {stage}} - {.val {level}}..."
      )
    }
    download_inep_file(url, xlsx_path, quiet = quiet)
  } else if (!quiet) {
    cli::cli_alert_success("using cached file")
  }

  if (!quiet) {
    cli::cli_alert_info("reading IDEB data...")
  }

  # determine sheet for brasil/regiao_uf
  sheet <- get_ideb_sheet(file_level, stage)

  # read the xlsx file
  df <- read_ideb_excel(xlsx_path, sheet = sheet)

  # standardize column names
  df <- standardize_names(df)

  # rename ID columns for escola/municipio
  if (level %in% c("escola", "municipio")) {
    rename_map <- c(
      "sg_uf" = "uf_sigla",
      "co_municipio" = "municipio_codigo",
      "no_municipio" = "municipio_nome",
      "id_escola" = "escola_id",
      "no_escola" = "escola_nome"
    )
    for (old_nm in names(rename_map)) {
      if (old_nm %in% names(df)) {
        names(df)[names(df) == old_nm] <- rename_map[[old_nm]]
      }
    }
  }

  # handle regiao/estado unnamed columns and filter rows
  if (level %in% c("regiao", "estado")) {
    df <- fix_regiao_uf_cols(df, level)
  }

  # handle brasil unnamed columns and drop redundant "brasil" column
  if (level == "brasil") {
    df <- fix_brasil_cols(df)
    df$brasil <- NULL
  }

  # remove footer/note rows (rede column is NA for non-data rows)
  rede_col <- if ("rede" %in% names(df)) "rede" else names(df)[2]
  df <- df[!is.na(df[[rede_col]]), ]

  # clean rede values: "Privada (1)" -> "Privada"
  if ("rede" %in% names(df)) {
    df$rede <- sub("\\s*(\\(\\d+\\))+$", "", df$rede)
  }

  # convert vl_* columns to numeric
  df <- clean_ideb_values(df)

  # reshape wide to long
  df <- reshape_ideb(df, level, metric, stage)

  # filter by year if requested
  if (!is.null(year)) {
    df <- df[df$ano %in% year, ]
  }

  # validate data structure
  validate_data(df, "ideb", ideb_year)

  if (!quiet) {
    cli::cli_alert_success(
      "loaded {.val {nrow(df)}} rows and {.val {ncol(df)}} columns"
    )
  }

  df
}

#' Build IDEB download URL
#'
#' @description
#' Internal function to construct IDEB download URLs based on level and stage.
#'
#' @param level Geographic level.
#' @param stage Education stage.
#' @param year The file year (most recent available).
#'
#' @return A character string with the URL.
#'
#' @keywords internal
build_ideb_url <- function(level, stage, year) {
  base_url <- "https://download.inep.gov.br/ideb/resultados"

  # map level names to url format
  level_url <- switch(
    level,
    "escola" = "escolas",
    "municipio" = "municipios",
    "brasil" = "brasil",
    "regiao_uf" = "regioes_ufs"
  )

  # escola/municipio: separate files per stage

  # brasil/regiao_uf: single file with multiple sheets (no stage in filename)
  if (level %in% c("escola", "municipio")) {
    filename <- str_c("divulgacao_", stage, "_", level_url, "_", year, ".xlsx")
  } else {
    filename <- str_c("divulgacao_", level_url, "_ideb_", year, ".xlsx")
  }

  str_c(base_url, "/", filename)
}

#' Get IDEB Excel sheet name
#'
#' @description
#' Internal function to determine which sheet to read for brasil/regiao_uf levels.
#'
#' @param level Geographic level.
#' @param stage Education stage.
#'
#' @return Sheet name (character) or NULL for escola/municipio.
#'
#' @keywords internal
get_ideb_sheet <- function(level, stage) {
  if (level %in% c("escola", "municipio")) {
    return(NULL)
  }

  if (level == "brasil") {
    switch(
      stage,
      "anos_iniciais" = "Brasil (Anos Iniciais)",
      "anos_finais" = "Brasil (Anos Finais)",
      "ensino_medio" = "Brasil (EM)"
    )
  } else if (level == "regiao_uf") {
    switch(
      stage,
      "anos_iniciais" = "UF e Regi\u00f5es (AI)",
      "anos_finais" = "UF e Regi\u00f5es (AF)",
      "ensino_medio" = "UF e Regi\u00f5es (EM)"
    )
  }
}

# Brazilian region names for filtering
ideb_regioes <- c("Norte", "Nordeste", "Sudeste", "Sul", "Centro-Oeste")

# UF name to abbreviation mapping
uf_nome_to_sigla <- c(
  "Rond\u00f4nia" = "RO", "Acre" = "AC", "Amazonas" = "AM",
  "Roraima" = "RR", "Par\u00e1" = "PA", "Amap\u00e1" = "AP",
  "Tocantins" = "TO", "Maranh\u00e3o" = "MA", "Piau\u00ed" = "PI",
  "Cear\u00e1" = "CE", "Rio Grande do Norte" = "RN",
  "Para\u00edba" = "PB", "Pernambuco" = "PE", "Alagoas" = "AL",
  "Sergipe" = "SE", "Bahia" = "BA", "Minas Gerais" = "MG",
  "Esp\u00edrito Santo" = "ES", "Rio de Janeiro" = "RJ",
  "S\u00e3o Paulo" = "SP", "Paran\u00e1" = "PR",
  "Santa Catarina" = "SC", "Rio Grande do Sul" = "RS",
  "Mato Grosso do Sul" = "MS", "Mato Grosso" = "MT",
  "Goi\u00e1s" = "GO", "Distrito Federal" = "DF"
)

#' Fix regiao/estado unnamed columns and filter rows
#'
#' @description
#' Internal function to rename unnamed columns in regiao_uf data and filter
#' to keep only regions or states depending on the requested level.
#'
#' @param df Data frame with regiao_uf data.
#' @param level `"regiao"` or `"estado"`.
#'
#' @return Data frame with renamed columns, filtered to the requested level.
#'
#' @keywords internal
fix_regiao_uf_cols <- function(df, level) {
  nms <- names(df)
  if (length(nms) >= 2) {
    id_cols <- nms[!grepl("^vl_", nms)]
    if (length(id_cols) >= 2) {
      # temporarily name first column for filtering
      col1 <- id_cols[1]
      names(df)[names(df) == id_cols[2]] <- "rede"

      if (level == "regiao") {
        df <- df[df[[col1]] %in% ideb_regioes, ]
        names(df)[names(df) == col1] <- "regiao"
      } else {
        df <- df[!df[[col1]] %in% ideb_regioes & !is.na(df[[col1]]), ]
        # fix abbreviated state names
        df[[col1]] <- sub("^R\\. G\\. do Norte$", "Rio Grande do Norte", df[[col1]])
        df[[col1]] <- sub("^R\\. G\\. do Sul$", "Rio Grande do Sul", df[[col1]])
        df[[col1]] <- sub("^M\\. G\\. do Sul$", "Mato Grosso do Sul", df[[col1]])
        names(df)[names(df) == col1] <- "uf_nome"
        # insert uf_sigla right after uf_nome
        df$uf_sigla <- unname(uf_nome_to_sigla[df$uf_nome])
        col_order <- names(df)
        idx <- which(col_order == "uf_nome")
        col_order <- append(col_order[col_order != "uf_sigla"], "uf_sigla", after = idx)
        df <- df[, col_order]
      }
    }
  }
  df
}

#' Fix brasil unnamed columns
#'
#' @description
#' Internal function to rename columns in brasil data.
#'
#' @param df Data frame with brasil data.
#'
#' @return Data frame with renamed columns.
#'
#' @keywords internal
fix_brasil_cols <- function(df) {
  nms <- names(df)
  id_cols <- nms[!grepl("^vl_", nms)]
  if (length(id_cols) >= 2) {
    names(df)[names(df) == id_cols[1]] <- "brasil"
    names(df)[names(df) == id_cols[2]] <- "rede"
  } else if (length(id_cols) == 1) {
    names(df)[names(df) == id_cols[1]] <- "rede"
  }
  df
}

#' Reshape IDEB data from wide to long format
#'
#' @description
#' Internal function to transform IDEB data from wide format (one column per
#' year/metric) to tidy long format, filtered by the requested metric type.
#'
#' @param df Data frame with IDEB data (wide format, standardized names).
#' @param level Geographic level (determines ID columns).
#' @param metric Type of metric to extract.
#'
#' @return A tibble in long format.
#'
#' @keywords internal
reshape_ideb <- function(df, level, metric, stage = NULL) {
  # identify ID columns (non vl_* columns)
  all_cols <- names(df)
  vl_cols <- grep("^vl_", all_cols, value = TRUE)
  id_cols <- setdiff(all_cols, vl_cols)

  # select columns by metric pattern
  col_patterns <- switch(
    metric,
    "indicador" = c(
      "Indicador de Rendimento" = "^vl_indicador_rend_",
      "Nota M\u00e9dia Padronizada" = "^vl_nota_media_",
      "IDEB" = "^vl_observado_"
    ),
    "aprovacao" = "^vl_aprovacao_",
    "nota" = c(
      "matematica" = "^vl_nota_matematica_",
      "portugues" = "^vl_nota_portugues_"
    ),
    "meta" = "^vl_projecao_"
  )

  if (metric == "indicador") {
    result <- reshape_indicador(df, id_cols, col_patterns)
  } else if (metric == "aprovacao") {
    result <- reshape_aprovacao(df, id_cols, stage)
  } else if (metric == "nota") {
    result <- reshape_nota(df, id_cols, col_patterns)
  } else if (metric == "meta") {
    result <- reshape_meta(df, id_cols)
  }

  dplyr::as_tibble(result)
}

#' @keywords internal
reshape_indicador <- function(df, id_cols, patterns) {
  results <- list()

  for (indicador_name in names(patterns)) {
    pattern <- patterns[[indicador_name]]
    cols <- grep(pattern, names(df), value = TRUE)
    if (length(cols) == 0) next

    # extract years from column names
    anos <- as.integer(str_extract(cols, "[0-9]{4}"))

    sub_df <- df[, c(id_cols, cols), drop = FALSE]

    long <- tidyr::pivot_longer(
      sub_df,
      cols = dplyr::all_of(cols),
      names_to = "col_orig",
      values_to = "valor"
    )

    long$ano <- as.integer(str_extract(long$col_orig, "[0-9]{4}"))
    long$indicador <- indicador_name
    long$col_orig <- NULL

    results[[indicador_name]] <- long
  }

  out <- dplyr::bind_rows(results)
  out <- out[, c(id_cols, "ano", "indicador", "valor")]
  out[order(out$ano, out$indicador), ]
}

#' @keywords internal
reshape_aprovacao <- function(df, id_cols, stage) {
  cols <- grep("^vl_aprovacao_", names(df), value = TRUE)
  if (length(cols) == 0) {
    return(data.frame())
  }

  sub_df <- df[, c(id_cols, cols), drop = FALSE]

  long <- tidyr::pivot_longer(
    sub_df,
    cols = dplyr::all_of(cols),
    names_to = "col_orig",
    values_to = "taxa_aprovacao"
  )

  # extract year (4 digits after "vl_aprovacao_")
  long$ano <- as.integer(str_extract(long$col_orig, "(?<=aprovacao_)[0-9]{4}"))

  # extract suffix after year
  suffix <- str_remove(long$col_orig, "^vl_aprovacao_[0-9]{4}_?")

  # map suffix to ano_escolar based on stage
  # anos_iniciais: _si_4 = "1\u00ba ao 5\u00ba ano", _1=1\u00ba, _2=2\u00ba, _3=3\u00ba, _4=4\u00ba, _si=5\u00ba
  # anos_finais:   _si_4 = "6\u00ba ao 9\u00ba ano", _1=6\u00ba, _2=7\u00ba, _3=8\u00ba, _4=9\u00ba
  # ensino_medio:  _si_4 = "Total",  _1=1\u00aa, _2=2\u00aa, _3=3\u00aa, _4=4\u00aa
  if (stage == "anos_iniciais") {
    long$ano_escolar <- dplyr::case_when(
      suffix == "si_4" ~ "1\u00ba ao 5\u00ba ano",
      suffix == "si"   ~ "5\u00ba",
      suffix == "1"    ~ "1\u00ba",
      suffix == "2"    ~ "2\u00ba",
      suffix == "3"    ~ "3\u00ba",
      suffix == "4"    ~ "4\u00ba",
      TRUE ~ suffix
    )
    col_name <- "ano_escolar"
  } else if (stage == "anos_finais") {
    long$ano_escolar <- dplyr::case_when(
      suffix == "si_4" ~ "6\u00ba ao 9\u00ba ano",
      suffix == "1"    ~ "6\u00ba",
      suffix == "2"    ~ "7\u00ba",
      suffix == "3"    ~ "8\u00ba",
      suffix == "4"    ~ "9\u00ba",
      TRUE ~ suffix
    )
    col_name <- "ano_escolar"
  } else {
    # ensino_medio
    long$serie <- dplyr::case_when(
      suffix == "si_4" ~ "Total",
      suffix == "1"    ~ "1\u00aa",
      suffix == "2"    ~ "2\u00aa",
      suffix == "3"    ~ "3\u00aa",
      suffix == "4"    ~ "4\u00aa",
      TRUE ~ suffix
    )
    col_name <- "serie"
  }

  long$col_orig <- NULL
  long <- long[, c(id_cols, "ano", col_name, "taxa_aprovacao")]
  long[order(long$ano, long[[col_name]]), ]
}

#' @keywords internal
reshape_nota <- function(df, id_cols, patterns) {
  results <- list()

  for (disciplina_name in names(patterns)) {
    pattern <- patterns[[disciplina_name]]
    cols <- grep(pattern, names(df), value = TRUE)
    if (length(cols) == 0) next

    sub_df <- df[, c(id_cols, cols), drop = FALSE]

    long <- tidyr::pivot_longer(
      sub_df,
      cols = dplyr::all_of(cols),
      names_to = "col_orig",
      values_to = "nota"
    )

    long$ano <- as.integer(str_extract(long$col_orig, "[0-9]{4}"))
    long$disciplina <- disciplina_name
    long$col_orig <- NULL

    results[[disciplina_name]] <- long
  }

  out <- dplyr::bind_rows(results)
  out <- out[, c(id_cols, "ano", "disciplina", "nota")]
  out[order(out$ano, out$disciplina), ]
}

#' @keywords internal
reshape_meta <- function(df, id_cols) {
  cols <- grep("^vl_projecao_", names(df), value = TRUE)
  if (length(cols) == 0) {
    return(data.frame())
  }

  sub_df <- df[, c(id_cols, cols), drop = FALSE]

  long <- tidyr::pivot_longer(
    sub_df,
    cols = dplyr::all_of(cols),
    names_to = "col_orig",
    values_to = "meta"
  )

  long$ano <- as.integer(str_extract(long$col_orig, "[0-9]{4}"))
  long$col_orig <- NULL
  long <- long[, c(id_cols, "ano", "meta")]
  long[order(long$ano), ]
}

#' Clean IDEB numeric columns
#'
#' @description
#' Internal function to convert `vl_*` columns from character to numeric.
#' Handles `"-"` and `"ND"` as `NA`, and replaces comma decimal separators
#' with dots.
#'
#' @param df A data frame with IDEB data.
#'
#' @return The data frame with `vl_*` columns as numeric.
#'
#' @keywords internal
clean_ideb_values <- function(df) {
  vl_cols <- grep("^vl_", names(df), value = TRUE)

  for (col in vl_cols) {
    if (is.character(df[[col]])) {
      values <- df[[col]]
      values[values %in% c("-", "ND")] <- NA_character_
      values <- gsub(",", ".", values)
      df[[col]] <- suppressWarnings(as.numeric(values))
    }
  }

  df
}

#' Read IDEB Excel file
#'
#' @description
#' Internal function to read IDEB Excel files.
#'
#' @param file Path to the Excel file.
#' @param sheet Sheet name to read (NULL for first sheet).
#'
#' @return A tibble with the data.
#'
#' @keywords internal
read_ideb_excel <- function(file, sheet = NULL) {
  if (!requireNamespace("readxl", quietly = TRUE)) {
    cli::cli_abort(
      c(
        "package {.pkg readxl} is required to read IDEB Excel files",
        "i" = "install with: {.code install.packages('readxl')}"
      )
    )
  }

  # IDEB Excel files have 9 header rows before the actual column names
  df <- readxl::read_excel(file, sheet = sheet, skip = 9, col_types = "text")

  df
}

#' Get IDEB historical series
#'
#' @description
#' `r lifecycle::badge("deprecated")`
#'
#' `get_ideb_series()` is deprecated because the new `get_ideb()` already
#' returns data in long format with all historical editions.
#' Use `get_ideb(level, stage, metric)` instead.
#'
#' @param years Vector of years to include (default: all available).
#' @param level The aggregation level.
#' @param stage The education stage.
#' @param uf Optional. Filter by state.
#' @param quiet Logical. If `TRUE`, suppresses progress messages.
#'
#' @return A tibble with IDEB data.
#'
#' @family IDEB functions
#' @export
#'
#' @examples
#' \dontrun{
#' # deprecated: use get_ideb() instead
#' ideb <- get_ideb("municipio", "anos_iniciais", "indicador")
#' }
get_ideb_series <- function(years = NULL,
                            level = c("escola", "municipio"),
                            stage = c("anos_iniciais", "anos_finais", "ensino_medio"),
                            uf = NULL,
                            quiet = FALSE) {
  lifecycle::deprecate_warn(
    "1.0.0",
    "get_ideb_series()",
    "get_ideb()",
    details = paste0(
      "get_ideb() now returns data in long format with all editions. ",
      "Use get_ideb(level, stage, metric, year) instead."
    )
  )

  level <- match.arg(level)
  stage <- match.arg(stage)

  get_ideb(
    level = level,
    stage = stage,
    metric = "indicador",
    year = years,
    quiet = quiet
  )
}

#' List available IDEB data
#'
#' @description
#' Lists the IDEB data combinations available for download.
#'
#' @return A tibble with available IDEB datasets (level, stage, metric).
#'
#' @family IDEB functions
#' @export
#'
#' @examples
#' list_ideb_available()
list_ideb_available <- function() {
  levels <- c("escola", "municipio", "estado", "regiao", "brasil")
  stages <- c("anos_iniciais", "anos_finais", "ensino_medio")
  metrics <- c("indicador", "aprovacao", "nota", "meta")

  tidyr::expand_grid(
    level = levels,
    stage = stages,
    metric = metrics
  ) |>
    dplyr::arrange(.data$level, .data$stage, .data$metric)
}

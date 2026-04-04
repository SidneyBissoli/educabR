# validation utilities for educabR
# validates data after reading from INEP files

#' Validate downloaded data structure
#'
#' @description
#' Internal function to validate that downloaded data has the expected
#' structure. Issues warnings for potential problems and errors for
#' critical issues.
#'
#' @param data A tibble with the downloaded data.
#' @param dataset The dataset name ("enem", "enem_itens", "ideb", "censo_escolar").
#' @param year The year of the data.
#'
#' @return The input data (invisibly), or aborts with an error.
#'
#' @keywords internal
validate_data <- function(data, dataset, year) {
  # check if data is empty
  if (nrow(data) == 0) {
    cli::cli_abort(
      c(
        "downloaded file for {.val {dataset}} {.val {year}} contains no rows",
        "i" = "the file may be corrupted or the format may have changed",
        "i" = "try clearing the cache with {.fun clear_cache} and downloading again"
      )
    )
  }

  # check minimum number of columns
  if (ncol(data) < 3) {
    cli::cli_abort(
      c(
        "downloaded file for {.val {dataset}} {.val {year}} has only {.val {ncol(data)}} column(s)",
        "i" = "the file may be corrupted or the delimiter may have changed",
        "i" = "try clearing the cache with {.fun clear_cache} and downloading again"
      )
    )
  }

  # dataset-specific validation

  switch(
    dataset,
    "enem" = validate_enem(data, year),
    "enem_participantes" = validate_enem_participantes(data, year),
    "enem_itens" = validate_enem_itens(data, year),
    "saeb" = validate_saeb(data, year),
    "censo_superior" = validate_censo_superior(data, year),
    "enade" = validate_enade(data, year),
    "encceja" = validate_encceja(data, year),
    "enem_escola" = validate_enem_escola(data, year),
    "idd" = validate_idd(data, year),
    "cpc" = validate_cpc(data, year),
    "igc" = validate_igc(data, year),
    "capes" = validate_capes(data, year),
    "ideb" = validate_ideb(data, year),
    "fundeb" = validate_fundeb(data, year),
    "fundeb_enrollment" = validate_fundeb_enrollment(data, year),
    "censo_escolar" = validate_censo_escolar(data, year)
  )

  invisible(data)
}

# enem: check for score columns
validate_enem <- function(data, year) {
  score_cols <- names(data)[str_detect(names(data), "^nu_nota_")]

  if (length(score_cols) == 0) {
    cli::cli_warn(
      c(
        "no score columns found in ENEM {.val {year}} data",
        "i" = "expected columns starting with {.val nu_nota_}",
        "i" = "column names found: {.val {head(names(data), 10)}}",
        "i" = "{.fun enem_summary} will not work with this data"
      )
    )
  }
}

# enem_participantes (2024+): check for demographic columns, no score expected
validate_enem_participantes <- function(data, year) {
  expected <- c("nu_inscricao", "tp_sexo")
  found <- expected[expected %in% names(data)]

  if (length(found) == 0) {
    cli::cli_warn(
      c(
        "ENEM {.val {year}} participant data may have an unexpected structure",
        "i" = "expected columns like {.val {expected}}",
        "i" = "column names found: {.val {head(names(data), 10)}}"
      )
    )
  }
}

# enem_itens: basic structure check
validate_enem_itens <- function(data, year) {
  expected <- c("co_item", "sg_area")
  found <- expected[expected %in% names(data)]

  if (length(found) == 0) {
    cli::cli_warn(
      c(
        "ENEM {.val {year}} item data may have an unexpected structure",
        "i" = "expected columns like {.val {expected}}",
        "i" = "column names found: {.val {head(names(data), 10)}}"
      )
    )
  }
}

# saeb: check for student or school identifiers
validate_saeb <- function(data, year) {
  expected <- c("id_aluno", "id_escola", "id_saeb", "id_educacao_infantil",
                "nu_ano_saeb")
  found <- expected[expected %in% names(data)]

  if (length(found) == 0) {
    cli::cli_warn(
      c(
        "SAEB {.val {year}} data may have an unexpected structure",
        "i" = "expected columns like {.val {expected}}",
        "i" = "column names found: {.val {head(names(data), 10)}}"
      )
    )
  }
}

# enade: check for year and score columns
validate_enade <- function(data, year) {
  expected <- c("nu_ano", "co_curso", "co_ies", "nt_ger", "nt_fg", "nt_ce")
  found <- expected[expected %in% names(data)]

  if (length(found) == 0) {
    cli::cli_warn(
      c(
        "ENADE {.val {year}} data may have an unexpected structure",
        "i" = "expected columns like {.val {expected}}",
        "i" = "column names found: {.val {head(names(data), 10)}}"
      )
    )
  }
}

# encceja: check for participant identifiers
validate_encceja <- function(data, year) {
  expected <- c("nu_inscricao", "nu_ano", "tp_sexo", "co_municipio_residencia")
  found <- expected[expected %in% names(data)]

  if (length(found) == 0) {
    cli::cli_warn(
      c(
        "ENCCEJA {.val {year}} data may have an unexpected structure",
        "i" = "expected columns like {.val {expected}}",
        "i" = "column names found: {.val {head(names(data), 10)}}"
      )
    )
  }
}

# enem_escola: check for school and score columns
validate_enem_escola <- function(data, year) {
  expected <- c("co_escola_educacenso", "no_escola", "nu_ano",
                "nu_media_cn", "nu_media_ch", "nu_media_lc", "nu_media_mt")
  found <- expected[expected %in% names(data)]

  if (length(found) == 0) {
    cli::cli_warn(
      c(
        "ENEM por Escola data may have an unexpected structure",
        "i" = "expected columns like {.val {expected}}",
        "i" = "column names found: {.val {head(names(data), 10)}}"
      )
    )
  }
}

# idd: check for course and IDD score columns
validate_idd <- function(data, year) {
  expected <- c("co_curso", "co_ies", "idd_continuo", "idd_faixa",
                "no_curso", "co_grupo")
  found <- expected[expected %in% names(data)]

  if (length(found) == 0) {
    cli::cli_warn(
      c(
        "IDD {.val {year}} data may have an unexpected structure",
        "i" = "expected columns like {.val {expected}}",
        "i" = "column names found: {.val {head(names(data), 10)}}"
      )
    )
  }
}

# cpc: check for course and CPC score columns
validate_cpc <- function(data, year) {
  expected <- c("co_curso", "co_ies", "cpc_continuo", "cpc_faixa",
                "no_curso", "co_grupo")
  found <- expected[expected %in% names(data)]

  if (length(found) == 0) {
    cli::cli_warn(
      c(
        "CPC {.val {year}} data may have an unexpected structure",
        "i" = "expected columns like {.val {expected}}",
        "i" = "column names found: {.val {head(names(data), 10)}}"
      )
    )
  }
}

# igc: check for institution and IGC score columns
validate_igc <- function(data, year) {
  expected <- c("co_ies", "no_ies", "igc_continuo", "igc_faixa",
                "sigla_ies", "co_mantenedora")
  found <- expected[expected %in% names(data)]

  if (length(found) == 0) {
    cli::cli_warn(
      c(
        "IGC {.val {year}} data may have an unexpected structure",
        "i" = "expected columns like {.val {expected}}",
        "i" = "column names found: {.val {head(names(data), 10)}}"
      )
    )
  }
}

# capes: check for program or student identifiers
validate_capes <- function(data, year) {
  expected <- c("cd_programa_ies", "nm_programa", "sg_entidade_ensino",
                "nm_entidade_ensino", "an_base", "cd_conceito_curso")
  found <- expected[expected %in% names(data)]

  if (length(found) == 0) {
    cli::cli_warn(
      c(
        "CAPES {.val {year}} data may have an unexpected structure",
        "i" = "expected columns like {.val {expected}}",
        "i" = "column names found: {.val {head(names(data), 10)}}"
      )
    )
  }
}

# ideb: check for tidy long format columns
validate_ideb <- function(data, year) {
  if (!"ano" %in% names(data)) {
    cli::cli_warn(
      c(
        "column {.val ano} not found in IDEB {.val {year}} data",
        "i" = "data may not have been reshaped correctly",
        "i" = "column names found: {.val {head(names(data), 10)}}"
      )
    )
  }
}

# censo_superior: check for institution or course identifiers
validate_censo_superior <- function(data, year) {
  expected <- c("co_ies", "co_curso", "co_aluno", "co_docente",
                "no_ies", "no_curso")
  found <- expected[expected %in% names(data)]

  if (length(found) == 0) {
    cli::cli_warn(
      c(
        "Higher Education Census {.val {year}} data may have an unexpected structure",
        "i" = "expected columns like {.val {expected}}",
        "i" = "column names found: {.val {head(names(data), 10)}}"
      )
    )
  }
}

# fundeb distribution: check for tidy columns
validate_fundeb <- function(data, year) {
  expected <- c("uf", "estados", "mes_ano", "origem", "destino", "valor")
  found <- expected[expected %in% names(data)]

  if (length(found) == 0) {
    cli::cli_warn(
      c(
        "FUNDEB distribution {.val {year}} data may have an unexpected structure",
        "i" = "expected columns like {.val {expected}}",
        "i" = "column names found: {.val {head(names(data), 10)}}"
      )
    )
  }
}

# fundeb enrollment: check for census/enrollment columns
validate_fundeb_enrollment <- function(data, year) {
  expected <- c("ano_censo", "uf", "qtd_matricula", "tipo_rede_educacao",
                "descricao_tipo_educacao")
  found <- expected[expected %in% names(data)]

  if (length(found) == 0) {
    cli::cli_warn(
      c(
        "FUNDEB enrollment {.val {year}} data may have an unexpected structure",
        "i" = "expected columns like {.val {expected}}",
        "i" = "column names found: {.val {head(names(data), 10)}}"
      )
    )
  }
}

# censo_escolar: check for UF column
validate_censo_escolar <- function(data, year) {
  if (!"co_uf" %in% names(data)) {
    cli::cli_warn(
      c(
        "column {.val co_uf} not found in School Census {.val {year}} data",
        "i" = "state filtering will not work",
        "i" = "column names found: {.val {head(names(data), 10)}}"
      )
    )
  }
}

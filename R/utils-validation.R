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
    "ideb" = validate_ideb(data, year),
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

# ideb: check for UF and index columns
validate_ideb <- function(data, year) {
  uf_cols <- names(data)[str_detect(names(data), "uf|estado")]

  if (length(uf_cols) == 0) {
    cli::cli_warn(
      c(
        "no UF/state column found in IDEB {.val {year}} data",
        "i" = "state filtering will not work",
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

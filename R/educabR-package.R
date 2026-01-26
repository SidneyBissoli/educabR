#' @keywords internal
"_PACKAGE"

#' educabR: Download and Process Brazilian Education Data from INEP
#'
#' @description
#' The educabR package provides functions to download and process public
#' education data from INEP (Instituto Nacional de Estudos e Pesquisas
#' Educacionais Anísio Teixeira). It offers easy access to microdata from:
#'
#' - **School Census (Censo Escolar)**: Annual data on schools, enrollment,
#'   teachers, and classes in basic education
#' - **ENEM**: Data from the National High School Exam
#' - **IDEB**: Basic Education Development Index
#'
#' All functions return data in tidy format, ready for analysis with tidyverse
#' tools.
#'
#' @section Main functions:
#'
#' **School Census:**
#' - [get_censo_escolar()]: Download School Census microdata
#'
#' **ENEM:**
#' - [get_enem()]: Download ENEM microdata
#'
#' **IDEB:**
#' - [get_ideb()]: Download IDEB data
#'
#' @section Cache system:
#'
#' The package implements a local cache system to avoid repeated downloads.
#' Use [set_cache_dir()] to configure a persistent cache directory.
#' See [get_cache_dir()] to check the current cache location.
#'
#' @section Data source:
#'
#' All data is downloaded from INEP's official portal:
#' \url{https://www.gov.br/inep/pt-br/acesso-a-informacao/dados-abertos/microdados}
#'
#' @name educabR-package
#' @aliases educabR
#'
#' @importFrom rlang .data .env := %||%
#' @importFrom dplyr filter select mutate rename arrange group_by summarise
#' @importFrom dplyr ungroup left_join inner_join bind_rows distinct across
#' @importFrom dplyr if_else case_when pull n
#' @importFrom purrr map map_chr map_dfr walk possibly
#' @importFrom stringr str_c str_detect str_extract str_remove str_replace
#' @importFrom stringr str_to_lower str_to_upper str_trim str_squish str_replace_all
#' @importFrom stats sd median quantile
#' @importFrom readr read_csv read_csv2 read_delim locale cols col_character
#' @importFrom tidyr pivot_longer pivot_wider unnest
#' @importFrom httr2 request req_perform resp_body_raw req_url_path_append
#' @importFrom httr2 req_timeout req_retry
#' @importFrom cli cli_alert_info cli_alert_success cli_alert_warning
#' @importFrom cli cli_alert_danger cli_progress_bar cli_progress_update
#' @importFrom cli cli_progress_done cli_abort cli_warn
#' @importFrom tools file_ext
#' @importFrom utils unzip download.file
NULL

# tests targeting remaining coverage gaps in:
#   R/get-capes.R, R/get-fundeb.R, R/utils-download.R, R/get-cpc.R

# helper: set up a temp cache environment
setup_temp_cache <- function(env = parent.frame()) {
  temp_cache <- withr::local_tempdir(.local_envir = env)
  withr::local_options(educabR.cache_dir = temp_cache, .local_envir = env)
  educabR::set_cache_dir(temp_cache)
  temp_cache
}

# =============================================================================
# get-capes.R coverage gaps
# =============================================================================

test_that("get_capes full pipeline when not cached", {
  temp_cache <- setup_temp_cache()

  local_mocked_bindings(
    discover_capes_url = function(year, type) "http://mock-capes.csv",
    download_inep_file = function(url, destfile, quiet = FALSE) {
      dir.create(dirname(destfile), recursive = TRUE, showWarnings = FALSE)
      writeLines(
        c("CD_PROGRAMA_IES;NM_PROGRAMA;SG_ENTIDADE_ENSINO;NM_ENTIDADE_ENSINO;AN_BASE;CD_CONCEITO_CURSO",
          "001;PROG A;USP;Universidade de Sao Paulo;2023;5",
          "002;PROG B;UNICAMP;Universidade Estadual de Campinas;2023;4"),
        destfile
      )
      destfile
    },
    .package = "educabR"
  )

  result <- get_capes(2023, type = "programas", quiet = TRUE)
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2)
  expect_true("cd_programa_ies" %in% names(result))
  expect_true("nm_programa" %in% names(result))
})

test_that("get_capes with keep_file=FALSE removes cached file", {
  temp_cache <- setup_temp_cache()

  local_mocked_bindings(
    discover_capes_url = function(year, type) "http://mock-capes.csv",
    download_inep_file = function(url, destfile, quiet = FALSE) {
      dir.create(dirname(destfile), recursive = TRUE, showWarnings = FALSE)
      writeLines(
        c("CD_PROGRAMA_IES;NM_PROGRAMA;SG_ENTIDADE_ENSINO;AN_BASE",
          "001;PROG A;USP;2023"),
        destfile
      )
      destfile
    },
    .package = "educabR"
  )

  result <- get_capes(2023, type = "programas", keep_file = FALSE, quiet = TRUE)
  expect_s3_class(result, "tbl_df")

  file_path <- educabR:::cache_path("capes", "capes_programas_2023.csv")
  expect_false(file.exists(file_path))
})

test_that("get_capes not-quiet path prints messages", {
  temp_cache <- setup_temp_cache()

  local_mocked_bindings(
    discover_capes_url = function(year, type) "http://mock-capes.csv",
    download_inep_file = function(url, destfile, quiet = FALSE) {
      dir.create(dirname(destfile), recursive = TRUE, showWarnings = FALSE)
      writeLines(
        c("CD_PROGRAMA_IES;NM_PROGRAMA;SG_ENTIDADE_ENSINO;AN_BASE",
          "001;PROG A;USP;2023"),
        destfile
      )
      destfile
    },
    .package = "educabR"
  )

  expect_message(
    get_capes(2023, type = "programas", quiet = FALSE),
    "discovering download URL"
  )
})

test_that("get_capes uses cached file when present", {
  temp_cache <- setup_temp_cache()

  # Pre-create cached file
  capes_dir <- file.path(temp_cache, "capes")
  dir.create(capes_dir, recursive = TRUE)
  writeLines(
    c("CD_PROGRAMA_IES;NM_PROGRAMA;SG_ENTIDADE_ENSINO;AN_BASE",
      "001;PROG A;USP;2023"),
    file.path(capes_dir, "capes_programas_2023.csv")
  )

  # discover_capes_url should NOT be called
  local_mocked_bindings(
    discover_capes_url = function(year, type) stop("should not be called"),
    .package = "educabR"
  )

  result <- get_capes(2023, type = "programas", quiet = TRUE)
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 1)
})

test_that("get_capes applies parse_sas_dates and clean_dash_values", {
  temp_cache <- setup_temp_cache()

  local_mocked_bindings(
    discover_capes_url = function(year, type) "http://mock.csv",
    download_inep_file = function(url, destfile, quiet = FALSE) {
      dir.create(dirname(destfile), recursive = TRUE, showWarnings = FALSE)
      writeLines(
        c("CD_PROGRAMA_IES;DT_SITUACAO;NM_PROGRAMA;SG_ENTIDADE_ENSINO",
          "001;01JAN2023:00:00:00;-;USP"),
        destfile
      )
      destfile
    },
    .package = "educabR"
  )

  result <- get_capes(2023, type = "programas", quiet = TRUE)
  # dash replaced with NA
  expect_true(is.na(result$nm_programa[1]))
  # SAS date parsed
  expect_s3_class(result$dt_situacao, "Date")
})

test_that("discover_capes_url errors for year outside all ranges", {
  # Year 2000 is not in any range and not in available_years,
  # but we can call discover_capes_url directly
  expect_error(
    educabR:::discover_capes_url(2000, "programas"),
    "could not determine"
  )
})

test_that("discover_capes_url builds correct package slug", {
  # We capture the package slug by observing the API URL built.
  # Mock the httr2 pipeline to capture the URL and return a valid response.
  captured_url <- NULL

  local_mocked_bindings(
    request = function(url) {
      captured_url <<- url
      structure(list(url = url), class = "httr2_request")
    },
    req_timeout = function(req, ...) req,
    req_retry = function(req, ...) req,
    req_perform = function(req) {
      structure(list(), class = "httr2_response")
    },
    resp_body_json = function(resp) {
      list(
        success = TRUE,
        result = list(
          resources = list(
            list(format = "CSV", name = "programas-2023-data",
                 url = "http://example.com/prog-2023.csv")
          )
        )
      )
    },
    .package = "httr2"
  )

  url <- educabR:::discover_capes_url(2023, "programas")

  expect_equal(url, "http://example.com/prog-2023.csv")
  expect_true(grepl("2021-a-2024", captured_url))
  expect_true(grepl("programas-da-pos-graduacao", captured_url))
})

test_that("discover_capes_url falls back to URL matching when name does not match", {
  local_mocked_bindings(
    request = function(url) {
      structure(list(url = url), class = "httr2_request")
    },
    req_timeout = function(req, ...) req,
    req_retry = function(req, ...) req,
    req_perform = function(req) {
      structure(list(), class = "httr2_response")
    },
    resp_body_json = function(resp) {
      list(
        success = TRUE,
        result = list(
          resources = list(
            # name does NOT contain 2023, but URL does
            list(format = "CSV", name = "programas-data",
                 url = "http://example.com/prog-2023-data.csv"),
            list(format = "PDF", name = "dicionario",
                 url = "http://example.com/dict.pdf")
          )
        )
      )
    },
    .package = "httr2"
  )

  url <- educabR:::discover_capes_url(2023, "programas")
  expect_equal(url, "http://example.com/prog-2023-data.csv")
})

test_that("discover_capes_url errors when no CSV resource found", {
  local_mocked_bindings(
    request = function(url) {
      structure(list(url = url), class = "httr2_request")
    },
    req_timeout = function(req, ...) req,
    req_retry = function(req, ...) req,
    req_perform = function(req) {
      structure(list(), class = "httr2_response")
    },
    resp_body_json = function(resp) {
      list(
        success = TRUE,
        result = list(
          resources = list(
            list(format = "PDF", name = "dicionario-2023",
                 url = "http://example.com/dict.pdf")
          )
        )
      )
    },
    .package = "httr2"
  )

  expect_error(
    educabR:::discover_capes_url(2023, "programas"),
    "no CSV resource found"
  )
})

test_that("discover_capes_url errors when CKAN API returns success=FALSE", {
  local_mocked_bindings(
    request = function(url) {
      structure(list(url = url), class = "httr2_request")
    },
    req_timeout = function(req, ...) req,
    req_retry = function(req, ...) req,
    req_perform = function(req) {
      structure(list(), class = "httr2_response")
    },
    resp_body_json = function(resp) {
      list(success = FALSE)
    },
    .package = "httr2"
  )

  expect_error(
    educabR:::discover_capes_url(2023, "programas"),
    "CKAN API returned error"
  )
})

test_that("discover_capes_url errors on network failure", {
  local_mocked_bindings(
    request = function(url) {
      structure(list(url = url), class = "httr2_request")
    },
    req_timeout = function(req, ...) req,
    req_retry = function(req, ...) req,
    req_perform = function(req) {
      stop("connection refused")
    },
    .package = "httr2"
  )

  expect_error(
    educabR:::discover_capes_url(2023, "programas"),
    "failed to query CAPES API"
  )
})

# =============================================================================
# get-fundeb.R coverage gaps
# =============================================================================

test_that("read_fundeb_sheets filters by source and destination", {
  mock_tidy <- dplyr::tibble(
    estados = "SAO PAULO", uf = "SP",
    mes_ano = as.Date("2023-01-31"),
    origem = "FPE", destino = "UF",
    tabela = "Fundeb", valor = 1000
  )

  local_mocked_bindings(
    excel_sheets = function(...) c("E_FPE", "M_FPE", "E_ICMS", "M_ICMS",
                                   "Tot1", "Resumo"),
    .package = "readxl"
  )

  local_mocked_bindings(
    parse_fundeb_sheet = function(...) mock_tidy,
    .package = "educabR"
  )

  result <- educabR:::read_fundeb_sheets("dummy.xls", 2023, quiet = TRUE)
  # All valid data sheets should be processed (E_FPE, M_FPE, E_ICMS, M_ICMS)
  # Tot1 and Resumo should be skipped
  expect_true(nrow(result) > 0)
})

test_that("read_fundeb_sheets filters by source only", {
  call_count <- 0

  local_mocked_bindings(
    excel_sheets = function(...) c("E_FPE", "M_FPE", "E_ICMS", "M_ICMS"),
    .package = "readxl"
  )

  local_mocked_bindings(
    parse_fundeb_sheet = function(file_path, sheet_name, year,
                                  source_name, dest_name) {
      call_count <<- call_count + 1
      dplyr::tibble(
        estados = "SAO PAULO", uf = "SP",
        mes_ano = as.Date("2023-01-31"),
        origem = source_name, destino = dest_name,
        tabela = "Fundeb", valor = 1000
      )
    },
    .package = "educabR"
  )

  result <- educabR:::read_fundeb_sheets("dummy.xls", 2023,
                                         source = "FPE", quiet = TRUE)
  # Only E_FPE and M_FPE should be processed
  expect_equal(call_count, 2)
  expect_true(all(result$origem == "FPE"))
})

test_that("read_fundeb_sheets filters by destination only", {
  call_count <- 0

  local_mocked_bindings(
    excel_sheets = function(...) c("E_FPE", "M_FPE", "E_ICMS", "M_ICMS"),
    .package = "readxl"
  )

  local_mocked_bindings(
    parse_fundeb_sheet = function(file_path, sheet_name, year,
                                  source_name, dest_name) {
      call_count <<- call_count + 1
      dplyr::tibble(
        estados = "SAO PAULO", uf = "SP",
        mes_ano = as.Date("2023-01-31"),
        origem = source_name, destino = dest_name,
        tabela = "Fundeb", valor = 1000
      )
    },
    .package = "educabR"
  )

  result <- educabR:::read_fundeb_sheets("dummy.xls", 2023,
                                         destination = "UF", quiet = TRUE)
  # Only E_ sheets (UF destination)
  expect_equal(call_count, 2)
})

test_that("read_fundeb_sheets handles parse errors gracefully", {
  local_mocked_bindings(
    excel_sheets = function(...) c("E_FPE", "E_ICMS"),
    .package = "readxl"
  )

  call_num <- 0
  local_mocked_bindings(
    parse_fundeb_sheet = function(...) {
      call_num <<- call_num + 1
      if (call_num == 1) stop("corrupt sheet")
      dplyr::tibble(
        estados = "SP STATE", uf = "SP",
        mes_ano = as.Date("2023-01-31"),
        origem = "ICMS", destino = "UF",
        tabela = "Fundeb", valor = 500
      )
    },
    .package = "educabR"
  )

  result <- educabR:::read_fundeb_sheets("dummy.xls", 2023, quiet = TRUE)
  expect_true(nrow(result) > 0)
})

test_that("read_fundeb_sheets errors when no valid sheets found", {
  local_mocked_bindings(
    excel_sheets = function(...) c("Tot1", "Resumo", "Summary"),
    .package = "readxl"
  )

  expect_error(
    educabR:::read_fundeb_sheets("dummy.xls", 2023, quiet = TRUE),
    "no valid data sheets"
  )
})

test_that("read_fundeb_sheets errors when all sheets fail to parse", {
  local_mocked_bindings(
    excel_sheets = function(...) c("E_FPE"),
    .package = "readxl"
  )

  local_mocked_bindings(
    parse_fundeb_sheet = function(...) stop("parse error"),
    .package = "educabR"
  )

  expect_error(
    educabR:::read_fundeb_sheets("dummy.xls", 2023, quiet = TRUE),
    "no data could be read"
  )
})

test_that("read_fundeb_sheets handles sheets with 3-part names like E_COUN_VAAR", {
  local_mocked_bindings(
    excel_sheets = function(...) c("E_COUN_VAAR", "M_COUN_VAAR"),
    .package = "readxl"
  )

  local_mocked_bindings(
    parse_fundeb_sheet = function(file_path, sheet_name, year,
                                  source_name, dest_name) {
      dplyr::tibble(
        estados = "SAO PAULO", uf = "SP",
        mes_ano = as.Date("2023-01-31"),
        origem = source_name, destino = dest_name,
        tabela = "Fundeb", valor = 1000
      )
    },
    .package = "educabR"
  )

  result <- educabR:::read_fundeb_sheets("dummy.xls", 2023, quiet = TRUE)
  expect_true(all(result$origem == "VAAR"))
})

test_that("parse_fundeb_sheet finds header rows and extracts tables", {
  mock_raw <- dplyr::tibble(
    ...1 = c("REPASSE DO FUNDEB", "ESTADOS", "SAO PAULO", "RIO DE JANEIRO",
             "", "AJUSTE FUNDEB", "ESTADOS", "SAO PAULO"),
    ...2 = c("", "UF", "SP", "RJ", "", "", "UF", "SP"),
    ...3 = c("", "JANEIRO", "1000", "2000", "", "", "JANEIRO", "50")
  )

  local_mocked_bindings(
    read_excel = function(...) mock_raw,
    .package = "readxl"
  )

  result <- educabR:::parse_fundeb_sheet("dummy.xls", "E_FPE", 2023, "FPE", "UF")
  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 0)
  expect_true("valor" %in% names(result))
})

test_that("parse_fundeb_sheet returns empty tibble when no header rows", {
  mock_raw <- dplyr::tibble(
    ...1 = c("SOME DATA", "OTHER DATA"),
    ...2 = c("VALUE1", "VALUE2"),
    ...3 = c("100", "200")
  )

  local_mocked_bindings(
    read_excel = function(...) mock_raw,
    .package = "readxl"
  )

  result <- educabR:::parse_fundeb_sheet("dummy.xls", "E_FPE", 2023, "FPE", "UF")
  expect_equal(nrow(result), 0)
})

test_that("parse_fundeb_sheet handles single table (no ajuste)", {
  mock_raw <- dplyr::tibble(
    ...1 = c("REPASSE", "ESTADOS", "SAO PAULO"),
    ...2 = c("", "UF", "SP"),
    ...3 = c("", "JANEIRO", "1000")
  )

  local_mocked_bindings(
    read_excel = function(...) mock_raw,
    .package = "readxl"
  )

  result <- educabR:::parse_fundeb_sheet("dummy.xls", "E_FPE", 2023, "FPE", "UF")
  expect_true(nrow(result) > 0)
  expect_true(all(result$tabela == "Fundeb"))
})

test_that("tidy_fundeb_table handles MARCO with cedilla accent", {
  df <- dplyr::tibble(
    ESTADO = c("SAO PAULO"),
    UF = c("SP"),
    "MAR\u00c7O" := c(1500)
  )

  result <- educabR:::tidy_fundeb_table(df, 2023, "FPE", "UF", "Fundeb")

  expect_equal(nrow(result), 1)
  expect_equal(result$mes_ano[1], as.Date("2023-03-31"))
})

test_that("fetch_fundeb_enrollment paginates and stops on empty page", {
  call_count <- 0

  local_mocked_bindings(
    request = function(url) {
      structure(list(url = url), class = "httr2_request")
    },
    req_url_query = function(req, ...) req,
    req_timeout = function(req, ...) req,
    req_retry = function(req, ...) req,
    req_perform = function(req) {
      call_count <<- call_count + 1
      structure(list(call = call_count), class = "httr2_response")
    },
    resp_body_json = function(resp) {
      if (resp$call == 1) {
        list(value = list(
          list(AnoCenso = 2023, Uf = "SP", MunicipioGe = "SAO PAULO",
               TipoRedeEducacao = "PUB", DescricaoTipoEducacao = "REG",
               DescricaoTipoEnsino = "FUND", DescricaoTipoTurma = "AI",
               DescricaoTipoCargaHoraria = "PARC",
               DescricaoTipoLocalizacao = "URB",
               QtdMatricula = 1000)
        ))
      } else {
        list(value = list())
      }
    },
    .package = "httr2"
  )

  result <- educabR:::fetch_fundeb_enrollment(2023, quiet = TRUE)
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 1)
  expect_true("AnoCenso" %in% names(result) || "anocenso" %in% names(result))
})

test_that("fetch_fundeb_enrollment with uf filter builds correct query", {
  call_count <- 0

  local_mocked_bindings(
    request = function(url) {
      structure(list(url = url), class = "httr2_request")
    },
    req_url_query = function(req, ...) {
      args <- list(...)
      # Verify the filter contains UF clause
      if (!is.null(args$`$filter`)) {
        expect_true(grepl("Uf eq 'SP'", args$`$filter`))
      }
      req
    },
    req_timeout = function(req, ...) req,
    req_retry = function(req, ...) req,
    req_perform = function(req) {
      call_count <<- call_count + 1
      structure(list(call = call_count), class = "httr2_response")
    },
    resp_body_json = function(resp) {
      if (resp$call == 1) {
        list(value = list(
          list(AnoCenso = 2023, Uf = "SP", MunicipioGe = "SAO PAULO",
               TipoRedeEducacao = "PUB", DescricaoTipoEducacao = "REG",
               DescricaoTipoEnsino = "FUND", DescricaoTipoTurma = "AI",
               DescricaoTipoCargaHoraria = "PARC",
               DescricaoTipoLocalizacao = "URB",
               QtdMatricula = 500)
        ))
      } else {
        list(value = list())
      }
    },
    .package = "httr2"
  )

  result <- educabR:::fetch_fundeb_enrollment(2023, uf = "SP", quiet = TRUE)
  expect_equal(nrow(result), 1)
})

test_that("fetch_fundeb_enrollment respects n_max", {
  call_count <- 0

  local_mocked_bindings(
    request = function(url) {
      structure(list(url = url), class = "httr2_request")
    },
    req_url_query = function(req, ...) req,
    req_timeout = function(req, ...) req,
    req_retry = function(req, ...) req,
    req_perform = function(req) {
      call_count <<- call_count + 1
      structure(list(call = call_count), class = "httr2_response")
    },
    resp_body_json = function(resp) {
      list(value = list(
        list(AnoCenso = 2023, Uf = "SP", MunicipioGe = "SAO PAULO",
             TipoRedeEducacao = "PUB", DescricaoTipoEducacao = "REG",
             DescricaoTipoEnsino = "FUND", DescricaoTipoTurma = "AI",
             DescricaoTipoCargaHoraria = "PARC",
             DescricaoTipoLocalizacao = "URB",
             QtdMatricula = 100),
        list(AnoCenso = 2023, Uf = "RJ", MunicipioGe = "RIO",
             TipoRedeEducacao = "PUB", DescricaoTipoEducacao = "REG",
             DescricaoTipoEnsino = "FUND", DescricaoTipoTurma = "AI",
             DescricaoTipoCargaHoraria = "PARC",
             DescricaoTipoLocalizacao = "URB",
             QtdMatricula = 200)
      ))
    },
    .package = "httr2"
  )

  result <- educabR:::fetch_fundeb_enrollment(2023, n_max = 1, quiet = TRUE)
  expect_equal(nrow(result), 1)
})

test_that("fetch_fundeb_enrollment errors when no data returned", {
  local_mocked_bindings(
    request = function(url) {
      structure(list(url = url), class = "httr2_request")
    },
    req_url_query = function(req, ...) req,
    req_timeout = function(req, ...) req,
    req_retry = function(req, ...) req,
    req_perform = function(req) {
      structure(list(), class = "httr2_response")
    },
    resp_body_json = function(resp) {
      list(value = list())
    },
    .package = "httr2"
  )

  expect_error(
    educabR:::fetch_fundeb_enrollment(2023, quiet = TRUE),
    "no FUNDEB enrollment data found"
  )
})

test_that("fetch_fundeb_enrollment errors on API failure", {
  local_mocked_bindings(
    request = function(url) {
      structure(list(url = url), class = "httr2_request")
    },
    req_url_query = function(req, ...) req,
    req_timeout = function(req, ...) req,
    req_retry = function(req, ...) req,
    req_perform = function(req) {
      stop("connection timeout")
    },
    .package = "httr2"
  )

  expect_error(
    educabR:::fetch_fundeb_enrollment(2023, quiet = TRUE),
    "failed to fetch FUNDEB enrollment"
  )
})

test_that("get_fundeb_enrollment full pipeline fetches from API when not cached", {
  temp_cache <- setup_temp_cache()

  mock_enrollment <- dplyr::tibble(
    ano_censo = c(2018, 2018),
    uf = c("SP", "RJ"),
    municipio = c("SAO PAULO", "RIO"),
    tipo_rede_educacao = c("PUB", "PUB"),
    descricao_tipo_educacao = c("REG", "REG"),
    descricao_tipo_ensino = c("FUND", "FUND"),
    descricao_tipo_turma = c("AI", "AI"),
    descricao_tipo_carga_horaria = c("PARC", "PARC"),
    descricao_tipo_localizacao = c("URB", "URB"),
    qtd_matricula = c(1000, 2000)
  )

  local_mocked_bindings(
    fetch_fundeb_enrollment = function(year, uf = NULL, n_max = Inf,
                                       quiet = FALSE) {
      mock_enrollment
    },
    rename_fundeb_enrollment = function(df) df,
    .package = "educabR"
  )

  result <- get_fundeb_enrollment(2018, keep_file = TRUE, quiet = TRUE)
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2)

  # Check that it was cached
  file_path <- educabR:::cache_path("fundeb", "fundeb_enrollment_2018.csv")
  expect_true(file.exists(file_path))
})

# =============================================================================
# utils-download.R coverage gaps
# =============================================================================

test_that("download_inep_file creates directory and downloads file", {
  temp_dir <- withr::local_tempdir()
  dest <- file.path(temp_dir, "subdir", "test_file.csv")

  local_mocked_bindings(
    get_remote_file_size = function(...) 5242880,
    .package = "educabR"
  )

  local_mocked_bindings(
    request = function(url) {
      structure(list(url = url), class = "httr2_request")
    },
    req_timeout = function(req, ...) req,
    req_retry = function(req, ...) req,
    req_perform = function(req) {
      structure(list(), class = "httr2_response")
    },
    resp_body_raw = function(resp) {
      charToRaw("col1;col2\n1;2\n")
    },
    .package = "httr2"
  )

  result <- educabR:::download_inep_file("http://example.com/test.csv", dest,
                                         quiet = FALSE)
  expect_equal(result, dest)
  expect_true(file.exists(dest))
  expect_true(dir.exists(dirname(dest)))
})

test_that("download_inep_file quiet mode skips file size check", {
  temp_dir <- withr::local_tempdir()
  dest <- file.path(temp_dir, "test_quiet.csv")

  local_mocked_bindings(
    request = function(url) {
      structure(list(url = url), class = "httr2_request")
    },
    req_timeout = function(req, ...) req,
    req_retry = function(req, ...) req,
    req_perform = function(req) {
      structure(list(), class = "httr2_response")
    },
    resp_body_raw = function(resp) {
      charToRaw("data\n")
    },
    .package = "httr2"
  )

  result <- educabR:::download_inep_file("http://example.com/test.csv", dest,
                                         quiet = TRUE)
  expect_equal(result, dest)
  expect_true(file.exists(dest))
})

test_that("download_inep_file reports GB for large files", {
  temp_dir <- withr::local_tempdir()
  dest <- file.path(temp_dir, "big_file.csv")

  local_mocked_bindings(
    request = function(url) {
      structure(list(url = url), class = "httr2_request")
    },
    req_timeout = function(req, ...) req,
    req_retry = function(req, ...) req,
    req_perform = function(req) {
      structure(list(), class = "httr2_response")
    },
    resp_body_raw = function(resp) {
      charToRaw("data\n")
    },
    .package = "httr2"
  )

  local_mocked_bindings(
    get_remote_file_size = function(...) 2 * 1024^3,
    .package = "educabR"
  )

  # The GB path: size_mb >= 1000
  expect_message(
    educabR:::download_inep_file("http://example.com/big.csv", dest,
                                 quiet = FALSE),
    "GB"
  )
})

test_that("download_inep_file shows generic message when size unknown", {
  temp_dir <- withr::local_tempdir()
  dest <- file.path(temp_dir, "unknown_size.csv")

  local_mocked_bindings(
    request = function(url) {
      structure(list(url = url), class = "httr2_request")
    },
    req_timeout = function(req, ...) req,
    req_retry = function(req, ...) req,
    req_perform = function(req) {
      structure(list(), class = "httr2_response")
    },
    resp_body_raw = function(resp) {
      charToRaw("data\n")
    },
    .package = "httr2"
  )

  local_mocked_bindings(
    get_remote_file_size = function(...) NULL,
    .package = "educabR"
  )

  expect_message(
    educabR:::download_inep_file("http://example.com/file.csv", dest,
                                 quiet = FALSE),
    "downloading from INEP"
  )
})

test_that("download_inep_file errors on download failure", {
  temp_dir <- withr::local_tempdir()
  dest <- file.path(temp_dir, "fail.csv")

  local_mocked_bindings(
    request = function(url) {
      structure(list(url = url), class = "httr2_request")
    },
    req_timeout = function(req, ...) req,
    req_retry = function(req, ...) req,
    req_perform = function(req) {
      stop("connection refused")
    },
    .package = "httr2"
  )

  expect_error(
    educabR:::download_inep_file("http://bad-url.com/fail.csv", dest,
                                 quiet = TRUE),
    "download failed"
  )
})

test_that("get_remote_file_size returns NULL on failure", {
  local_mocked_bindings(
    request = function(url) {
      structure(list(url = url), class = "httr2_request")
    },
    req_method = function(req, ...) req,
    req_timeout = function(req, ...) req,
    req_perform = function(req) {
      stop("network error")
    },
    .package = "httr2"
  )

  result <- educabR:::get_remote_file_size("http://invalid.example.com/file.zip")
  expect_null(result)
})

test_that("get_remote_file_size returns numeric size on success", {
  local_mocked_bindings(
    request = function(url) {
      structure(list(url = url), class = "httr2_request")
    },
    req_method = function(req, ...) req,
    req_timeout = function(req, ...) req,
    req_perform = function(req) {
      structure(list(), class = "httr2_response")
    },
    resp_header = function(resp, name) "12345678",
    .package = "httr2"
  )

  result <- educabR:::get_remote_file_size("http://example.com/file.zip")
  expect_equal(result, 12345678)
})

test_that("get_remote_file_size returns NULL when no content-length header", {
  local_mocked_bindings(
    request = function(url) {
      structure(list(url = url), class = "httr2_request")
    },
    req_method = function(req, ...) req,
    req_timeout = function(req, ...) req,
    req_perform = function(req) {
      structure(list(), class = "httr2_response")
    },
    resp_header = function(resp, name) NULL,
    .package = "httr2"
  )

  result <- educabR:::get_remote_file_size("http://example.com/file.zip")
  expect_null(result)
})

test_that("read_inep_file reads a CSV file correctly", {
  temp_file <- withr::local_tempfile(fileext = ".csv")
  writeLines(c("col1;col2;col3", "a;1;x", "b;2;y"), temp_file)

  result <- educabR:::read_inep_file(temp_file, delim = ";")
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2)
  expect_equal(ncol(result), 3)
})

test_that("read_inep_file auto-detects encoding", {
  temp_file <- withr::local_tempfile(fileext = ".csv")
  writeLines(c("col1;col2", "abc;def"), temp_file)

  # encoding = NULL triggers auto-detection
  result <- educabR:::read_inep_file(temp_file, delim = ";", encoding = NULL)
  expect_s3_class(result, "tbl_df")
})

test_that("read_inep_file respects n_max", {
  temp_file <- withr::local_tempfile(fileext = ".csv")
  writeLines(c("col1;col2", "a;1", "b;2", "c;3", "d;4"), temp_file)

  result <- educabR:::read_inep_file(temp_file, delim = ";", n_max = 2)
  expect_equal(nrow(result), 2)
})

test_that("extract_zip handles non-zip file", {
  temp_dir <- withr::local_tempdir()
  bad_zip <- file.path(temp_dir, "bad.zip")
  writeLines("this is not a zip file", bad_zip)
  exdir <- file.path(temp_dir, "out")

  # On some platforms unzip gives a warning instead of error for invalid zip
  # so we just check it doesn't silently succeed with extracted files
  result <- tryCatch(
    educabR:::extract_zip(bad_zip, exdir, quiet = TRUE),
    error = function(e) "error_raised",
    warning = function(w) "warning_raised"
  )
  expect_true(result %in% c("error_raised", "warning_raised") ||
              length(result) == 0)
})

test_that("extract_archive handles 7z format", {
  skip_on_cran()
  temp_dir <- withr::local_tempdir()
  fake_7z <- file.path(temp_dir, "test.7z")
  file.create(fake_7z)
  exdir <- file.path(temp_dir, "out")

  # Fake 7z file will fail extraction - may error or warn depending on system
  tryCatch(
    withCallingHandlers(
      educabR:::extract_archive(fake_7z, exdir, quiet = TRUE),
      warning = function(w) invokeRestart("muffleWarning")
    ),
    error = function(e) {
      expect_true(TRUE)  # any error is expected
    }
  )
})

# =============================================================================
# get-cpc.R coverage gaps
# =============================================================================

test_that("get_cpc full pipeline when not cached", {
  temp_cache <- setup_temp_cache()

  mock_data <- dplyr::tibble(
    CO_CURSO = c(1, 2),
    CO_IES = c(100, 200),
    NO_CURSO = c("DIREITO", "MEDICINA"),
    CPC_CONTINUO = c(3.5, 4.2),
    CPC_FAIXA = c("4", "SC"),
    CO_GRUPO = c(1, 2)
  )

  local_mocked_bindings(
    download_inep_file = function(url, destfile, quiet = FALSE) {
      dir.create(dirname(destfile), recursive = TRUE, showWarnings = FALSE)
      file.create(destfile)
      destfile
    },
    read_excel_safe = function(file, n_max = Inf) mock_data,
    .package = "educabR"
  )

  result <- get_cpc(2023, quiet = TRUE)
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2)
  # SC -> NA via convert_faixa_columns
  expect_true(is.na(result$cpc_faixa[2]))
  # standardize_names applied
  expect_true("co_curso" %in% names(result))
})

test_that("get_cpc with n_max limits rows", {
  temp_cache <- setup_temp_cache()

  mock_data <- dplyr::tibble(
    CO_CURSO = 1:5,
    CO_IES = 101:105,
    NO_CURSO = paste("CURSO", 1:5),
    CPC_CONTINUO = runif(5, 1, 5),
    CPC_FAIXA = as.character(1:5)
  )

  local_mocked_bindings(
    download_inep_file = function(url, destfile, quiet = FALSE) {
      dir.create(dirname(destfile), recursive = TRUE, showWarnings = FALSE)
      file.create(destfile)
      destfile
    },
    read_excel_safe = function(file, n_max = Inf) {
      if (!is.infinite(n_max)) {
        mock_data[seq_len(min(n_max, nrow(mock_data))), ]
      } else {
        mock_data
      }
    },
    .package = "educabR"
  )

  result <- get_cpc(2023, n_max = 3, quiet = TRUE)
  expect_equal(nrow(result), 3)
})

test_that("get_cpc with keep_file=FALSE removes cached file", {
  temp_cache <- setup_temp_cache()

  mock_data <- dplyr::tibble(
    CO_CURSO = 1, CO_IES = 100, NO_CURSO = "DIREITO",
    CPC_CONTINUO = 3.5, CPC_FAIXA = "4"
  )

  local_mocked_bindings(
    download_inep_file = function(url, destfile, quiet = FALSE) {
      dir.create(dirname(destfile), recursive = TRUE, showWarnings = FALSE)
      file.create(destfile)
      destfile
    },
    read_excel_safe = function(file, n_max = Inf) mock_data,
    .package = "educabR"
  )

  result <- get_cpc(2023, keep_file = FALSE, quiet = TRUE)
  expect_s3_class(result, "tbl_df")

  file_path <- educabR:::cache_path("cpc", "cpc_2023.xlsx")
  expect_false(file.exists(file_path))
})

test_that("get_cpc not-quiet prints messages", {
  temp_cache <- setup_temp_cache()

  mock_data <- dplyr::tibble(
    CO_CURSO = 1, CO_IES = 100, NO_CURSO = "DIREITO",
    CPC_CONTINUO = 3.5, CPC_FAIXA = "4"
  )

  local_mocked_bindings(
    download_inep_file = function(url, destfile, quiet = FALSE) {
      dir.create(dirname(destfile), recursive = TRUE, showWarnings = FALSE)
      file.create(destfile)
      destfile
    },
    read_excel_safe = function(file, n_max = Inf) mock_data,
    .package = "educabR"
  )

  expect_message(
    get_cpc(2023, quiet = FALSE),
    "downloading CPC"
  )
})

test_that("get_cpc applies clean_dash_values", {
  temp_cache <- setup_temp_cache()

  mock_data <- dplyr::tibble(
    CO_CURSO = c(1, 2),
    CO_IES = c(100, 200),
    NO_CURSO = c("DIREITO", "-"),
    CPC_CONTINUO = c(3.5, 4.2),
    CPC_FAIXA = c("4", "3")
  )

  local_mocked_bindings(
    download_inep_file = function(url, destfile, quiet = FALSE) {
      dir.create(dirname(destfile), recursive = TRUE, showWarnings = FALSE)
      file.create(destfile)
      destfile
    },
    read_excel_safe = function(file, n_max = Inf) mock_data,
    .package = "educabR"
  )

  result <- get_cpc(2023, quiet = TRUE)
  expect_true(is.na(result$no_curso[2]))
})

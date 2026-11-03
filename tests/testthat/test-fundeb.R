# tests for FUNDEB functions

# --- year validation ---

test_that("validate_year accepts valid FUNDEB years", {
  expect_silent(validate_year(2007, "fundeb"))
  expect_silent(validate_year(2023, "fundeb"))
  expect_silent(validate_year(2026, "fundeb"))
})

test_that("validate_year rejects invalid FUNDEB years", {
  expect_error(
    validate_year(2006, "fundeb"),
    "not available"
  )

  expect_error(
    validate_year(2027, "fundeb"),
    "not available"
  )
})

test_that("available_years returns expected FUNDEB years", {
  years <- available_years("fundeb")

  expect_true(2007 %in% years)
  expect_true(2026 %in% years)
  expect_false(2006 %in% years)
  expect_equal(length(years), 20)
})

# --- URL builder ---

test_that("build_fundeb_url returns correct URLs", {
  url_2007 <- build_fundeb_url(2007)
  expect_equal(
    url_2007,
    "https://thot-arquivos.tesouro.gov.br/publicacao/28512"
  )

  url_2019 <- build_fundeb_url(2019)
  expect_equal(
    url_2019,
    "https://thot-arquivos.tesouro.gov.br/publicacao/29102"
  )

  url_2026 <- build_fundeb_url(2026)
  expect_equal(
    url_2026,
    "https://thot-arquivos.tesouro.gov.br/publicacao/53824"
  )
})

test_that("build_fundeb_url errors for unknown year", {
  expect_error(
    build_fundeb_url(1999),
    "no FUNDEB distribution URL found"
  )
})

test_that("FUNDEB URL map has entry for every available year", {
  years <- available_years("fundeb")
  for (y in years) {
    expect_true(
      as.character(y) %in% names(fundeb_recursos_ids),
      info = paste("missing FUNDEB URL for year", y)
    )
  }
})

# --- argument validation ---

test_that("get_fundeb_distribution rejects invalid source", {
  expect_error(
    get_fundeb_distribution(2023, source = "INVALID"),
    "invalid source"
  )
})

test_that("get_fundeb_distribution rejects invalid destination", {
  expect_error(
    get_fundeb_distribution(2023, destination = "invalid"),
    "should be one of"
  )
})

# --- data validation ---

test_that("validate_data warns for unexpected FUNDEB distribution structure", {
  bad_data <- data.frame(col1 = 1:5, col2 = 6:10, col3 = 11:15)

  expect_warning(
    validate_data(bad_data, "fundeb", 2023),
    "unexpected structure"
  )
})

test_that("validate_data passes for valid FUNDEB distribution structure", {
  good_data <- data.frame(
    estados = c("Acre", "Alagoas"),
    uf = c("AC", "AL"),
    mes_ano = as.Date(c("2023-01-31", "2023-02-28")),
    origem = c("FPE", "FPE"),
    destino = c("UF", "Munic\u00edpio"),
    tabela = c("Fundeb", "Ajuste Fundeb"),
    valor = c(1000.50, 2000.75)
  )

  expect_silent(validate_data(good_data, "fundeb", 2023))
})

test_that("validate_data warns for unexpected FUNDEB enrollment structure", {
  bad_data <- data.frame(col1 = 1:5, col2 = 6:10, col3 = 11:15)

  expect_warning(
    validate_data(bad_data, "fundeb_enrollment", 2023),
    "unexpected structure"
  )
})

test_that("validate_data passes for valid FUNDEB enrollment structure", {
  good_data <- data.frame(
    ano_censo = c(2023, 2023),
    uf = c("SP", "RJ"),
    qtd_matricula = c(1000, 2000)
  )

  expect_silent(validate_data(good_data, "fundeb_enrollment", 2023))
})

# --- column rename ---

test_that("rename_fundeb_enrollment converts CamelCase to snake_case", {
  df <- data.frame(
    AnoCenso = 2023,
    Uf = "SP",
    MunicipioGe = "SAO PAULO",
    TipoRedeEducacao = "PUBLICA",
    DescricaoTipoEducacao = "REGULAR",
    DescricaoTipoEnsino = "FUNDAMENTAL",
    DescricaoTipoTurma = "ANOS INICIAIS",
    DescricaoTipoCargaHoraria = "PARCIAL",
    DescricaoTipoLocalizacao = "URBANA",
    QtdMatricula = 1000
  )

  result <- rename_fundeb_enrollment(df)

  expect_equal(
    names(result),
    c(
      "ano_censo",
      "uf",
      "municipio",
      "tipo_rede_educacao",
      "descricao_tipo_educacao",
      "descricao_tipo_ensino",
      "descricao_tipo_turma",
      "descricao_tipo_carga_horaria",
      "descricao_tipo_localizacao",
      "qtd_matricula"
    )
  )
})

# --- constants ---

test_that("fundeb_sources contains all expected sources", {
  expected <- c(
    "FPE",
    "FPM",
    "IPI",
    "ITR",
    "VAAF",
    "VAAT",
    "VAAR",
    "ICMS",
    "IPVA",
    "ITCMD",
    "COUN",
    "COUN_FTI",
    "LC8796",
    "AJUSTE",
    "AFE_EC123"
  )
  expect_equal(fundeb_sources, expected)
})

test_that("fundeb_sheet_source keeps VAAF/VAAT/VAAR short and others whole", {
  expect_equal(fundeb_sheet_source("E_FPE"), "FPE")
  expect_equal(fundeb_sheet_source("M_COUN_VAAF"), "VAAF")
  expect_equal(fundeb_sheet_source("E_COUN"), "COUN")
  expect_equal(fundeb_sheet_source("E_COUN_FTI"), "COUN_FTI")
  expect_equal(fundeb_sheet_source("M_AFE_EC123"), "AFE_EC123")
  expect_equal(fundeb_sheet_source("E_Ajuste"), "AJUSTE")
})

test_that("read_fundeb_sheets reads every data sheet but not the summaries", {
  # 2007-2020 files: the Complementacao da Uniao (E_COUN) was left out
  read <- character()
  local_mocked_bindings(
    excel_sheets = function(path) {
      c(
        "Resumo",
        "E_FPE",
        "E_COUN",
        "E_LC8796",
        "E_Ajuste",
        "E_Tot1_U",
        "E_Tot2_E",
        "E_TOTAL",
        "M_COUN_VAAF"
      )
    },
    .package = "readxl"
  )
  local_mocked_bindings(
    parse_fundeb_sheet = function(
      file_path,
      sheet_name,
      year,
      source_name,
      dest_name
    ) {
      read <<- c(read, sheet_name)
      dplyr::tibble(
        estados = "ACRE",
        uf = "AC",
        mes_ano = as.Date("2010-01-31"),
        origem = source_name,
        destino = dest_name,
        tabela = "Fundeb",
        valor = 1
      )
    }
  )

  out <- read_fundeb_sheets("fundeb.xls", 2010, quiet = TRUE)

  expect_equal(
    read,
    c("E_FPE", "E_COUN", "E_LC8796", "E_Ajuste", "M_COUN_VAAF")
  )
  expect_equal(out$origem, c("FPE", "COUN", "LC8796", "AJUSTE", "VAAF"))
})

test_that("tidy_fundeb_table drops footnote rows without a UF code", {
  # 2009: "Obs.: Dados de novembro retificados em 16/04/2010" became a row
  df <- data.frame(
    ESTADOS = c("ACRE", "Obs.: Dados de novembro retificados em 16/04/2010"),
    UF = c("AC", NA),
    JANEIRO = c("10", NA),
    check.names = FALSE
  )

  out <- tidy_fundeb_table(df, 2009, "FPE", "UF", "Fundeb")

  expect_equal(unique(out$uf), "AC")
  expect_equal(out$valor, 10)
})

test_that("fundeb_month_map covers all 12 months", {
  month_numbers <- unique(unname(fundeb_month_map))
  expect_equal(sort(month_numbers), 1:12)
})

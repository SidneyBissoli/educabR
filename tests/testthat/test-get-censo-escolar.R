# tests for Censo Escolar functions

# --- year validation ---

test_that("validate_year accepts valid censo_escolar years", {
  expect_silent(validate_year(1995, "censo_escolar"))
  expect_silent(validate_year(2023, "censo_escolar"))
  expect_silent(validate_year(2024, "censo_escolar"))
})

test_that("validate_year rejects invalid censo_escolar years", {
  expect_error(
    validate_year(1994, "censo_escolar"),
    "not available"
  )

  expect_error(
    validate_year(2025, "censo_escolar"),
    "not available"
  )
})

test_that("fallback_years returns expected censo_escolar years", {
  years <- fallback_years("censo_escolar")

  expect_true(1995 %in% years)
  expect_true(2024 %in% years)
  expect_false(1994 %in% years)
  expect_equal(length(years), 30)
})

# --- get_censo_escolar: argument validation ---

test_that("get_censo_escolar rejects invalid year", {
  expect_error(
    get_censo_escolar(1994),
    "not available"
  )

  expect_error(
    get_censo_escolar(2025),
    "not available"
  )
})

# --- build_inep_url ---

test_that("build_inep_url returns valid censo_escolar URL", {
  url <- build_inep_url("censo_escolar", 2023)

  expect_true(grepl("microdados_censo_escolar_2023", url))
  expect_true(grepl("download.inep.gov.br", url))
  expect_true(grepl("\\.zip$", url))
})

test_that("build_inep_url returns valid censo_escolar URL for boundary years", {
  url_1995 <- build_inep_url("censo_escolar", 1995)
  expect_true(grepl("microdados_censo_escolar_1995", url_1995))

  url_2024 <- build_inep_url("censo_escolar", 2024)
  expect_true(grepl("microdados_censo_escolar_2024", url_2024))
})

# --- list_censo_files ---

test_that("list_censo_files rejects invalid year", {
  expect_error(
    list_censo_files(1994),
    "not available"
  )
})

test_that("list_censo_files errors when not downloaded", {
  withr::with_tempdir({
    withr::local_options(educabR.cache_dir = getwd())

    expect_error(
      list_censo_files(2023),
      "not downloaded"
    )
  })
})

# --- validate_data ---

test_that("validate_data warns for missing co_uf in censo_escolar", {
  bad_data <- data.frame(col1 = 1:5, col2 = 6:10, col3 = 11:15)

  expect_warning(
    validate_data(bad_data, "censo_escolar", 2023),
    "co_uf"
  )
})

test_that("validate_data passes for valid censo_escolar structure", {
  good_data <- data.frame(
    co_entidade = 1:5,
    co_uf = rep(35, 5),
    no_entidade = paste("School", 1:5)
  )

  expect_silent(validate_data(good_data, "censo_escolar", 2023))
})

# --- uf_to_code ---

test_that("uf_to_code converts valid abbreviations", {
  expect_equal(educabR:::uf_to_code("SP"), 35)
  expect_equal(educabR:::uf_to_code("RJ"), 33)
  expect_equal(educabR:::uf_to_code("MG"), 31)
  expect_equal(educabR:::uf_to_code("AC"), 12)
})

test_that("uf_to_code is case-insensitive", {
  expect_equal(educabR:::uf_to_code("sp"), 35)
  expect_equal(educabR:::uf_to_code("Sp"), 35)
})

test_that("uf_to_code passes numeric codes through unchanged", {
  expect_equal(educabR:::uf_to_code(35), 35)
  expect_equal(educabR:::uf_to_code(11), 11)
})

test_that("uf_to_code errors for invalid UF", {
  expect_error(
    educabR:::uf_to_code("XX"),
    "invalid UF"
  )
})

# --- standardize_names ---

test_that("standardize_names converts to lowercase with underscores", {
  df <- data.frame(CO_UF = 1, NO_MUNICIPIO = "test", SG_UF = "SP")
  result <- educabR:::standardize_names(df)

  expect_true(all(names(result) == tolower(names(result))))
  expect_true("co_uf" %in% names(result))
  expect_true("no_municipio" %in% names(result))
})

# --- parse_sas_dates ---

test_that("parse_sas_dates converts SAS datetime strings to Date", {
  df <- data.frame(
    dt_criacao = c("12FEB2024:00:00:00", "05MAR2023:00:00:00"),
    nome = c("A", "B"),
    stringsAsFactors = FALSE
  )

  result <- educabR:::parse_sas_dates(df)

  expect_s3_class(result$dt_criacao, "Date")
  expect_equal(result$dt_criacao[1], as.Date("2024-02-12"))
})

test_that("parse_sas_dates leaves non-dt columns unchanged", {
  df <- data.frame(
    nome = c("A", "B"),
    valor = c(1, 2),
    stringsAsFactors = FALSE
  )

  result <- educabR:::parse_sas_dates(df)

  expect_equal(result$nome, c("A", "B"))
  expect_equal(result$valor, c(1, 2))
})

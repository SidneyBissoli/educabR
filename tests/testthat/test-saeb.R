# tests for SAEB functions

# --- year validation ---

test_that("validate_year accepts valid SAEB years", {
  expect_silent(validate_year(2023, "saeb"))
  expect_silent(validate_year(2021, "saeb"))
  expect_silent(validate_year(2011, "saeb"))
})

test_that("validate_year rejects invalid SAEB years", {
  expect_error(
    validate_year(2022, "saeb"),
    "not available"
  )

  expect_error(
    validate_year(2010, "saeb"),
    "not available"
  )

  expect_error(
    validate_year(2024, "saeb"),
    "not available"
  )
})

test_that("validate_year accepts SAEB boundary years", {
  expect_silent(validate_year(2011, "saeb"))
  expect_silent(validate_year(2023, "saeb"))
})

test_that("fallback_years returns expected SAEB years", {
  years <- fallback_years("saeb")

  expect_true(2023 %in% years)
  expect_true(2021 %in% years)
  expect_true(2011 %in% years)
  expect_false(2022 %in% years)
  expect_equal(length(years), 7)
})

# --- build_inep_url ---

test_that("build_inep_url returns valid SAEB URL", {
  url_2023 <- build_inep_url("saeb", 2023)
  expect_true(grepl("microdados_saeb_2023", url_2023))
  expect_true(grepl("download.inep.gov.br", url_2023))
})

test_that("build_inep_url handles SAEB 2021 split", {
  url_fm <- build_inep_url("saeb", 2021, level = "fundamental_medio")
  url_ei <- build_inep_url("saeb", 2021, level = "educacao_infantil")

  expect_true(grepl("ensino_fundamental_e_medio", url_fm))
  expect_true(grepl("educacao_infantil", url_ei))
})

test_that("build_inep_url for SAEB boundary years", {
  url_2011 <- build_inep_url("saeb", 2011)
  expect_true(grepl("microdados_saeb_2011", url_2011))

  url_2023 <- build_inep_url("saeb", 2023)
  expect_true(grepl("microdados_saeb_2023", url_2023))
})

# --- build_saeb_zip_filename ---

test_that("build_saeb_zip_filename handles regular years", {
  filename <- build_saeb_zip_filename(2023)
  expect_equal(filename, "microdados_saeb_2023.zip")
})

test_that("build_saeb_zip_filename handles 2021 split", {
  filename_fm <- build_saeb_zip_filename(2021, "fundamental_medio")
  filename_ei <- build_saeb_zip_filename(2021, "educacao_infantil")

  expect_true(grepl("ensino_fundamental_e_medio", filename_fm))
  expect_true(grepl("educacao_infantil", filename_ei))
})

test_that("build_saeb_zip_filename for non-2021 ignores level parameter", {
  filename_default <- build_saeb_zip_filename(2019)
  filename_with_level <- build_saeb_zip_filename(2019, "fundamental_medio")

  expect_equal(filename_default, filename_with_level)
  expect_equal(filename_default, "microdados_saeb_2019.zip")
})

# --- validate_data ---

test_that("validate_data warns for unexpected SAEB structure", {
  bad_data <- data.frame(col1 = 1:5, col2 = 6:10, col3 = 11:15)

  expect_warning(
    validate_data(bad_data, "saeb", 2023),
    "unexpected structure"
  )
})

test_that("validate_data passes for valid SAEB structure", {
  good_data <- data.frame(
    id_aluno = 1:5,
    id_escola = 101:105,
    score = runif(5)
  )

  expect_silent(validate_data(good_data, "saeb", 2023))
})

# --- get_saeb: argument validation ---

test_that("get_saeb rejects invalid year", {
  expect_error(
    get_saeb(2022),
    "not available"
  )

  expect_error(
    get_saeb(2010),
    "not available"
  )
})

test_that("get_saeb rejects invalid type via match.arg", {
  expect_error(
    get_saeb(2023, type = "invalido"),
    "arg"
  )
})

test_that("get_saeb rejects invalid level via match.arg", {
  expect_error(
    get_saeb(2023, level = "invalido"),
    "arg"
  )
})

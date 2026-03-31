# tests for SAEB functions

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
})

test_that("available_years returns expected SAEB years", {
  years <- available_years("saeb")

  expect_true(2023 %in% years)
  expect_true(2021 %in% years)
  expect_true(2011 %in% years)
  expect_false(2022 %in% years)
  expect_equal(length(years), 7)
})

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

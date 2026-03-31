# tests for ENEM por Escola functions

test_that("build_inep_url returns valid ENEM por Escola URL", {
  url <- build_inep_url("enem_escola", year = NULL)

  expect_true(grepl("microdados_enem_por_escola", url))
  expect_true(grepl("download.inep.gov.br", url))
  expect_true(grepl("\\.zip$", url))
})

test_that("validate_data warns for unexpected ENEM por Escola structure", {
  bad_data <- data.frame(col1 = 1:5, col2 = 6:10, col3 = 11:15)

  expect_warning(
    validate_data(bad_data, "enem_escola", year = NULL),
    "unexpected structure"
  )
})

test_that("validate_data passes for valid ENEM por Escola structure", {
  good_data <- data.frame(
    co_escola_educacenso = 1:5,
    nu_ano = rep(2015, 5),
    no_escola = paste("School", 1:5)
  )

  expect_silent(validate_data(good_data, "enem_escola", year = NULL))
})

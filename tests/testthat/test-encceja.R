# tests for ENCCEJA functions

# --- year validation ---

test_that("validate_year accepts valid ENCCEJA years", {
  expect_silent(validate_year(2023, "encceja"))
  expect_silent(validate_year(2014, "encceja"))
  expect_silent(validate_year(2024, "encceja"))
})

test_that("validate_year rejects invalid ENCCEJA years", {
  expect_error(
    validate_year(2013, "encceja"),
    "not available"
  )

  expect_error(
    validate_year(2025, "encceja"),
    "not available"
  )
})

test_that("validate_year accepts ENCCEJA boundary years", {
  expect_silent(validate_year(2014, "encceja"))
  expect_silent(validate_year(2024, "encceja"))
})

test_that("fallback_years returns expected ENCCEJA years", {
  years <- fallback_years("encceja")

  expect_true(2014 %in% years)
  expect_true(2023 %in% years)
  expect_true(2024 %in% years)
  expect_false(2013 %in% years)
  expect_equal(length(years), 11)
})

# --- build_inep_url ---

test_that("build_inep_url returns valid ENCCEJA URL", {
  url <- build_inep_url("encceja", 2023)

  expect_true(grepl("microdados_encceja_2023", url))
  expect_true(grepl("download.inep.gov.br", url))
  expect_true(grepl("\\.zip$", url))
})

test_that("build_inep_url returns valid ENCCEJA URL for boundary years", {
  url_2014 <- build_inep_url("encceja", 2014)
  expect_true(grepl("microdados_encceja_2014", url_2014))

  url_2024 <- build_inep_url("encceja", 2024)
  expect_true(grepl("microdados_encceja_2024", url_2024))
})

# --- validate_data ---

test_that("validate_data warns for unexpected ENCCEJA structure", {
  bad_data <- data.frame(col1 = 1:5, col2 = 6:10, col3 = 11:15)

  expect_warning(
    validate_data(bad_data, "encceja", 2023),
    "unexpected structure"
  )
})

test_that("validate_data passes for valid ENCCEJA structure", {
  good_data <- data.frame(
    nu_inscricao = 1:5,
    nu_ano = rep(2023, 5),
    tp_sexo = rep("M", 5)
  )

  expect_silent(validate_data(good_data, "encceja", 2023))
})

# --- get_encceja: argument validation ---

test_that("get_encceja rejects invalid year", {
  expect_error(
    get_encceja(2013),
    "not available"
  )

  expect_error(
    get_encceja(2025),
    "not available"
  )
})

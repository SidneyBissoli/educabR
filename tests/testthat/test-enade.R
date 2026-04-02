# tests for ENADE functions

# --- year validation ---

test_that("validate_year accepts valid ENADE years", {
  # use fallback_years directly to avoid HTTP requests in CI
  years <- fallback_years("enade")
  expect_true(2023 %in% years)
  expect_true(2004 %in% years)
  expect_silent(validate_year(2004, "enade"))
})

test_that("validate_year rejects invalid ENADE years", {
  expect_error(
    validate_year(2003, "enade"),
    "not available"
  )

  expect_error(
    validate_year(2025, "enade"),
    "not available"
  )
})

test_that("validate_year accepts ENADE boundary years", {
  expect_silent(validate_year(2004, "enade"))
})

test_that("fallback_years returns expected ENADE years", {
  years <- fallback_years("enade")
  expect_true(2004 %in% years)
  expect_true(2023 %in% years)
  expect_false(2003 %in% years)
  expect_false(2020 %in% years)
  expect_equal(length(years), 19)
})

# --- build_inep_url ---

test_that("build_inep_url returns valid ENADE URL", {
  url <- build_inep_url("enade", 2023)

  expect_true(grepl("microdados_enade_2023", url))
  expect_true(grepl("download.inep.gov.br", url))
  expect_true(grepl("\\.zip$", url))
})

test_that("build_inep_url returns valid ENADE URL for boundary years", {
  url_2004 <- build_inep_url("enade", 2004)
  expect_true(grepl("microdados_enade_2004", url_2004))

  url_2024 <- build_inep_url("enade", 2024)
  expect_true(grepl("microdados_enade_2024", url_2024))
})

# --- validate_data ---

test_that("validate_data warns for unexpected ENADE structure", {
  bad_data <- data.frame(col1 = 1:5, col2 = 6:10, col3 = 11:15)

  expect_warning(
    validate_data(bad_data, "enade", 2023),
    "unexpected structure"
  )
})

test_that("validate_data passes for valid ENADE structure", {
  good_data <- data.frame(
    nu_ano = rep(2023, 5),
    co_curso = 101:105,
    nt_ger = runif(5, 0, 100)
  )

  expect_silent(validate_data(good_data, "enade", 2023))
})

# --- get_enade: argument validation ---

test_that("get_enade rejects invalid year", {
  expect_error(
    get_enade(2003),
    "not available"
  )

  expect_error(
    get_enade(2025),
    "not available"
  )
})

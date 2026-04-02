# tests for IDD functions

# --- year validation ---

test_that("validate_year accepts valid IDD years", {
  expect_silent(validate_year(2023, "idd"))
  expect_silent(validate_year(2014, "idd"))
  expect_silent(validate_year(2021, "idd"))
})

test_that("validate_year rejects invalid IDD years", {
  expect_error(
    validate_year(2013, "idd"),
    "not available"
  )

  expect_error(
    validate_year(2020, "idd"),
    "not available"
  )

  expect_error(
    validate_year(2025, "idd"),
    "not available"
  )
})

test_that("validate_year accepts IDD boundary years", {
  expect_silent(validate_year(2014, "idd"))
  expect_silent(validate_year(2023, "idd"))
  expect_silent(validate_year(2019, "idd"))
  expect_silent(validate_year(2021, "idd"))
})

test_that("fallback_years returns expected IDD years", {
  years <- fallback_years("idd")

  expect_true(2014 %in% years)
  expect_true(2023 %in% years)
  expect_false(2013 %in% years)
  expect_false(2020 %in% years)
  expect_equal(length(years), 9)
})

# --- build_inep_url ---

test_that("build_inep_url returns valid IDD URL for recent years (zip)", {
  url_2023 <- build_inep_url("idd", 2023)
  expect_true(grepl("microdados_IDD_2023", url_2023))
  expect_true(grepl("download.inep.gov.br", url_2023))
  expect_true(grepl("\\.zip$", url_2023))

  url_2021 <- build_inep_url("idd", 2021)
  expect_true(grepl("\\.zip$", url_2021))
})

test_that("build_inep_url returns valid IDD URL for older years (7z)", {
  url_2019 <- build_inep_url("idd", 2019)
  expect_true(grepl("microdados_IDD_2019", url_2019))
  expect_true(grepl("\\.7z$", url_2019))

  url_2014 <- build_inep_url("idd", 2014)
  expect_true(grepl("\\.7z$", url_2014))
})

test_that("IDD archive format switches at year 2021", {
  # years < 2021 should use .7z
  for (y in c(2014, 2015, 2016, 2017, 2018, 2019)) {
    url <- build_inep_url("idd", y)
    expect_true(grepl("\\.7z$", url), info = paste("year", y, "should be .7z"))
  }

  # years >= 2021 should use .zip
  for (y in c(2021, 2022, 2023)) {
    url <- build_inep_url("idd", y)
    expect_true(grepl("\\.zip$", url), info = paste("year", y, "should be .zip"))
  }
})

# --- validate_data ---

test_that("validate_data warns for unexpected IDD structure", {
  bad_data <- data.frame(col1 = 1:5, col2 = 6:10, col3 = 11:15)

  expect_warning(
    validate_data(bad_data, "idd", 2023),
    "unexpected structure"
  )
})

test_that("validate_data passes for valid IDD structure", {
  good_data <- data.frame(
    co_curso = 101:105,
    co_ies = 1:5,
    idd_continuo = runif(5, 0, 5)
  )

  expect_silent(validate_data(good_data, "idd", 2023))
})

# --- get_idd: argument validation ---

test_that("get_idd rejects invalid year", {
  expect_error(
    get_idd(2013),
    "not available"
  )

  expect_error(
    get_idd(2020),
    "not available"
  )
})

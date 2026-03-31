# tests for CPC functions

test_that("validate_year accepts valid CPC years", {
  expect_silent(validate_year(2023, "cpc"))
  expect_silent(validate_year(2007, "cpc"))
  expect_silent(validate_year(2021, "cpc"))
})

test_that("validate_year rejects invalid CPC years", {
  expect_error(
    validate_year(2006, "cpc"),
    "not available"
  )

  expect_error(
    validate_year(2020, "cpc"),
    "not available"
  )

  expect_error(
    validate_year(2025, "cpc"),
    "not available"
  )
})

test_that("available_years returns expected CPC years", {
  years <- available_years("cpc")

  expect_true(2007 %in% years)
  expect_true(2023 %in% years)
  expect_false(2006 %in% years)
  expect_false(2020 %in% years)
  expect_equal(length(years), 16)
})

test_that("CPC URL map has entry for every available year", {
  years <- available_years("cpc")
  for (y in years) {
    expect_true(
      as.character(y) %in% names(cpc_urls),
      info = paste("missing CPC URL for year", y)
    )
  }
})

test_that("validate_data warns for unexpected CPC structure", {
  bad_data <- data.frame(col1 = 1:5, col2 = 6:10, col3 = 11:15)

  expect_warning(
    validate_data(bad_data, "cpc", 2023),
    "unexpected structure"
  )
})

test_that("validate_data passes for valid CPC structure", {
  good_data <- data.frame(
    co_curso = 101:105,
    co_ies = 1:5,
    cpc_continuo = runif(5, 0, 5)
  )

  expect_silent(validate_data(good_data, "cpc", 2023))
})

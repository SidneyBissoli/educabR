# tests for IGC functions

test_that("validate_year accepts valid IGC years", {
  expect_silent(validate_year(2023, "igc"))
  expect_silent(validate_year(2007, "igc"))
  expect_silent(validate_year(2021, "igc"))
})

test_that("validate_year rejects invalid IGC years", {
  expect_error(
    validate_year(2006, "igc"),
    "not available"
  )

  expect_error(
    validate_year(2020, "igc"),
    "not available"
  )

  expect_error(
    validate_year(2025, "igc"),
    "not available"
  )
})

test_that("available_years returns expected IGC years", {
  years <- available_years("igc")

  expect_true(2007 %in% years)
  expect_true(2023 %in% years)
  expect_false(2006 %in% years)
  expect_false(2020 %in% years)
  expect_equal(length(years), 16)
})

test_that("IGC URL map has entry for every available year", {
  years <- available_years("igc")
  for (y in years) {
    expect_true(
      as.character(y) %in% names(igc_urls),
      info = paste("missing IGC URL for year", y)
    )
  }
})

test_that("validate_data warns for unexpected IGC structure", {
  bad_data <- data.frame(col1 = 1:5, col2 = 6:10, col3 = 11:15)

  expect_warning(
    validate_data(bad_data, "igc", 2023),
    "unexpected structure"
  )
})

test_that("validate_data passes for valid IGC structure", {
  good_data <- data.frame(
    co_ies = 1:5,
    no_ies = paste("IES", 1:5),
    igc_continuo = runif(5, 0, 5)
  )

  expect_silent(validate_data(good_data, "igc", 2023))
})

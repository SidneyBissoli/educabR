# tests for IGC functions

# --- year validation ---

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

test_that("validate_year accepts IGC boundary years", {
  expect_silent(validate_year(2007, "igc"))
  expect_silent(validate_year(2023, "igc"))
  expect_silent(validate_year(2019, "igc"))
  expect_silent(validate_year(2021, "igc"))
})

test_that("available_years returns expected IGC years", {
  years <- available_years("igc")

  expect_true(2007 %in% years)
  expect_true(2023 %in% years)
  expect_false(2006 %in% years)
  expect_false(2020 %in% years)
  expect_equal(length(years), 16)
})

# --- IGC URL map ---

test_that("IGC URL map has entry for every available year", {
  years <- available_years("igc")
  for (y in years) {
    expect_true(
      as.character(y) %in% names(educabR:::igc_urls),
      info = paste("missing IGC URL for year", y)
    )
  }
})

test_that("IGC URLs point to INEP download domain", {
  for (url in educabR:::igc_urls) {
    expect_true(
      grepl("download.inep.gov.br", url),
      info = paste("URL does not point to INEP:", url)
    )
  }
})

# --- IGC 2007 is 7z, others are not ---

test_that("IGC 2007 URL is detected as 7z archive", {
  url_2007 <- educabR:::igc_urls[["2007"]]
  ext <- tools::file_ext(url_2007)

  expect_equal(ext, "7z")
})

test_that("IGC years other than 2007 are not 7z archives", {
  years <- setdiff(names(educabR:::igc_urls), "2007")
  for (y in years) {
    url <- educabR:::igc_urls[[y]]
    ext <- tools::file_ext(url)
    expect_true(
      ext %in% c("xls", "xlsx"),
      info = paste("year", y, "has unexpected extension:", ext)
    )
  }
})

# --- validate_data ---

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

# --- convert_faixa_columns (shared with CPC) ---

test_that("convert_faixa_columns works on IGC faixa columns", {
  df <- data.frame(
    co_ies = 1:3,
    igc_faixa = c("3", "SC", "5"),
    stringsAsFactors = FALSE
  )

  result <- educabR:::convert_faixa_columns(df)

  expect_true(is.numeric(result$igc_faixa))
  expect_equal(result$igc_faixa[1], 3)
  expect_true(is.na(result$igc_faixa[2]))
  expect_equal(result$igc_faixa[3], 5)
})

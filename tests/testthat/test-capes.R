# tests for CAPES functions

# --- year validation ---

test_that("validate_year accepts valid CAPES years", {
  expect_silent(validate_year(2024, "capes"))
  expect_silent(validate_year(2013, "capes"))
  expect_silent(validate_year(2020, "capes"))
})

test_that("validate_year rejects invalid CAPES years", {
  expect_error(
    validate_year(2012, "capes"),
    "not available"
  )

  expect_error(
    validate_year(2025, "capes"),
    "not available"
  )
})

test_that("available_years returns expected CAPES years", {
  years <- available_years("capes")

  expect_true(2013 %in% years)
  expect_true(2024 %in% years)
  expect_false(2012 %in% years)
  expect_equal(length(years), 12)
})

test_that("validate_year accepts CAPES boundary years", {
  expect_silent(validate_year(2013, "capes"))
  expect_silent(validate_year(2024, "capes"))
})

# --- validate_data ---

test_that("validate_data warns for unexpected CAPES structure", {
  bad_data <- data.frame(col1 = 1:5, col2 = 6:10, col3 = 11:15)

  expect_warning(
    validate_data(bad_data, "capes", 2023),
    "unexpected structure"
  )
})

test_that("validate_data passes for valid CAPES structure", {
  good_data <- data.frame(
    cd_programa_ies = 1:5,
    nm_programa = paste("Programa", 1:5),
    sg_entidade_ensino = paste("IES", 1:5)
  )

  expect_silent(validate_data(good_data, "capes", 2023))
})

# --- get_capes: argument validation ---

test_that("get_capes rejects invalid type", {
  expect_error(
    get_capes(2023, type = "invalido"),
    "arg"
  )
})

test_that("get_capes rejects invalid year", {
  expect_error(
    get_capes(2012, type = "programas"),
    "not available"
  )
})

# --- discover_capes_url: range prefix detection ---

test_that("discover_capes_url selects correct range prefix for 2013", {
  # We can test that the range prefix selection logic works by checking

  # the capes_year_ranges structure directly
  range_prefix <- NULL
  for (range in educabR:::capes_year_ranges) {
    if (2013 %in% range$years) {
      range_prefix <- range$prefix
      break
    }
  }
  expect_equal(range_prefix, "2013-a-2016")
})

test_that("discover_capes_url selects correct range prefix for 2017", {
  range_prefix <- NULL
  for (range in educabR:::capes_year_ranges) {
    if (2017 %in% range$years) {
      range_prefix <- range$prefix
      break
    }
  }
  expect_equal(range_prefix, "2017-a-2020")
})

test_that("discover_capes_url selects correct range prefix for 2021", {
  range_prefix <- NULL
  for (range in educabR:::capes_year_ranges) {
    if (2021 %in% range$years) {
      range_prefix <- range$prefix
      break
    }
  }
  expect_equal(range_prefix, "2021-a-2024")
})

test_that("discover_capes_url errors for year not in any range", {
  # Year 2012 is not in any capes_year_ranges, and validate_year
  # would catch it first. But if we bypassed validate_year,
  # discover_capes_url would error on range_prefix being NULL.
  # We can verify the ranges do not cover 2012.
  range_prefix <- NULL
  for (range in educabR:::capes_year_ranges) {
    if (2012 %in% range$years) {
      range_prefix <- range$prefix
      break
    }
  }
  expect_null(range_prefix)
})

# --- capes_type_slugs ---

test_that("capes_type_slugs has entries for all 5 types", {
  slugs <- educabR:::capes_type_slugs

  expect_equal(length(slugs), 5)
  expect_true("programas" %in% names(slugs))
  expect_true("discentes" %in% names(slugs))
  expect_true("docentes" %in% names(slugs))
  expect_true("cursos" %in% names(slugs))
  expect_true("catalogo" %in% names(slugs))
})

test_that("capes_type_slugs values are non-empty strings", {
  slugs <- educabR:::capes_type_slugs

  for (slug in slugs) {
    expect_true(nchar(slug) > 0)
  }
})

# --- capes_year_ranges ---

test_that("capes_year_ranges covers years 2013-2024", {
  all_years <- integer(0)
  for (range in educabR:::capes_year_ranges) {
    all_years <- c(all_years, range$years)
  }
  all_years <- sort(unique(all_years))

  expect_equal(all_years, 2013:2024)
})

test_that("capes_year_ranges has 3 range groups", {
  expect_equal(length(educabR:::capes_year_ranges), 3)
})

test_that("each capes_year_ranges entry has years and prefix", {
  for (range in educabR:::capes_year_ranges) {
    expect_true("years" %in% names(range))
    expect_true("prefix" %in% names(range))
    expect_true(length(range$years) > 0)
    expect_true(nchar(range$prefix) > 0)
  }
})

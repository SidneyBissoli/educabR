# tests for CAPES functions

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

test_that("get_capes rejects invalid type", {
  expect_error(
    get_capes(2023, type = "invalido"),
    "arg"
  )
})

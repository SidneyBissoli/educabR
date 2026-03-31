# tests for Higher Education Census functions

test_that("validate_year accepts valid censo_superior years", {
  expect_silent(validate_year(2023, "censo_superior"))
  expect_silent(validate_year(2009, "censo_superior"))
  expect_silent(validate_year(2024, "censo_superior"))
})

test_that("validate_year rejects invalid censo_superior years", {
  expect_error(
    validate_year(2008, "censo_superior"),
    "not available"
  )

  expect_error(
    validate_year(2025, "censo_superior"),
    "not available"
  )
})

test_that("available_years returns expected censo_superior years", {
  years <- available_years("censo_superior")

  expect_true(2009 %in% years)
  expect_true(2023 %in% years)
  expect_true(2024 %in% years)
  expect_false(2008 %in% years)
  expect_equal(length(years), 16)
})

test_that("build_inep_url returns valid censo_superior URL", {
  url <- build_inep_url("censo_superior", 2023)

  expect_true(grepl("microdados_censo_da_educacao_superior_2023", url))
  expect_true(grepl("download.inep.gov.br", url))
  expect_true(grepl("\\.zip$", url))
})

test_that("validate_data warns for unexpected censo_superior structure", {
  bad_data <- data.frame(col1 = 1:5, col2 = 6:10, col3 = 11:15)

  expect_warning(
    validate_data(bad_data, "censo_superior", 2023),
    "unexpected structure"
  )
})

test_that("validate_data passes for valid censo_superior structure", {
  good_data <- data.frame(
    co_ies = 1:5,
    no_ies = paste("IES", 1:5),
    co_uf_ies = rep(35, 5)
  )

  expect_silent(validate_data(good_data, "censo_superior", 2023))
})

test_that("validate_data passes for censo_superior course data", {
  course_data <- data.frame(
    co_curso = 101:105,
    co_ies = 1:5,
    no_curso = paste("Course", 1:5)
  )

  expect_silent(validate_data(course_data, "censo_superior", 2023))
})

test_that("list_censo_superior_files errors when not downloaded", {
  withr::with_tempdir({
    withr::local_options(educabR.cache_dir = getwd())

    expect_error(
      list_censo_superior_files(2023),
      "not downloaded"
    )
  })
})

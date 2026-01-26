# tests for download utilities

test_that("validate_year accepts valid years", {
  expect_silent(validate_year(2023, "censo_escolar"))
  expect_silent(validate_year(2023, "enem"))
  expect_silent(validate_year(2021, "ideb"))
})

test_that("validate_year rejects invalid years", {
  expect_error(
    validate_year(1990, "censo_escolar"),
    "not available"
  )

  expect_error(
    validate_year(1990, "enem"),
    "not available"
  )

  expect_error(
    validate_year(2020, "ideb"),
    "not available"
  )
})

test_that("build_inep_url returns valid URL structure", {
  url_censo <- build_inep_url("censo_escolar", 2023)
  url_enem <- build_inep_url("enem", 2023)

  expect_true(grepl("download.inep.gov.br", url_censo))
  expect_true(grepl("microdados_censo_escolar_2023", url_censo))
  expect_true(grepl("microdados_enem_2023", url_enem))
})

test_that("build_inep_url fails for unknown dataset", {
  expect_error(
    build_inep_url("invalid_dataset", 2023),
    "unknown dataset"
  )
})

test_that("uf_to_code converts abbreviations correctly", {
  expect_equal(uf_to_code("SP"), 35)
  expect_equal(uf_to_code("RJ"), 33)
  expect_equal(uf_to_code("MG"), 31)
  expect_equal(uf_to_code("BA"), 29)

  # case insensitive
  expect_equal(uf_to_code("sp"), 35)
})

test_that("uf_to_code passes through numeric codes", {
  expect_equal(uf_to_code(35), 35)
  expect_equal(uf_to_code(33), 33)
})

test_that("uf_to_code rejects invalid UF", {
  expect_error(
    uf_to_code("XX"),
    "invalid UF"
  )
})

test_that("standardize_names converts to snake_case", {
  df <- data.frame(
    `Column Name` = 1,
    `UPPERCASE` = 2,
    `Mixed.Case` = 3,
    check.names = FALSE
  )

  result <- standardize_names(df)

  expect_true(all(names(result) == tolower(names(result))))
  expect_true(!any(grepl(" ", names(result))))
  expect_true(!any(grepl("\\.", names(result))))
})

test_that("list_ideb_available returns expected structure", {
  result <- list_ideb_available()

  expect_s3_class(result, "tbl_df")
  expect_true(all(c("year", "level", "stage") %in% names(result)))
  expect_true(nrow(result) > 0)
})

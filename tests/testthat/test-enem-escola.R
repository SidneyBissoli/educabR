# tests for ENEM por Escola functions

# --- build_inep_url ---

test_that("build_inep_url returns valid ENEM por Escola URL", {
  url <- build_inep_url("enem_escola", year = NULL)

  expect_true(grepl("microdados_enem_por_escola", url))
  expect_true(grepl("download.inep.gov.br", url))
  expect_true(grepl("\\.zip$", url))
})

test_that("build_inep_url for ENEM por Escola includes 2005_a_2015 in path", {
  url <- build_inep_url("enem_escola", year = NULL)

  expect_true(grepl("2005_a_2015", url))
})

# --- validate_data ---

test_that("validate_data warns for unexpected ENEM por Escola structure", {
  bad_data <- data.frame(col1 = 1:5, col2 = 6:10, col3 = 11:15)

  expect_warning(
    validate_data(bad_data, "enem_escola", year = NULL),
    "unexpected structure"
  )
})

test_that("validate_data passes for valid ENEM por Escola structure", {
  good_data <- data.frame(
    co_escola_educacenso = 1:5,
    nu_ano = rep(2015, 5),
    no_escola = paste("School", 1:5)
  )

  expect_silent(validate_data(good_data, "enem_escola", year = NULL))
})

test_that("validate_data passes for ENEM por Escola with score columns", {
  score_data <- data.frame(
    co_escola_educacenso = 1:3,
    nu_ano = rep(2015, 3),
    no_escola = paste("School", 1:3),
    nu_media_cn = runif(3, 300, 800),
    nu_media_ch = runif(3, 300, 800),
    nu_media_lc = runif(3, 300, 800),
    nu_media_mt = runif(3, 300, 800)
  )

  expect_silent(validate_data(score_data, "enem_escola", year = NULL))
})

# --- get_enem_escola does not take a year argument ---

test_that("get_enem_escola function signature has no year param", {
  args <- names(formals(get_enem_escola))

  expect_false("year" %in% args)
  expect_true("n_max" %in% args)
  expect_true("keep_zip" %in% args)
  expect_true("quiet" %in% args)
})

# tests for ENEM functions

# --- year validation ---

test_that("validate_year accepts valid ENEM years", {
  expect_silent(validate_year(1998, "enem"))
  expect_silent(validate_year(2023, "enem"))
  expect_silent(validate_year(2024, "enem"))
})

test_that("validate_year rejects invalid ENEM years", {
  expect_error(
    validate_year(1997, "enem"),
    "not available"
  )

  expect_error(
    validate_year(2025, "enem"),
    "not available"
  )
})

test_that("fallback_years returns expected ENEM year range", {
  years <- fallback_years("enem")

  expect_true(1998 %in% years)
  expect_true(2024 %in% years)
  expect_false(1997 %in% years)
  expect_equal(length(years), 27)
})

# --- get_enem: argument validation ---

test_that("get_enem rejects invalid year", {
  expect_error(
    get_enem(1997),
    "not available"
  )

  expect_error(
    get_enem(2025),
    "not available"
  )
})

test_that("get_enem rejects invalid type", {
  expect_error(
    get_enem(2024, type = "invalido"),
    "arg"
  )
})

test_that("get_enem type parameter accepts only valid values", {
  # match.arg constrains the type parameter to valid options
  expect_error(
    get_enem(2024, type = "invalido"),
    "arg"
  )
})

# --- get_enem_itens: year validation ---

test_that("get_enem_itens rejects invalid year", {
  expect_error(
    get_enem_itens(1997),
    "not available"
  )

  expect_error(
    get_enem_itens(2025),
    "not available"
  )
})

# --- build_inep_url ---

test_that("build_inep_url returns valid ENEM URL", {
  url <- build_inep_url("enem", 2023)

  expect_true(grepl("microdados_enem_2023", url))
  expect_true(grepl("download.inep.gov.br", url))
  expect_true(grepl("\\.zip$", url))
})

test_that("build_inep_url returns valid ENEM URL for boundary years", {
  url_1998 <- build_inep_url("enem", 1998)
  expect_true(grepl("microdados_enem_1998", url_1998))

  url_2024 <- build_inep_url("enem", 2024)
  expect_true(grepl("microdados_enem_2024", url_2024))
})

# --- validate_data ---

test_that("validate_data warns for unexpected ENEM structure", {
  bad_data <- data.frame(col1 = 1:5, col2 = 6:10, col3 = 11:15)

  expect_warning(
    validate_data(bad_data, "enem", 2023),
    "no score columns"
  )
})

test_that("validate_data passes for valid ENEM structure", {
  good_data <- data.frame(
    nu_inscricao = 1:5,
    nu_nota_cn = runif(5, 300, 800),
    nu_nota_ch = runif(5, 300, 800),
    nu_nota_lc = runif(5, 300, 800),
    nu_nota_mt = runif(5, 300, 800)
  )

  expect_silent(validate_data(good_data, "enem", 2023))
})

# --- enem_summary ---

test_that("enem_summary errors when no score columns present", {
  df <- data.frame(
    tp_sexo = c("M", "F", "M"),
    co_uf = c(35, 33, 31)
  )

  expect_error(
    enem_summary(df),
    "no score columns"
  )
})

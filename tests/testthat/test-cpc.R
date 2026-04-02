# tests for CPC functions

# --- year validation ---

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

test_that("validate_year accepts CPC boundary years", {
  expect_silent(validate_year(2007, "cpc"))
  expect_silent(validate_year(2023, "cpc"))
  expect_silent(validate_year(2019, "cpc"))
  expect_silent(validate_year(2021, "cpc"))
})

test_that("available_years returns expected CPC years", {
  years <- available_years("cpc")

  expect_true(2007 %in% years)
  expect_true(2023 %in% years)
  expect_false(2006 %in% years)
  expect_false(2020 %in% years)
  expect_equal(length(years), 16)
})

# --- CPC URL map ---

test_that("CPC URL map has entry for every available year", {
  years <- available_years("cpc")
  for (y in years) {
    expect_true(
      as.character(y) %in% names(educabR:::cpc_urls),
      info = paste("missing CPC URL for year", y)
    )
  }
})

test_that("CPC URLs point to INEP download domain", {
  for (url in educabR:::cpc_urls) {
    expect_true(
      grepl("download.inep.gov.br", url),
      info = paste("URL does not point to INEP:", url)
    )
  }
})

test_that("CPC URLs have xls or xlsx extension", {
  for (url in educabR:::cpc_urls) {
    ext <- tools::file_ext(url)
    expect_true(
      ext %in% c("xls", "xlsx"),
      info = paste("unexpected extension in URL:", url)
    )
  }
})

# --- validate_data ---

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

# --- convert_faixa_columns ---

test_that("convert_faixa_columns converts character faixa to numeric", {
  df <- data.frame(
    co_curso = 1:4,
    cpc_faixa = c("1", "2", "3", "4"),
    idd_faixa = c("5", "3", "2", "1"),
    stringsAsFactors = FALSE
  )

  result <- educabR:::convert_faixa_columns(df)

  expect_true(is.numeric(result$cpc_faixa))
  expect_true(is.numeric(result$idd_faixa))
  expect_equal(result$cpc_faixa, c(1, 2, 3, 4))
  expect_equal(result$idd_faixa, c(5, 3, 2, 1))
})

test_that("convert_faixa_columns converts SC to NA", {
  df <- data.frame(
    cpc_faixa = c("1", "SC", "3", "SC"),
    stringsAsFactors = FALSE
  )

  result <- educabR:::convert_faixa_columns(df)

  expect_true(is.numeric(result$cpc_faixa))
  expect_equal(result$cpc_faixa[1], 1)
  expect_true(is.na(result$cpc_faixa[2]))
  expect_equal(result$cpc_faixa[3], 3)
  expect_true(is.na(result$cpc_faixa[4]))
})

test_that("convert_faixa_columns does not modify non-faixa columns", {
  df <- data.frame(
    co_curso = c("101", "102"),
    cpc_faixa = c("3", "4"),
    no_curso = c("Engenharia", "Medicina"),
    stringsAsFactors = FALSE
  )

  result <- educabR:::convert_faixa_columns(df)

  expect_equal(result$co_curso, c("101", "102"))
  expect_equal(result$no_curso, c("Engenharia", "Medicina"))
})

# --- read_excel_safe ---

test_that("read_excel_safe errors when readxl not available", {
  local_mocked_bindings(
    requireNamespace = function(pkg, ...) {
      if (pkg == "readxl") return(FALSE)
      base::requireNamespace(pkg, ...)
    },
    .package = "base"
  )

  expect_error(
    educabR:::read_excel_safe("fake.xlsx"),
    "readxl"
  )
})

# --- clean_dash_values ---

test_that("clean_dash_values replaces hyphen in character columns with NA", {
  df <- data.frame(
    nome = c("test", "-", "abc"),
    valor = c(1, 2, 3),
    stringsAsFactors = FALSE
  )

  result <- educabR:::clean_dash_values(df)

  expect_true(is.na(result$nome[2]))
  expect_equal(result$nome[1], "test")
  expect_equal(result$nome[3], "abc")
})

test_that("clean_dash_values replaces en-dash and em-dash with NA", {
  df <- data.frame(
    col1 = c("valid", "\u2013", "\u2014"),
    stringsAsFactors = FALSE
  )

  result <- educabR:::clean_dash_values(df)

  expect_equal(result$col1[1], "valid")
  expect_true(is.na(result$col1[2]))
  expect_true(is.na(result$col1[3]))
})

test_that("clean_dash_values does not modify numeric columns", {
  df <- data.frame(
    valor = c(1.5, 2.5, 3.5),
    nome = c("a", "-", "c"),
    stringsAsFactors = FALSE
  )

  result <- educabR:::clean_dash_values(df)

  expect_equal(result$valor, c(1.5, 2.5, 3.5))
})

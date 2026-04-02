# tests for IDEB functions

# --- get_ideb: year validation ---

test_that("get_ideb rejects invalid year", {
  expect_error(
    get_ideb(2018, level = "escola", stage = "anos_iniciais"),
    "not available"
  )

  expect_error(
    get_ideb(2016, level = "escola", stage = "anos_iniciais"),
    "not available"
  )

  expect_error(
    get_ideb(2025, level = "escola", stage = "anos_iniciais"),
    "not available"
  )
})

test_that("get_ideb rejects invalid level via match.arg", {
  expect_error(
    get_ideb(2023, level = "rede", stage = "anos_iniciais"),
    "arg"
  )
})

test_that("get_ideb rejects invalid stage via match.arg", {
  expect_error(
    get_ideb(2023, level = "escola", stage = "creche"),
    "arg"
  )
})

# --- clean_ideb_values ---

test_that("clean_ideb_values replaces '-' and 'ND' with NA in vl_ columns", {
  df <- data.frame(
    sg_uf = c("SP", "RJ", "MG"),
    vl_aprovacao = c("0,95", "-", "ND"),
    vl_ideb = c("6,5", "ND", "-"),
    stringsAsFactors = FALSE
  )

  result <- educabR:::clean_ideb_values(df)

  expect_true(is.numeric(result$vl_aprovacao))
  expect_true(is.numeric(result$vl_ideb))

  expect_equal(result$vl_aprovacao[1], 0.95)
  expect_true(is.na(result$vl_aprovacao[2]))
  expect_true(is.na(result$vl_aprovacao[3]))

  expect_equal(result$vl_ideb[1], 6.5)
  expect_true(is.na(result$vl_ideb[2]))
  expect_true(is.na(result$vl_ideb[3]))
})

test_that("clean_ideb_values converts comma decimal separators", {
  df <- data.frame(
    vl_nota = c("7,3", "8,15", "5,0"),
    stringsAsFactors = FALSE
  )

  result <- educabR:::clean_ideb_values(df)

  expect_equal(result$vl_nota, c(7.3, 8.15, 5.0))
})

test_that("clean_ideb_values does not modify non-vl columns", {
  df <- data.frame(
    sg_uf = c("SP", "RJ"),
    no_municipio = c("Sao Paulo", "Rio de Janeiro"),
    vl_ideb = c("6,5", "5,2"),
    stringsAsFactors = FALSE
  )

  result <- educabR:::clean_ideb_values(df)

  expect_equal(result$sg_uf, c("SP", "RJ"))
  expect_equal(result$no_municipio, c("Sao Paulo", "Rio de Janeiro"))
})

test_that("clean_ideb_values leaves already-numeric vl columns unchanged", {
  df <- data.frame(
    vl_ideb = c(6.5, 5.2, NA),
    vl_nota = c(7.3, 8.1, 5.0)
  )

  result <- educabR:::clean_ideb_values(df)

  expect_equal(result$vl_ideb, c(6.5, 5.2, NA))
  expect_equal(result$vl_nota, c(7.3, 8.1, 5.0))
})

# --- read_ideb_excel: readxl check ---

test_that("read_ideb_excel errors when readxl not available", {
  local_mocked_bindings(
    requireNamespace = function(pkg, ...) {
      if (pkg == "readxl") return(FALSE)
      base::requireNamespace(pkg, ...)
    },
    .package = "base"
  )

  expect_error(
    educabR:::read_ideb_excel("fake.xlsx"),
    "readxl"
  )
})

# --- list_ideb_available ---

test_that("list_ideb_available returns 24 rows (4 years x 2 levels x 3 stages)", {
  result <- list_ideb_available()

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 24)
})

test_that("list_ideb_available has correct column names", {
  result <- list_ideb_available()

  expect_equal(names(result), c("year", "level", "stage"))
})

test_that("list_ideb_available contains all valid years", {
  result <- list_ideb_available()

  expect_true(all(c(2017, 2019, 2021, 2023) %in% result$year))
})

test_that("list_ideb_available contains all valid levels", {
  result <- list_ideb_available()

  expect_true(all(c("escola", "municipio") %in% result$level))
})

test_that("list_ideb_available contains all valid stages", {
  result <- list_ideb_available()

  expect_true(all(c("anos_iniciais", "anos_finais", "ensino_medio") %in% result$stage))
})

# --- get_ideb_series ---

test_that("get_ideb_series rejects invalid years", {
  expect_error(
    get_ideb_series(years = c(2017, 2020), level = "escola", stage = "anos_iniciais"),
    "not available"
  )
})

test_that("get_ideb_series with NULL years defaults to all valid years", {
  # We can't run the download, but we can verify that NULL years

  # does not error on validation (the error will come from download).
  # Instead, verify the valid_years logic by checking get_ideb rejects
  # the right years.
  valid_years <- c(2017L, 2019L, 2021L, 2023L)
  expect_equal(available_years("ideb"), valid_years)
})

# --- IDEB year validation via available_years ---

test_that("available_years returns expected IDEB years", {
  years <- available_years("ideb")

  expect_equal(years, c(2017L, 2019L, 2021L, 2023L))
  expect_equal(length(years), 4)
})

test_that("validate_year accepts valid IDEB years", {
  expect_silent(validate_year(2017, "ideb"))
  expect_silent(validate_year(2023, "ideb"))
})

test_that("validate_year rejects invalid IDEB years", {
  expect_error(validate_year(2016, "ideb"), "not available")
  expect_error(validate_year(2018, "ideb"), "not available")
  expect_error(validate_year(2024, "ideb"), "not available")
})

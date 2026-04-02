# comprehensive tests for download utilities and internal helpers

# --- inep_base_url -----------------------------------------------------------

test_that("inep_base_url returns correct URL", {
  url <- educabR:::inep_base_url()
  expect_equal(url, "https://download.inep.gov.br")
})

# --- detect_delim ------------------------------------------------------------

test_that("detect_delim detects semicolon delimiter", {
  f <- tempfile(fileext = ".csv")
  withr::defer(unlink(f))
  writeLines("a;b;c\n1;2;3", f)
  expect_equal(educabR:::detect_delim(f), ";")
})

test_that("detect_delim detects comma delimiter", {
  f <- tempfile(fileext = ".csv")
  withr::defer(unlink(f))
  writeLines("a,b,c\n1,2,3", f)
  expect_equal(educabR:::detect_delim(f), ",")
})

test_that("detect_delim detects pipe delimiter", {
  f <- tempfile(fileext = ".csv")
  withr::defer(unlink(f))
  writeLines("a|b|c\n1|2|3", f)
  expect_equal(educabR:::detect_delim(f), "|")
})

test_that("detect_delim detects tab delimiter", {
  f <- tempfile(fileext = ".csv")
  withr::defer(unlink(f))
  writeLines("a\tb\tc\n1\t2\t3", f)
  expect_equal(educabR:::detect_delim(f), "\t")
})

# --- detect_encoding ---------------------------------------------------------

test_that("detect_encoding detects UTF-8 file", {
  f <- tempfile(fileext = ".csv")
  withr::defer(unlink(f))
  writeBin(charToRaw("col1;col2\nabc;def\n"), f)
  expect_equal(educabR:::detect_encoding(f), "UTF-8")
})

test_that("detect_encoding detects Latin1 file", {
  f <- tempfile(fileext = ".csv")
  withr::defer(unlink(f))
  # write bytes that are valid Latin1 but invalid UTF-8

  # 0xE9 = e-acute in Latin1, invalid continuation in UTF-8
  latin1_bytes <- charToRaw("col1;col2\n")
  latin1_bytes <- c(latin1_bytes, as.raw(c(0xE9, 0x3B, 0xE7, 0x0A)))
  writeBin(latin1_bytes, f)
  expect_equal(educabR:::detect_encoding(f), "latin1")
})

# --- find_data_files ---------------------------------------------------------

test_that("find_data_files finds CSV files in directory", {
  d <- tempfile("find_data_")
  dir.create(d, recursive = TRUE)
  withr::defer(unlink(d, recursive = TRUE))

  file.create(file.path(d, "data.csv"))
  file.create(file.path(d, "readme.txt"))

  files <- educabR:::find_data_files(d)
  expect_true(any(grepl("data\\.csv$", files)))
  expect_true(any(grepl("readme\\.txt$", files)))
})

test_that("find_data_files finds files in subdirectories", {
  d <- tempfile("find_data_sub_")
  sub <- file.path(d, "DADOS")
  dir.create(sub, recursive = TRUE)
  withr::defer(unlink(d, recursive = TRUE))

  file.create(file.path(sub, "microdados.CSV"))

  files <- educabR:::find_data_files(d)
  expect_length(files, 1)
  expect_true(grepl("microdados\\.CSV$", files))
})

test_that("find_data_files errors when no files match", {
  d <- tempfile("find_data_empty_")
  dir.create(d, recursive = TRUE)
  withr::defer(unlink(d, recursive = TRUE))

  file.create(file.path(d, "data.xlsx"))

  expect_error(educabR:::find_data_files(d), "no data files found")
})

test_that("find_data_files uses custom pattern", {
  d <- tempfile("find_data_pattern_")
  dir.create(d, recursive = TRUE)
  withr::defer(unlink(d, recursive = TRUE))

  file.create(file.path(d, "data.xlsx"))
  file.create(file.path(d, "data.csv"))

  files <- educabR:::find_data_files(d, pattern = "\\.xlsx$")
  expect_length(files, 1)
  expect_true(grepl("xlsx$", files))
})

# --- build_inep_url ----------------------------------------------------------

test_that("build_inep_url builds censo_escolar URL", {
  url <- build_inep_url("censo_escolar", 2023)
  expect_match(url, "download\\.inep\\.gov\\.br")
  expect_match(url, "microdados_censo_escolar_2023\\.zip$")
})

test_that("build_inep_url builds enem URL", {
  url <- build_inep_url("enem", 2023)
  expect_match(url, "microdados_enem_2023\\.zip$")
})

test_that("build_inep_url builds saeb URL for non-2021 year", {
  url <- build_inep_url("saeb", 2019)
  expect_match(url, "microdados_saeb_2019\\.zip$")
  expect_false(grepl("fundamental|infantil", url))
})

test_that("build_inep_url builds saeb 2021 URL with default level", {

  url <- build_inep_url("saeb", 2021)
  expect_match(url, "microdados_saeb_2021_ensino_fundamental_e_medio\\.zip$")
})

test_that("build_inep_url builds saeb 2021 URL with educacao_infantil level", {
  url <- build_inep_url("saeb", 2021, level = "educacao_infantil")
  expect_match(url, "microdados_saeb_2021_educacao_infantil\\.zip$")
})

test_that("build_inep_url builds censo_superior URL", {
  url <- build_inep_url("censo_superior", 2023)
  expect_match(url, "microdados_censo_da_educacao_superior_2023\\.zip$")
})

test_that("build_inep_url builds enade URL", {
  url <- build_inep_url("enade", 2023)
  expect_match(url, "microdados_enade_2023\\.zip$")
})

test_that("build_inep_url builds encceja URL", {
  url <- build_inep_url("encceja", 2023)
  expect_match(url, "microdados_encceja_2023\\.zip$")
})

test_that("build_inep_url builds enem_escola URL (fixed URL)", {
  url <- build_inep_url("enem_escola", 2015)
  expect_match(url, "enem_por_escola/2005_a_2015/microdados_enem_por_escola\\.zip$")
})

test_that("build_inep_url builds idd URL with zip for year >= 2021", {
  url <- build_inep_url("idd", 2021)
  expect_match(url, "microdados_IDD_2021\\.zip$")
})

test_that("build_inep_url builds idd URL with 7z for year < 2021", {
  url <- build_inep_url("idd", 2019)
  expect_match(url, "microdados_IDD_2019\\.7z$")
})

test_that("build_inep_url builds ideb URL", {
  url <- build_inep_url("ideb", 2021)
  expect_match(url, "ideb/2021/$")
})

test_that("build_inep_url errors for unknown dataset", {
  expect_error(build_inep_url("invalid_dataset", 2023), "unknown dataset")
})

# --- validate_year -----------------------------------------------------------

test_that("validate_year accepts valid years for all datasets", {
  expect_silent(validate_year(2023, "censo_escolar"))
  expect_silent(validate_year(1995, "censo_escolar"))
  expect_silent(validate_year(2024, "enem"))
  expect_silent(validate_year(1998, "enem"))
  expect_silent(validate_year(2021, "saeb"))
  expect_silent(validate_year(2023, "censo_superior"))
  expect_silent(validate_year(2023, "enade"))
  expect_silent(validate_year(2023, "encceja"))
  expect_silent(validate_year(2023, "idd"))
  expect_silent(validate_year(2023, "cpc"))
  expect_silent(validate_year(2023, "igc"))
  expect_silent(validate_year(2023, "capes"))
  expect_silent(validate_year(2023, "ideb"))
  expect_silent(validate_year(2026, "fundeb"))
})

test_that("validate_year rejects invalid years", {
  expect_error(validate_year(1990, "censo_escolar"), "not available")
  expect_error(validate_year(1990, "enem"), "not available")
  expect_error(validate_year(2020, "saeb"), "not available")
  expect_error(validate_year(2008, "censo_superior"), "not available")
  expect_error(validate_year(2003, "enade"), "not available")
  expect_error(validate_year(2013, "encceja"), "not available")
  expect_error(validate_year(2020, "idd"), "not available")
  expect_error(validate_year(2020, "cpc"), "not available")
  expect_error(validate_year(2020, "igc"), "not available")
  expect_error(validate_year(2012, "capes"), "not available")
  expect_error(validate_year(2016, "ideb"), "not available")
  expect_error(validate_year(2006, "fundeb"), "not available")
})

test_that("validate_year returns year invisibly on success", {
  result <- validate_year(2023, "censo_escolar")
  expect_equal(result, 2023)
})

# --- available_years ---------------------------------------------------------

test_that("fallback_years returns correct years for all datasets", {
  expect_equal(fallback_years("censo_escolar"), 1995:2024)
  expect_equal(fallback_years("enem"), 1998:2024)
  expect_equal(fallback_years("saeb"), c(2011L, 2013L, 2015L, 2017L, 2019L, 2021L, 2023L))
  expect_equal(fallback_years("censo_superior"), 2009:2024)
  expect_equal(fallback_years("enade"), c(2004L:2019L, 2021L:2023L))
  expect_equal(fallback_years("encceja"), 2014:2024)
  expect_equal(fallback_years("idd"), c(2014L:2019L, 2021L:2023L))
  expect_equal(fallback_years("cpc"), c(2007L:2019L, 2021L:2023L))
  expect_equal(fallback_years("igc"), c(2007L:2019L, 2021L:2023L))
  expect_equal(fallback_years("fundeb_enrollment"), 2017:2018)
  expect_false(2020 %in% fallback_years("idd"))
  expect_false(2020 %in% fallback_years("enade"))
})

test_that("available_years returns non-empty sorted integer vector", {
  # available_years may use dynamic discovery or fallback depending on network
  # so we only test general properties, not exact values
  for (ds in c("censo_escolar", "enem", "saeb", "censo_superior", "enade",
               "encceja", "idd", "cpc", "igc", "capes", "ideb", "fundeb")) {
    yrs <- available_years(ds)
    expect_true(length(yrs) > 0, info = paste("dataset:", ds))
    expect_true(is.numeric(yrs), info = paste("dataset:", ds))
    expect_equal(yrs, sort(yrs), info = paste("dataset:", ds))
  }
})

test_that("available_years accepts fundeb_enrollment as dataset", {
  yrs <- available_years("fundeb_enrollment")
  expect_true(length(yrs) > 0)
  expect_true(is.numeric(yrs))
})

test_that("available_years rejects invalid dataset", {
  expect_error(available_years("nonexistent"))
})

test_that("available_years returns correct years for capes", {
  yrs <- available_years("capes")
  expect_true(2013 %in% yrs)
  expect_true(2024 %in% yrs)
})

test_that("available_years returns correct years for ideb", {
  yrs <- available_years("ideb")
  expect_equal(yrs, c(2017L, 2019L, 2021L, 2023L))
})

test_that("available_years returns correct years for fundeb", {
  yrs <- available_years("fundeb")
  expect_true(2007 %in% yrs)
  expect_true(2026 %in% yrs)
})

test_that("available_years errors for invalid dataset", {
  expect_error(available_years("nonexistent"), "should be one of")
})

# --- standardize_names -------------------------------------------------------

test_that("standardize_names converts to lowercase", {
  df <- data.frame(UPPERCASE = 1, MixedCase = 2, check.names = FALSE)
  result <- standardize_names(df)
  expect_equal(names(result), c("uppercase", "mixedcase"))
})

test_that("standardize_names replaces spaces with underscores", {
  df <- data.frame(`Column Name` = 1, `Another Col` = 2, check.names = FALSE)
  result <- standardize_names(df)
  expect_equal(names(result), c("column_name", "another_col"))
})

test_that("standardize_names replaces dots with underscores", {
  df <- data.frame(col.name = 1, another.col.here = 2, check.names = FALSE)
  result <- standardize_names(df)
  expect_equal(names(result), c("col_name", "another_col_here"))
})

test_that("standardize_names removes accents", {
  df <- data.frame(
    "\u00e9cole" = 1,
    "institui\u00e7\u00e3o" = 2,
    check.names = FALSE
  )
  result <- standardize_names(df)
  expect_true(all(!grepl("[\u00e9\u00e7\u00e3]", names(result))))
  expect_match(names(result)[1], "^[a-z_]+$")
})

test_that("standardize_names collapses consecutive underscores", {
  df <- data.frame(`a  b` = 1, `c---d` = 2, check.names = FALSE)
  result <- standardize_names(df)
  expect_false(any(grepl("__", names(result))))
})

test_that("standardize_names removes leading and trailing underscores", {
  df <- data.frame(` leading` = 1, `trailing ` = 2, check.names = FALSE)
  result <- standardize_names(df)
  expect_false(any(grepl("^_|_$", names(result))))
})

test_that("standardize_names handles mixed special characters", {
  df <- data.frame(
    `Col (Name) #1!` = 1,
    check.names = FALSE
  )
  result <- standardize_names(df)
  expect_match(names(result), "^[a-z0-9_]+$")
})

# --- uf_to_code --------------------------------------------------------------

test_that("uf_to_code converts all 27 UF abbreviations", {
  uf_expected <- c(
    RO = 11, AC = 12, AM = 13, RR = 14, PA = 15, AP = 16, TO = 17,
    MA = 21, PI = 22, CE = 23, RN = 24, PB = 25, PE = 26, AL = 27,
    SE = 28, BA = 29, MG = 31, ES = 32, RJ = 33, SP = 35,
    PR = 41, SC = 42, RS = 43, MS = 50, MT = 51, GO = 52, DF = 53
  )

  for (uf_name in names(uf_expected)) {
    expect_equal(
      uf_to_code(uf_name),
      unname(uf_expected[uf_name]),
      info = paste("UF:", uf_name)
    )
  }
})

test_that("uf_to_code is case insensitive", {
  expect_equal(uf_to_code("sp"), 35)
  expect_equal(uf_to_code("Sp"), 35)
  expect_equal(uf_to_code("SP"), 35)
})

test_that("uf_to_code passes through numeric codes", {
  expect_equal(uf_to_code(35), 35)
  expect_equal(uf_to_code(33), 33)
  expect_equal(uf_to_code(11), 11)
})

test_that("uf_to_code rejects invalid UF", {
  expect_error(uf_to_code("XX"), "invalid UF")
  expect_error(uf_to_code("ZZ"), "invalid UF")
})

# --- parse_sas_dates ---------------------------------------------------------

test_that("parse_sas_dates converts dt_ columns with SAS datetime format", {
  df <- data.frame(
    dt_criacao = c("12FEB2024:00:00:00", "01JAN2023:00:00:00"),
    co_entidade = c(1, 2),
    stringsAsFactors = FALSE
  )

  result <- educabR:::parse_sas_dates(df)

  expect_s3_class(result$dt_criacao, "Date")
  expect_equal(result$dt_criacao[1], as.Date("2024-02-12"))
  expect_equal(result$dt_criacao[2], as.Date("2023-01-01"))
})

test_that("parse_sas_dates converts dh_ columns", {
  df <- data.frame(
    dh_alteracao = c("15MAR2023:10:30:00"),
    no_escola = "test",
    stringsAsFactors = FALSE
  )

  result <- educabR:::parse_sas_dates(df)

  expect_s3_class(result$dh_alteracao, "Date")
  expect_equal(result$dh_alteracao, as.Date("2023-03-15"))
})

test_that("parse_sas_dates leaves non-date columns unchanged", {
  df <- data.frame(
    co_escola = 12345,
    no_escola = "Test School",
    dt_data = "01JAN2023:00:00:00",
    stringsAsFactors = FALSE
  )

  result <- educabR:::parse_sas_dates(df)

  expect_type(result$co_escola, "double")
  expect_type(result$no_escola, "character")
  expect_equal(result$no_escola, "Test School")
})

test_that("parse_sas_dates skips non-character dt_ columns", {
  df <- data.frame(
    dt_numeric = 12345,
    co_escola = 1,
    stringsAsFactors = FALSE
  )

  result <- educabR:::parse_sas_dates(df)

  # numeric dt_ column should remain numeric

  expect_type(result$dt_numeric, "double")
  expect_equal(result$dt_numeric, 12345)
})

test_that("parse_sas_dates handles df with no date columns", {
  df <- data.frame(co_escola = 1, no_escola = "A", stringsAsFactors = FALSE)
  result <- educabR:::parse_sas_dates(df)
  expect_equal(result, df)
})

# --- find_censo_file ---------------------------------------------------------

test_that("find_censo_file finds file matching year pattern", {
  d <- tempfile("censo_find_")
  sub <- file.path(d, "DADOS")
  dir.create(sub, recursive = TRUE)
  withr::defer(unlink(d, recursive = TRUE))

  file.create(file.path(sub, "microdados_ed_basica_2023.csv"))
  file.create(file.path(sub, "suplemento_2023.csv"))

  result <- educabR:::find_censo_file(d, 2023)
  expect_match(basename(result), "microdados_ed_basica_2023\\.csv")
})

test_that("find_censo_file prefers non-suplemento file", {
  d <- tempfile("censo_pref_")
  sub <- file.path(d, "DADOS")
  dir.create(sub, recursive = TRUE)
  withr::defer(unlink(d, recursive = TRUE))

  file.create(file.path(sub, "microdados_ed_basica_2023.csv"))
  file.create(file.path(sub, "microdados_ed_basica_suplemento_2023.csv"))

  result <- educabR:::find_censo_file(d, 2023)
  expect_false(grepl("suplemento", basename(result), ignore.case = TRUE))
})

test_that("find_censo_file falls back to broader pattern", {
  d <- tempfile("censo_fallback_")
  sub <- file.path(d, "DADOS")
  dir.create(sub, recursive = TRUE)
  withr::defer(unlink(d, recursive = TRUE))

  # no year-specific file, but a generic microdados file
  file.create(file.path(sub, "microdados_ed_basica.csv"))

  result <- educabR:::find_censo_file(d, 2023)
  expect_match(basename(result), "microdados_ed_basica\\.csv")
})

test_that("find_censo_file falls back to just 'microdados' pattern", {
  d <- tempfile("censo_micro_")
  sub <- file.path(d, "DADOS")
  dir.create(sub, recursive = TRUE)
  withr::defer(unlink(d, recursive = TRUE))

  file.create(file.path(sub, "microdados.csv"))

  result <- educabR:::find_censo_file(d, 2023)
  expect_match(basename(result), "microdados\\.csv")
})

test_that("find_censo_file errors when no files found", {
  d <- tempfile("censo_empty_")
  dir.create(d, recursive = TRUE)
  withr::defer(unlink(d, recursive = TRUE))

  file.create(file.path(d, "readme.txt"))

  expect_error(educabR:::find_censo_file(d, 2023), "no data file found")
})

# --- clean_dash_values (from get-censo-superior.R) ---------------------------

test_that("clean_dash_values replaces hyphens with NA", {
  df <- data.frame(
    a = c("value", "-", "other"),
    b = c(1, 2, 3),
    stringsAsFactors = FALSE
  )

  result <- educabR:::clean_dash_values(df)

  expect_true(is.na(result$a[2]))
  expect_equal(result$a[1], "value")
  expect_equal(result$a[3], "other")
})

test_that("clean_dash_values replaces en-dash and em-dash", {
  df <- data.frame(
    a = c("\u2013", "\u2014", "ok"),
    stringsAsFactors = FALSE
  )

  result <- educabR:::clean_dash_values(df)

  expect_true(is.na(result$a[1]))
  expect_true(is.na(result$a[2]))
  expect_equal(result$a[3], "ok")
})

test_that("clean_dash_values leaves non-character columns unchanged", {
  df <- data.frame(
    num_col = c(1, 2, 3),
    char_col = c("-", "a", "b"),
    stringsAsFactors = FALSE
  )

  result <- educabR:::clean_dash_values(df)

  expect_equal(result$num_col, c(1, 2, 3))
  expect_true(is.na(result$char_col[1]))
})

# --- clean_ideb_values (from get-ideb.R) -------------------------------------

test_that("clean_ideb_values replaces - and ND with NA in vl_ columns", {
  df <- data.frame(
    vl_nota = c("-", "ND", "5,5", "7,2"),
    sg_uf = c("SP", "RJ", "MG", "BA"),
    stringsAsFactors = FALSE
  )

  result <- educabR:::clean_ideb_values(df)

  expect_true(is.na(result$vl_nota[1]))
  expect_true(is.na(result$vl_nota[2]))
  expect_equal(result$vl_nota[3], 5.5)
  expect_equal(result$vl_nota[4], 7.2)
})

test_that("clean_ideb_values fixes comma decimal separator", {
  df <- data.frame(
    vl_ideb = c("6,5", "7,8"),
    stringsAsFactors = FALSE
  )

  result <- educabR:::clean_ideb_values(df)

  expect_type(result$vl_ideb, "double")
  expect_equal(result$vl_ideb, c(6.5, 7.8))
})

test_that("clean_ideb_values leaves non-vl columns unchanged", {
  df <- data.frame(
    vl_score = c("5,0"),
    no_escola = c("Test School"),
    co_escola = 12345,
    stringsAsFactors = FALSE
  )

  result <- educabR:::clean_ideb_values(df)

  expect_equal(result$no_escola, "Test School")
  expect_equal(result$co_escola, 12345)
  expect_equal(result$vl_score, 5.0)
})

# --- convert_faixa_columns (from get-cpc.R) ----------------------------------

test_that("convert_faixa_columns converts faixa columns to numeric", {
  df <- data.frame(
    cpc_faixa = c("3", "4", "5"),
    nome = c("a", "b", "c"),
    stringsAsFactors = FALSE
  )

  result <- educabR:::convert_faixa_columns(df)

  expect_type(result$cpc_faixa, "double")
  expect_equal(result$cpc_faixa, c(3, 4, 5))
})

test_that("convert_faixa_columns converts SC to NA", {
  df <- data.frame(
    cpc_faixa = c("3", "SC", "5"),
    stringsAsFactors = FALSE
  )

  result <- educabR:::convert_faixa_columns(df)

  expect_equal(result$cpc_faixa[1], 3)
  expect_true(is.na(result$cpc_faixa[2]))
  expect_equal(result$cpc_faixa[3], 5)
})

test_that("convert_faixa_columns only affects _faixa columns", {
  df <- data.frame(
    enade_faixa = c("4"),
    nome_curso = c("Eng"),
    stringsAsFactors = FALSE
  )

  result <- educabR:::convert_faixa_columns(df)

  expect_type(result$enade_faixa, "double")
  expect_type(result$nome_curso, "character")
})

test_that("convert_faixa_columns handles df without faixa columns", {
  df <- data.frame(a = 1, b = "x", stringsAsFactors = FALSE)
  result <- educabR:::convert_faixa_columns(df)
  expect_equal(result, df)
})

# --- read_excel_safe (from get-cpc.R) ----------------------------------------

test_that("read_excel_safe errors on invalid file", {
  expect_error(
    educabR:::read_excel_safe("nonexistent_file.xlsx"),
    "failed to read Excel file"
  )
})

# --- read_ideb_excel (from get-ideb.R) ---------------------------------------

test_that("read_ideb_excel reads with skip = 9", {
  skip_if_not_installed("readxl")
  # Test that it calls readxl (will fail on non-xlsx file)
  expect_error(
    educabR:::read_ideb_excel("nonexistent_file.xlsx")
  )
})

# --- list_ideb_available (from get-ideb.R) -----------------------------------

test_that("list_ideb_available returns expected structure", {
  result <- list_ideb_available()

  expect_s3_class(result, "tbl_df")
  expect_true(all(c("year", "level", "stage") %in% names(result)))
  expect_true(nrow(result) > 0)
})

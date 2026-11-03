# tests for get_conceito_enade()

setup_temp_cache <- function(env = parent.frame()) {
  temp_cache <- withr::local_tempdir(.local_envir = env)
  withr::local_options(educabR.cache_dir = temp_cache, .local_envir = env)
  educabR::set_cache_dir(temp_cache)
  temp_cache
}

mock_download <- function(url, destfile, quiet = FALSE) {
  dir.create(dirname(destfile), recursive = TRUE, showWarnings = FALSE)
  file.create(destfile)
  destfile
}

# --- years and sources ---

test_that("available_years covers 2004-2019, 2021-2023 and 2025", {
  expect_equal(
    available_years("conceito_enade"),
    c(2004:2019, 2021:2023, 2025)
  )
})

test_that("validate_year rejects years with no edition", {
  expect_error(validate_year(2020, "conceito_enade"), "not available")
  expect_error(validate_year(2024, "conceito_enade"), "not available")
  expect_error(validate_year(2003, "conceito_enade"), "not available")
})

test_that("every year without its own spreadsheet uses the CPC table", {
  own <- as.integer(names(educabR:::conceito_enade_urls))
  borrowed <- setdiff(available_years("conceito_enade"), c(own, 2025))

  expect_equal(borrowed, 2007:2011)
  for (y in borrowed) {
    expect_equal(
      educabR:::conceito_enade_source(y)$url,
      educabR:::cpc_urls[[as.character(y)]]
    )
  }
})

test_that("Conceito Enade URLs point to INEP download domain", {
  urls <- c(
    educabR:::conceito_enade_urls,
    educabR:::conceito_enade_2025_urls
  )
  expect_true(all(startsWith(urls, "https://download.inep.gov.br/")))
})

test_that("the 2021 edition reads the data sheet, not the first sheet", {
  expect_equal(educabR:::conceito_enade_source(2021)$sheet, "PLANILHA_ENADE")
  expect_equal(educabR:::conceito_enade_source(2023)$sheet, 1)
})

test_that("2025 requires type and other years reject it", {
  expect_error(educabR:::conceito_enade_source(2025), "two files")
  expect_match(
    educabR:::conceito_enade_source(2025, "medicina")$url,
    "medicina"
  )
  expect_match(
    educabR:::conceito_enade_source(2025, "lic")$url,
    "licenciaturas"
  )
  expect_error(
    educabR:::conceito_enade_source(2023, "medicina"),
    "only applies to the 2025"
  )
})

# --- pipeline ---

test_that("get_conceito_enade returns a tidy tibble", {
  temp_cache <- setup_temp_cache()
  sheets <- list()

  local_mocked_bindings(
    download_inep_file = mock_download,
    read_excel_safe = function(file, n_max = Inf, sheet = 1) {
      sheets[[length(sheets) + 1]] <<- sheet
      dplyr::tibble(
        Ano = c(2021, 2021),
        `Código da IES` = c("1", "2"),
        `Conceito Enade (Contínuo)` = c("3.2", "SC"),
        `Conceito Enade (Faixa)` = c("4", "SC")
      )
    },
    .package = "educabR"
  )

  result <- get_conceito_enade(2021, quiet = TRUE)

  expect_s3_class(result, "tbl_df")
  expect_equal(sheets[[1]], "PLANILHA_ENADE")
  expect_true("codigo_da_ies" %in% names(result))
  expect_equal(result$conceito_enade_faixa, c(4, NA))
  expect_equal(result$conceito_enade_continuo, c(3.2, NA))
})

test_that("get_conceito_enade caches the two 2025 files separately", {
  temp_cache <- setup_temp_cache()
  downloaded <- character()

  local_mocked_bindings(
    download_inep_file = function(url, destfile, quiet = FALSE) {
      downloaded <<- c(downloaded, basename(destfile))
      mock_download(url, destfile, quiet)
    },
    read_excel_safe = function(file, n_max = Inf, sheet = 1) {
      dplyr::tibble(ANO = 2025, CODIGO_DA_IES = "1", CONCEITO_ENADE_FAIXA = "3")
    },
    .package = "educabR"
  )

  get_conceito_enade(2025, type = "licenciaturas", quiet = TRUE)
  get_conceito_enade(2025, type = "medicina", quiet = TRUE)
  get_conceito_enade(2025, type = "medicina", quiet = TRUE)

  expect_equal(
    downloaded,
    c(
      "conceito_enade_2025_licenciaturas.xlsx",
      "conceito_enade_2025_medicina.xlsx"
    )
  )
})

test_that("get_conceito_enade with keep_file = FALSE removes the file", {
  temp_cache <- setup_temp_cache()

  local_mocked_bindings(
    download_inep_file = mock_download,
    read_excel_safe = function(file, n_max = Inf, sheet = 1) {
      dplyr::tibble(ANO = 2025, CODIGO_DA_IES = "1", CONCEITO_ENADE_FAIXA = "3")
    },
    .package = "educabR"
  )

  get_conceito_enade(2023, keep_file = FALSE, quiet = TRUE)

  expect_false(file.exists(
    educabR:::cache_path("conceito_enade", "conceito_enade_2023.xlsx")
  ))
})

test_that("validate_data warns for unexpected Conceito Enade structure", {
  expect_warning(
    validate_data(data.frame(x = 1, y = 2, z = 3), "conceito_enade", 2023),
    "unexpected structure"
  )
  expect_silent(
    validate_data(
      data.frame(ano = 2023, codigo_da_ies = 1, conceito_enade_faixa = 3),
      "conceito_enade",
      2023
    )
  )
})

test_that("standardize_names drops superscript footnote marks", {
  # 2025 headers: "Nome da IES¹", "Sigla da IES ¹"
  df <- data.frame(1, 2, 3)
  names(df) <- c(
    "Nome da IES¹",
    "Sigla da IES ¹",
    "Acima do Padrão 1"
  )

  expect_equal(
    names(educabR:::standardize_names(df)),
    c("nome_da_ies", "sigla_da_ies", "acima_do_padrao_1")
  )
})

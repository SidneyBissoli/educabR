# tests for IGC tables split by type of institution (2007-2016)

# helper: isolated cache dir for each test
setup_temp_cache <- function(env = parent.frame()) {
  temp_cache <- withr::local_tempdir(.local_envir = env)
  withr::local_options(educabR.cache_dir = temp_cache, .local_envir = env)
  educabR::set_cache_dir(temp_cache)
  temp_cache
}

test_that("igc_institution_sheets keeps only the institution sheets", {
  local_mocked_bindings(
    excel_sheets = function(path) {
      c(
        "Universidades e IFET",
        "Centros Univ e Cefet",
        "Faculdades",
        "Unidades com CPC 2013 e 2014",
        "Cursos com CPC 2015"
      )
    },
    .package = "readxl"
  )

  expect_equal(
    educabR:::igc_institution_sheets("igc.xlsx"),
    c("Universidades e IFET", "Centros Univ e Cefet", "Faculdades")
  )
})

test_that("igc_institution_sheets handles accents and the Outros sheet", {
  local_mocked_bindings(
    excel_sheets = function(path) {
      c(
        "Universidade",
        "Centro Universitário",
        "Outros",
        "Cursos com CPC (2006-2007-2008)"
      )
    },
    .package = "readxl"
  )

  expect_length(educabR:::igc_institution_sheets("igc.xlsx"), 3)
})

test_that("igc_institution_sheets falls back to the first sheet", {
  local_mocked_bindings(
    excel_sheets = function(path) c("IGC_2019", "CPC_2017_2018_2019"),
    .package = "readxl"
  )

  expect_equal(educabR:::igc_institution_sheets("igc.xlsx"), "IGC_2019")
})

test_that("bind_igc_parts stacks sheets with differently worded headers", {
  # IGC 2010: same column, "Porcentagem de" in one sheet and "%" in others
  a <- dplyr::tibble(
    `Código da IES` = 1,
    `Porcentagem de mestrandos` = 0.1
  )
  b <- dplyr::tibble(
    `Código da IES` = 2:3,
    `% de mestrandos` = c(0.2, 0.3)
  )

  result <- educabR:::bind_igc_parts(list(a, b))

  expect_equal(nrow(result), 3)
  expect_equal(names(result), names(a))
  expect_equal(result[[2]], c(0.1, 0.2, 0.3))
})

test_that("bind_igc_parts binds by name when widths differ", {
  # IGC 2015: only one sheet has the observation column
  a <- dplyr::tibble(cod = 1, igc = 3.1, obs = "x")
  b <- dplyr::tibble(cod = 2, igc = 2.5)

  result <- educabR:::bind_igc_parts(list(a, b))

  expect_equal(result$igc, c(3.1, 2.5))
  expect_equal(result$obs, c("x", NA))
})

test_that("bind_igc_parts turns conflicting types into character", {
  a <- dplyr::tibble(cod = 1, igc = 3.1, vazio = NA)
  b <- dplyr::tibble(cod = 2, igc = "sub judice", vazio = 4)

  result <- educabR:::bind_igc_parts(list(a, b))

  expect_equal(result$igc, c("3.1", "sub judice"))
  # an all-empty (logical) column does not force character
  expect_equal(result$vazio, c(NA, 4))
})

test_that("get_igc stacks every institution sheet", {
  temp_cache <- setup_temp_cache()
  sheets_read <- character()

  local_mocked_bindings(
    download_inep_file = function(url, destfile, quiet = FALSE) {
      dir.create(dirname(destfile), recursive = TRUE, showWarnings = FALSE)
      file.create(destfile)
      destfile
    },
    igc_institution_sheets = function(file) {
      c("Universidades", "Centros Universitários", "Faculdades")
    },
    read_excel_safe = function(file, n_max = Inf, sheet = 1) {
      sheets_read <<- c(sheets_read, sheet)
      dplyr::tibble(
        CO_IES = as.character(length(sheets_read)),
        NO_IES = sheet,
        IGC_CONTINUO = 3,
        IGC_FAIXA = "3"
      )
    },
    .package = "educabR"
  )

  result <- get_igc(2010, quiet = TRUE)

  expect_length(sheets_read, 3)
  expect_equal(nrow(result), 3)
  expect_equal(result$co_ies, c("1", "2", "3"))
})

test_that("get_igc 2007 reads and stacks the CSV of each institution type", {
  temp_cache <- setup_temp_cache()

  header <- "Ano;Cód. IES;IES;IGC - Contínuo;IGC - Faixas"
  csvs <- list(
    "igc_2007 - Universidade.csv" = c(header, "2007;1;UNIV A;290;3"),
    "igc_2007 - Centro Universitario.csv" = c(header, "2007;23;CENTRO B;315;4"),
    "igc_2007 - Outros.csv" = c(header, "2007;41;FACULDADE C;-;-")
  )

  local_mocked_bindings(
    download_inep_file = function(url, destfile, quiet = FALSE) {
      dir.create(dirname(destfile), recursive = TRUE, showWarnings = FALSE)
      file.create(destfile)
      destfile
    },
    extract_archive = function(archive, exdir, quiet = FALSE) {
      dir.create(exdir, recursive = TRUE, showWarnings = FALSE)
      for (nm in names(csvs)) {
        con <- file(file.path(exdir, nm), open = "w", encoding = "latin1")
        writeLines(csvs[[nm]], con)
        close(con)
      }
      exdir
    },
    .package = "educabR"
  )

  result <- get_igc(2007, quiet = TRUE)

  expect_equal(nrow(result), 3)
  expect_setequal(result$ies, c("UNIV A", "CENTRO B", "FACULDADE C"))
  expect_true(is.numeric(result$igc_continuo))
  expect_equal(sum(is.na(result$igc_faixas)), 1)
})

test_that("convert_faixa_columns converts faixas and continuo text", {
  # stacking IGC sheets turns these into text when one sheet has a marker
  df <- data.frame(
    igc_continuo = c("2.85", "sub judice", "."),
    igc_faixas = c("3", "SC", "4"),
    sigla = c("A", "B", "C"),
    stringsAsFactors = FALSE
  )

  result <- educabR:::convert_faixa_columns(df)

  expect_equal(result$igc_continuo, c(2.85, NA, NA))
  expect_equal(result$igc_faixas, c(3, NA, 4))
  expect_type(result$sigla, "character")
})

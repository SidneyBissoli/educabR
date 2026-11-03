# tests for INEP spreadsheet layout quirks handled by read_excel_safe()
# and for name collisions in standardize_names()

test_that("drop_footer_rows drops blank, footnote and total rows", {
  # CPC 2021: blank row + footnotes in column 1; CPC 2022: a lone total
  df <- data.frame(
    ano = c("2021", "2021", NA, "* Nome, sigla e codigo da IES ...", NA),
    co_ies = c("1", "2", NA, NA, NA),
    cebas = c("x", NA, NA, NA, "9891"),
    stringsAsFactors = FALSE
  )

  result <- educabR:::drop_footer_rows(df)

  expect_equal(nrow(result), 2)
  expect_equal(result$co_ies, c("1", "2"))
})

test_that("merge_subheader_row completes names from a second header row", {
  # IGC 2008: "IGC" over "Continuo" and "Faixas"; "COD. IES" repeated
  # the real sheet has 10 columns; the sub-header fills only 3 of them
  df <- dplyr::tibble(
    Ano = c(NA, "2008", "2008"),
    `Cód. IES` = c("CÓD. IES", "1", "2"),
    IES = c(NA, "UNIV A", "UNIV B"),
    Sigla = c(NA, "UA", "UB"),
    UF = c(NA, "MT", "DF"),
    Dep = c(NA, "Federal", "Federal"),
    Cursos = c(NA, "70", "39"),
    IGC = c("Contínuo", "285", "389"),
    x = c("Faixas", "3", "4")
  )
  names(df)[9] <- ""

  result <- educabR:::merge_subheader_row(df)

  expect_equal(nrow(result), 2)
  expect_equal(
    names(result)[c(1, 2, 8, 9)],
    c("Ano", "Cód. IES", "IGC Contínuo", "IGC Faixas")
  )
  # columns outside the sub-header keep their type
  expect_type(result$Cursos, "character")
  expect_equal(result[["IGC Contínuo"]], c(285, 389))
  expect_equal(result[["IGC Faixas"]], c(3, 4))
})

test_that("merge_subheader_row leaves ordinary data untouched", {
  df <- dplyr::tibble(ano = c(2023, 2023), sigla = c("UFMT", "UnB"))

  expect_identical(educabR:::merge_subheader_row(df), df)
})

test_that("excel_header_skip skips a title row above the header", {
  # IGC 2009: a title in A1, the header in row 2
  local_mocked_bindings(
    read_excel = function(
      path,
      sheet = NULL,
      col_names = TRUE,
      n_max = Inf,
      ...
    ) {
      dplyr::tibble(
        a = c("Indice Geral de Cursos - IGC 2009", "Ano", "2009"),
        b = c(NA, "Codigo da IES", "1"),
        c = c(NA, "IES", "UNIV A")
      )
    },
    .package = "readxl"
  )

  expect_equal(educabR:::excel_header_skip("igc.xls"), 1L)
})

test_that("excel_header_skip returns 0 when the header is the first row", {
  local_mocked_bindings(
    read_excel = function(
      path,
      sheet = NULL,
      col_names = TRUE,
      n_max = Inf,
      ...
    ) {
      dplyr::tibble(a = c("Ano", "2023"), b = c("CO_IES", "1"))
    },
    .package = "readxl"
  )

  expect_equal(educabR:::excel_header_skip("cpc.xlsx"), 0L)
})

test_that("standardize_names keeps the percent sign as pct on collisions", {
  # CPC 2007/2008: "Docentes Doutores" and "% Docentes Doutores"
  df <- dplyr::tibble(
    `Docentes Doutores` = 1,
    `% Docentes Doutores` = 0.5,
    `% avaliam bem o plano` = 0.2
  )

  result <- educabR:::standardize_names(df)

  expect_equal(
    names(result),
    c("docentes_doutores", "pct_docentes_doutores", "avaliam_bem_o_plano")
  )
})

test_that("standardize_names suffixes remaining collisions", {
  df <- data.frame(1, 2, 3, 4)
  names(df) <- c("Nota", "nota", "", "")

  result <- educabR:::standardize_names(df)

  expect_equal(names(result), c("nota", "nota_2", "", "unnamed_2"))
})

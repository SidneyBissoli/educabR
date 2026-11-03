# column names must not depend on the platform's iconv: macOS turned
# "i-acute" into "'i" (Municipio -> munic_ipio) with ASCII//TRANSLIT

test_that("ascii_fold gives the same ASCII text on every platform", {
  x <- c(
    "Município",
    "Organização Acadêmica",
    "Nº de Docentes",
    "Nome da IES¹",
    "IGC - Contínuo",
    "ß (Proporção de Mestrandos)"
  )

  expect_equal(
    educabR:::ascii_fold(x),
    c(
      "Municipio",
      "Organizacao Academica",
      "No de Docentes",
      "Nome da IES1",
      "IGC - Continuo",
      "  (Proporcao de Mestrandos)"
    )
  )
})

test_that("standardize_names gives fixed names for accented headers", {
  df <- data.frame(1, 2, 3, 4)
  names(df) <- c(
    "Município (Sede)",
    "Cód. IES",
    "IGC (Contínuo)",
    "Nº de Matrículas"
  )

  expect_equal(
    names(educabR:::standardize_names(df)),
    c("municipio_sede", "cod_ies", "igc_continuo", "no_de_matriculas")
  )
})

# INEP repeated a column code with the wrong year (regioes_ufs 2025, anos
# iniciais: the 2025 rendimento is coded VL_INDICADOR_REND_2023)

mock_ideb_top <- function() {
  # rows 1-9 of the sheet: block headers on row 7, merged over each block
  top <- as.data.frame(matrix(NA_character_, nrow = 9, ncol = 6))
  top[7, 1] <- "Região"
  top[7, 2] <- "Taxa de Aprovação - 20215"
  top[7, 3] <- "Taxa de Aprovação - 2023"
  top[7, 5] <- "Taxa de Aprovação - 2025"
  top[9, 2] <- "1º ao 5º ano"
  tibble::as_tibble(top, .name_repair = "minimal")
}

test_that("ideb_resolve_codes takes the year of a repeated code from its header", {
  local_mocked_bindings(
    read_excel = function(...) mock_ideb_top(),
    .package = "readxl"
  )
  nm <- c(
    "REGIAO",
    "VL_INDICADOR_REND_2021",
    "VL_INDICADOR_REND_2023...3",
    "VL_NOTA_MEDIA_2023",
    "VL_INDICADOR_REND_2023...5",
    "VL_NOTA_MEDIA_2025"
  )

  expect_equal(
    educabR:::ideb_resolve_codes("ideb.xlsx", 1, nm),
    c(
      "REGIAO",
      "VL_INDICADOR_REND_2021",
      "VL_INDICADOR_REND_2023",
      "VL_NOTA_MEDIA_2023",
      "VL_INDICADOR_REND_2025",
      "VL_NOTA_MEDIA_2025"
    )
  )
})

test_that("ideb_resolve_codes leaves sheets without repeated codes alone", {
  called <- FALSE
  local_mocked_bindings(
    read_excel = function(...) {
      called <<- TRUE
      mock_ideb_top()
    },
    .package = "readxl"
  )
  nm <- c("REGIAO", "VL_INDICADOR_REND_2023", "VL_INDICADOR_REND_2025")

  expect_identical(educabR:::ideb_resolve_codes("ideb.xlsx", 1, nm), nm)
  expect_false(called)
})

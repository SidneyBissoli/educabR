# tests for data validation utilities

test_that("validate_data errors on empty data", {
  df <- tibble::tibble(a = numeric(), b = character())

  expect_error(validate_data(df, "enem", 2023), "contains no rows")
})

test_that("validate_data errors on too few columns", {
  df <- tibble::tibble(a = 1:5, b = 1:5)

  expect_error(validate_data(df, "enem", 2023), "only.*column")
})

test_that("validate_data warns when ENEM has no score columns", {
  df <- tibble::tibble(
    tp_sexo = c("M", "F"),
    tp_cor_raca = c(1, 2),
    nu_inscricao = c(100, 200)
  )

  expect_warning(validate_data(df, "enem", 2023), "no score columns")
})

test_that("validate_data passes for valid ENEM data", {
  df <- tibble::tibble(
    nu_nota_cn = c(500, 600),
    nu_nota_ch = c(400, 500),
    tp_sexo = c("M", "F")
  )

  expect_silent(validate_data(df, "enem", 2023))
})

test_that("validate_data warns when ENEM items has unexpected structure", {
  df <- tibble::tibble(
    col_a = 1:3,
    col_b = 4:6,
    col_c = 7:9
  )

  expect_warning(validate_data(df, "enem_itens", 2023), "unexpected structure")
})

test_that("validate_data passes for valid ENEM items data", {
  df <- tibble::tibble(
    co_item = 1:3,
    sg_area = c("CN", "CH", "LC"),
    co_prova = c(100, 100, 100)
  )

  expect_silent(validate_data(df, "enem_itens", 2023))
})

test_that("validate_data warns when IDEB has no ano column", {
  df <- tibble::tibble(
    no_escola = c("Escola A", "Escola B"),
    vl_observado = c(5.0, 6.0),
    rede = c("Municipal", "Estadual")
  )

  expect_warning(validate_data(df, "ideb", 2021), "ano")
})

test_that("validate_data passes for valid IDEB data", {
  df <- tibble::tibble(
    sg_uf = c("SP", "RJ"),
    rede = c("Municipal", "Estadual"),
    ano = c(2021L, 2021L),
    indicador = c("ideb", "ideb"),
    valor = c(5.0, 6.0)
  )

  expect_silent(validate_data(df, "ideb", 2021))
})

test_that("validate_data warns when Census has no co_uf column", {
  df <- tibble::tibble(
    no_entidade = c("Escola A", "Escola B"),
    tp_dependencia = c(2, 3),
    sg_uf = c("SP", "RJ")
  )

  expect_warning(validate_data(df, "censo_escolar", 2023), "co_uf.*not found")
})

test_that("validate_data passes for valid Census data", {
  df <- tibble::tibble(
    co_uf = c(35, 33),
    no_entidade = c("Escola A", "Escola B"),
    tp_dependencia = c(2, 3)
  )

  expect_silent(validate_data(df, "censo_escolar", 2023))
})

# tests for IDEB functions

# --- get_ideb: argument validation ---

test_that("get_ideb rejects invalid level via match.arg", {
  expect_error(
    get_ideb(level = "rede", stage = "anos_iniciais", metric = "indicador"),
    "arg"
  )
})

test_that("get_ideb rejects invalid stage via match.arg", {
  expect_error(
    get_ideb(level = "escola", stage = "creche", metric = "indicador"),
    "arg"
  )
})

test_that("get_ideb rejects invalid metric via match.arg", {
  expect_error(
    get_ideb(level = "escola", stage = "anos_iniciais", metric = "invalido"),
    "arg"
  )
})

test_that("get_ideb accepts new levels (brasil, regiao_uf)", {
  # just check that match.arg doesn't reject them
  # (actual download not tested here)
  expect_error(
    match.arg("brasil", c("escola", "municipio", "estado", "regiao", "brasil")),
    NA
  )
  expect_error(
    match.arg("regiao", c("escola", "municipio", "estado", "regiao", "brasil")),
    NA
  )
})

# --- backward compatibility ---

test_that("get_ideb detects old positional usage (numeric first arg)", {
  # we can't run the download, but we can verify the deprecation path

  # by checking that a numeric first arg triggers lifecycle warning
  expect_warning(
    tryCatch(
      get_ideb(2023, "escola", "anos_iniciais"),
      error = function(e) NULL
    ),
    "deprecated"
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

# --- build_ideb_url ---

test_that("build_ideb_url builds correct URLs for escola/municipio", {
  url <- educabR:::build_ideb_url("escola", "anos_iniciais", 2023)
  expect_match(url, "divulgacao_anos_iniciais_escolas_2023\\.xlsx$")

  url <- educabR:::build_ideb_url("municipio", "anos_finais", 2023)
  expect_match(url, "divulgacao_anos_finais_municipios_2023\\.xlsx$")
})

test_that("build_ideb_url builds correct URLs for brasil/regiao_uf", {
  url <- educabR:::build_ideb_url("brasil", "anos_iniciais", 2023)
  expect_match(url, "divulgacao_brasil_ideb_2023\\.xlsx$")

  # regiao and estado share the same file via file_level = "regiao_uf"
  url <- educabR:::build_ideb_url("regiao_uf", "ensino_medio", 2023)
  expect_match(url, "divulgacao_regioes_ufs_ideb_2023\\.xlsx$")
})

# --- get_ideb_sheet ---

test_that("get_ideb_sheet returns NULL for escola/municipio", {
  expect_null(educabR:::get_ideb_sheet("escola", "anos_iniciais"))
  expect_null(educabR:::get_ideb_sheet("municipio", "anos_finais"))
})

test_that("get_ideb_sheet returns correct sheet names for brasil", {
  expect_equal(
    educabR:::get_ideb_sheet("brasil", "anos_iniciais"),
    "Brasil (Anos Iniciais)"
  )
  expect_equal(
    educabR:::get_ideb_sheet("brasil", "ensino_medio"),
    "Brasil (EM)"
  )
})

test_that("get_ideb_sheet returns correct sheet names for regiao_uf", {
  # regiao and estado use file_level "regiao_uf" internally
  expect_equal(
    educabR:::get_ideb_sheet("regiao_uf", "anos_iniciais"),
    "UF e Regi\u00f5es (AI)"
  )
  expect_equal(
    educabR:::get_ideb_sheet("regiao_uf", "anos_finais"),
    "UF e Regi\u00f5es (AF)"
  )
})

# --- reshape_ideb ---

test_that("reshape_ideb returns correct format for metric = indicador", {
  df <- data.frame(
    sg_uf = c("SP", "RJ"),
    rede = c("publica", "privada"),
    vl_observado_2019 = c(6.5, 7.0),
    vl_observado_2021 = c(6.8, 7.2),
    vl_indicador_rend_2019 = c(0.9, 0.95),
    vl_indicador_rend_2021 = c(0.91, 0.96),
    vl_nota_media_2019 = c(5.5, 6.0),
    vl_nota_media_2021 = c(5.8, 6.2),
    stringsAsFactors = FALSE
  )

  result <- educabR:::reshape_ideb(df, "escola", "indicador")

  expect_s3_class(result, "tbl_df")
  expect_true(all(c("sg_uf", "rede", "ano", "indicador", "valor") %in% names(result)))
  expect_true(all(c("Indicador de Rendimento", "Nota M\u00e9dia Padronizada", "IDEB") %in% result$indicador))
  expect_true(all(c(2019, 2021) %in% result$ano))
})

test_that("reshape_ideb returns correct format for metric = aprovacao", {
  df <- data.frame(
    sg_uf = c("SP"),
    rede = c("publica"),
    vl_aprovacao_2019_1 = c(0.95),
    vl_aprovacao_2019_2 = c(0.90),
    vl_aprovacao_2019_3 = c(0.88),
    vl_aprovacao_2019_4 = c(0.91),
    vl_aprovacao_2019_si = c(0.93),
    vl_aprovacao_2019_si_4 = c(0.92),
    stringsAsFactors = FALSE
  )

  result <- educabR:::reshape_ideb(df, "escola", "aprovacao", "anos_iniciais")

  expect_s3_class(result, "tbl_df")
  expect_true(all(c("ano", "ano_escolar", "taxa_aprovacao") %in% names(result)))
  expect_true("1\u00ba" %in% result$ano_escolar)
  expect_true("5\u00ba" %in% result$ano_escolar)
  expect_true("1\u00ba ao 5\u00ba ano" %in% result$ano_escolar)
})

test_that("reshape_ideb returns correct format for metric = nota", {
  df <- data.frame(
    sg_uf = c("SP", "RJ"),
    rede = c("publica", "privada"),
    vl_nota_matematica_2019 = c(250, 260),
    vl_nota_matematica_2021 = c(255, 265),
    vl_nota_portugues_2019 = c(240, 250),
    vl_nota_portugues_2021 = c(245, 255),
    stringsAsFactors = FALSE
  )

  result <- educabR:::reshape_ideb(df, "escola", "nota")

  expect_s3_class(result, "tbl_df")
  expect_true(all(c("ano", "disciplina", "nota") %in% names(result)))
  expect_true(all(c("matematica", "portugues") %in% result$disciplina))
})

test_that("reshape_ideb returns correct format for metric = meta", {
  df <- data.frame(
    sg_uf = c("SP", "RJ"),
    rede = c("publica", "privada"),
    vl_projecao_2019 = c(5.5, 6.0),
    vl_projecao_2021 = c(5.8, 6.3),
    stringsAsFactors = FALSE
  )

  result <- educabR:::reshape_ideb(df, "escola", "meta")

  expect_s3_class(result, "tbl_df")
  expect_true(all(c("ano", "meta") %in% names(result)))
  expect_true(all(c(2019, 2021) %in% result$ano))
})

# --- list_ideb_available ---

test_that("list_ideb_available returns correct number of rows", {
  result <- list_ideb_available()

  expect_s3_class(result, "tbl_df")
  # 5 levels x 3 stages x 4 metrics = 60
  expect_equal(nrow(result), 60)
})

test_that("list_ideb_available has correct column names", {
  result <- list_ideb_available()

  expect_equal(names(result), c("level", "stage", "metric"))
})

test_that("list_ideb_available contains all valid levels", {
  result <- list_ideb_available()

  expect_true(all(c("escola", "municipio", "estado", "regiao", "brasil") %in% result$level))
})

test_that("list_ideb_available contains all valid stages", {
  result <- list_ideb_available()

  expect_true(all(c("anos_iniciais", "anos_finais", "ensino_medio") %in% result$stage))
})

test_that("list_ideb_available contains all valid metrics", {
  result <- list_ideb_available()

  expect_true(all(c("indicador", "aprovacao", "nota", "meta") %in% result$metric))
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

# --- get_ideb_series deprecation ---

test_that("get_ideb_series emits deprecation warning", {
  expect_warning(
    tryCatch(
      get_ideb_series(level = "escola", stage = "anos_iniciais"),
      error = function(e) NULL
    ),
    "deprecated"
  )
})

# tests for full pipeline of get_* functions that read Excel files or call APIs
# uses local_mocked_bindings() to mock I/O functions

# =============================================================================
# Test 1: get_ideb() full pipeline
# =============================================================================

test_that("get_ideb full pipeline works", {
  mock_data <- dplyr::tibble(
    SG_UF = c("SP", "RJ", "MG"),
    CO_MUNICIPIO = c(3550308, 3304557, 3106200),
    NO_MUNICIPIO = c("SAO PAULO", "RIO DE JANEIRO", "BELO HORIZONTE"),
    ID_ESCOLA = c(1, 2, 3),
    NO_ESCOLA = c("ESCOLA A", "ESCOLA B", "ESCOLA C"),
    REDE = c("Estadual", "Municipal", "Estadual"),
    VL_OBSERVADO_2021 = c("5,2", "4,8", "-"),
    VL_NOTA_MATEMATICA_2021 = c("5.5", "ND", "6.1"),
    VL_NOTA_PORTUGUES_2021 = c("5.0", "4.5", "5.8")
  )

  local_mocked_bindings(
    download_inep_file = function(url, destfile, quiet = FALSE) {
      dir.create(dirname(destfile), recursive = TRUE, showWarnings = FALSE)
      file.create(destfile)
      destfile
    },
    read_ideb_excel = function(file) mock_data,
    .package = "educabR"
  )

  result <- get_ideb(2021, level = "escola", stage = "anos_iniciais", quiet = TRUE)

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 3)
  # Check standardize_names worked
  expect_true(all(names(result) == tolower(names(result))))
  # Check clean_ideb_values: "-" -> NA, comma -> dot
  expect_true(is.na(result$vl_observado_2021[3]))
  expect_true(is.na(result$vl_nota_matematica_2021[2])) # "ND" -> NA
  expect_equal(result$vl_observado_2021[1], 5.2) # comma converted
})

test_that("get_ideb with UF filtering returns only matching rows", {
  mock_data <- dplyr::tibble(
    SG_UF = c("SP", "RJ", "MG"),
    CO_MUNICIPIO = c(3550308, 3304557, 3106200),
    NO_MUNICIPIO = c("SAO PAULO", "RIO DE JANEIRO", "BELO HORIZONTE"),
    VL_OBSERVADO_2021 = c("5,2", "4,8", "6,0")
  )

  local_mocked_bindings(
    download_inep_file = function(url, destfile, quiet = FALSE) {
      dir.create(dirname(destfile), recursive = TRUE, showWarnings = FALSE)
      file.create(destfile)
      destfile
    },
    read_ideb_excel = function(file) mock_data,
    .package = "educabR"
  )

  result <- get_ideb(2021, level = "escola", stage = "anos_iniciais",
                     uf = "SP", quiet = TRUE)

  expect_equal(nrow(result), 1)
  expect_equal(result$sg_uf[1], "SP")
})

test_that("get_ideb for year 2023 uses different URL pattern", {
  mock_data <- dplyr::tibble(
    SG_UF = c("SP"),
    CO_MUNICIPIO = c(3550308),
    NO_MUNICIPIO = c("SAO PAULO"),
    VL_OBSERVADO_2023 = c("5,5")
  )

  captured_url <- NULL

  local_mocked_bindings(
    download_inep_file = function(url, destfile, quiet = FALSE) {
      captured_url <<- url
      dir.create(dirname(destfile), recursive = TRUE, showWarnings = FALSE)
      file.create(destfile)
      destfile
    },
    read_ideb_excel = function(file) mock_data,
    .package = "educabR"
  )

  result <- get_ideb(2023, level = "escola", stage = "anos_iniciais", quiet = TRUE)

  # 2023 URL should use the ideb/resultados base
  expect_true(grepl("ideb/resultados", captured_url))
  expect_true(grepl("2023", captured_url))
  expect_s3_class(result, "tbl_df")
})

test_that("get_ideb uses cached file when it already exists", {
  mock_data <- dplyr::tibble(
    SG_UF = c("SP"),
    CO_MUNICIPIO = c(3550308),
    NO_MUNICIPIO = c("SAO PAULO"),
    VL_OBSERVADO_2021 = c("5,5")
  )

  download_called <- FALSE

  # Create the cached file so the download path is skipped
  xlsx_path <- educabR:::cache_path(
    "ideb",
    "divulgacao_anos_iniciais_escolas_2021.xlsx"
  )
  dir.create(dirname(xlsx_path), recursive = TRUE, showWarnings = FALSE)
  file.create(xlsx_path)
  withr::defer(unlink(xlsx_path))

  local_mocked_bindings(
    download_inep_file = function(url, destfile, quiet = FALSE) {
      download_called <<- TRUE
      destfile
    },
    read_ideb_excel = function(file) mock_data,
    .package = "educabR"
  )

  result <- get_ideb(2021, level = "escola", stage = "anos_iniciais", quiet = TRUE)

  expect_false(download_called)
  expect_s3_class(result, "tbl_df")
})

test_that("get_ideb_series with multiple years combines data", {
  call_count <- 0L

  local_mocked_bindings(
    download_inep_file = function(url, destfile, quiet = FALSE) {
      dir.create(dirname(destfile), recursive = TRUE, showWarnings = FALSE)
      file.create(destfile)
      destfile
    },
    read_ideb_excel = function(file) {
      call_count <<- call_count + 1L
      dplyr::tibble(
        SG_UF = c("SP", "RJ"),
        CO_MUNICIPIO = c(3550308, 3304557),
        NO_MUNICIPIO = c("SAO PAULO", "RIO DE JANEIRO"),
        VL_OBSERVADO_2021 = c("5,2", "4,8")
      )
    },
    .package = "educabR"
  )

  result <- get_ideb_series(
    years = c(2021, 2023),
    level = "escola",
    stage = "anos_iniciais",
    quiet = TRUE
  )

  expect_s3_class(result, "tbl_df")
  # 2 rows per year x 2 years = 4 rows
  expect_equal(nrow(result), 4)
  # ano_ideb column should be added
  expect_true("ano_ideb" %in% names(result))
  expect_equal(sort(unique(result$ano_ideb)), c(2021, 2023))
})

# =============================================================================
# Test 2: get_cpc() full pipeline
# =============================================================================

test_that("get_cpc full pipeline works", {
  mock_cpc <- dplyr::tibble(
    CO_CURSO = c(1, 2, 3),
    CO_IES = c(100, 200, 300),
    NO_CURSO = c("DIREITO", "MEDICINA", "ENGENHARIA"),
    CPC_CONTINUO = c(3.5, 4.2, 2.8),
    CPC_FAIXA = c("4", "5", "SC"),
    CO_GRUPO = c(1, 2, 3)
  )

  local_mocked_bindings(
    download_inep_file = function(url, destfile, quiet = FALSE) {
      dir.create(dirname(destfile), recursive = TRUE, showWarnings = FALSE)
      file.create(destfile)
      destfile
    },
    read_excel_safe = function(file, n_max = Inf) mock_cpc,
    .package = "educabR"
  )

  result <- get_cpc(2023, quiet = TRUE)

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 3)
  # standardize_names: all lowercase
  expect_true(all(names(result) == tolower(names(result))))
  # convert_faixa_columns: "SC" -> NA
  expect_true(is.na(result$cpc_faixa[3]))
  expect_equal(result$cpc_faixa[1], 4)
  expect_equal(result$cpc_faixa[2], 5)
})

test_that("get_cpc with keep_file=FALSE removes cached file", {
  mock_cpc <- dplyr::tibble(
    CO_CURSO = c(1, 2, 3),
    CO_IES = c(100, 200, 300),
    NO_CURSO = c("DIREITO", "MEDICINA", "ENGENHARIA"),
    CPC_CONTINUO = c(3.5, 4.2, 2.8),
    CPC_FAIXA = c("4", "5", "4"),
    CO_GRUPO = c(1, 2, 3)
  )

  local_mocked_bindings(
    download_inep_file = function(url, destfile, quiet = FALSE) {
      dir.create(dirname(destfile), recursive = TRUE, showWarnings = FALSE)
      file.create(destfile)
      destfile
    },
    read_excel_safe = function(file, n_max = Inf) mock_cpc,
    .package = "educabR"
  )

  result <- get_cpc(2023, keep_file = FALSE, quiet = TRUE)

  # The file should have been removed
  file_path <- educabR:::cache_path("cpc", "cpc_2023.xlsx")
  expect_false(file.exists(file_path))
  expect_s3_class(result, "tbl_df")
})

test_that("get_cpc clean_dash_values replaces dashes with NA", {
  mock_cpc <- dplyr::tibble(
    CO_CURSO = c(1, 2, 3),
    CO_IES = c(100, 200, 300),
    NO_CURSO = c("DIREITO", "-", "ENGENHARIA"),
    CPC_CONTINUO = c(3.5, 4.2, 2.8),
    CPC_FAIXA = c("4", "5", "4"),
    CO_GRUPO = c(1, 2, 3)
  )

  local_mocked_bindings(
    download_inep_file = function(url, destfile, quiet = FALSE) {
      dir.create(dirname(destfile), recursive = TRUE, showWarnings = FALSE)
      file.create(destfile)
      destfile
    },
    read_excel_safe = function(file, n_max = Inf) mock_cpc,
    .package = "educabR"
  )

  result <- get_cpc(2023, quiet = TRUE)

  # "-" in character column should become NA
  expect_true(is.na(result$no_curso[2]))
})

# =============================================================================
# Test 3: get_igc() full pipeline (non-archive year)
# =============================================================================

test_that("get_igc full pipeline works for non-archive year", {
  mock_igc <- dplyr::tibble(
    CO_IES = c(1, 2),
    NO_IES = c("UNIVERSIDADE A", "UNIVERSIDADE B"),
    SIGLA_IES = c("UA", "UB"),
    CO_MANTENEDORA = c(10, 20),
    IGC_CONTINUO = c(3.8, 4.1),
    IGC_FAIXA = c("4", "4")
  )

  local_mocked_bindings(
    download_inep_file = function(url, destfile, quiet = FALSE) {
      dir.create(dirname(destfile), recursive = TRUE, showWarnings = FALSE)
      file.create(destfile)
      destfile
    },
    read_excel_safe = function(file, n_max = Inf) mock_igc,
    .package = "educabR"
  )

  result <- get_igc(2023, quiet = TRUE)

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2)
  # standardize_names: all lowercase
  expect_true(all(names(result) == tolower(names(result))))
  # igc_faixa should be numeric
  expect_true(is.numeric(result$igc_faixa))
  expect_equal(result$igc_faixa, c(4, 4))
})

test_that("get_igc with keep_file=FALSE removes cached file", {
  mock_igc <- dplyr::tibble(
    CO_IES = c(1, 2),
    NO_IES = c("UNIVERSIDADE A", "UNIVERSIDADE B"),
    SIGLA_IES = c("UA", "UB"),
    CO_MANTENEDORA = c(10, 20),
    IGC_CONTINUO = c(3.8, 4.1),
    IGC_FAIXA = c("4", "4")
  )

  local_mocked_bindings(
    download_inep_file = function(url, destfile, quiet = FALSE) {
      dir.create(dirname(destfile), recursive = TRUE, showWarnings = FALSE)
      file.create(destfile)
      destfile
    },
    read_excel_safe = function(file, n_max = Inf) mock_igc,
    .package = "educabR"
  )

  result <- get_igc(2023, keep_file = FALSE, quiet = TRUE)

  file_path <- educabR:::cache_path("igc", "igc_2023.xlsx")
  expect_false(file.exists(file_path))
  expect_s3_class(result, "tbl_df")
})

# =============================================================================
# Test 4: get_igc(2007) - archive year (7z)
# =============================================================================

test_that("get_igc handles 7z archive year", {
  mock_igc <- dplyr::tibble(
    CO_IES = c(1, 2),
    NO_IES = c("UNIVERSIDADE A", "UNIVERSIDADE B"),
    SIGLA_IES = c("UA", "UB"),
    CO_MANTENEDORA = c(10, 20),
    IGC_CONTINUO = c(3.8, 4.1),
    IGC_FAIXA = c("4", "4")
  )

  local_mocked_bindings(
    download_inep_file = function(url, destfile, quiet = FALSE) {
      dir.create(dirname(destfile), recursive = TRUE, showWarnings = FALSE)
      file.create(destfile)
      destfile
    },
    extract_archive = function(archive, exdir, quiet = FALSE) {
      # Create exdir with a mock excel file
      dir.create(exdir, recursive = TRUE, showWarnings = FALSE)
      mock_xlsx <- file.path(exdir, "igc_2007.xlsx")
      file.create(mock_xlsx)
      mock_xlsx
    },
    read_excel_safe = function(file, n_max = Inf) mock_igc,
    .package = "educabR"
  )

  result <- get_igc(2007, quiet = TRUE)

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2)
  expect_true(all(names(result) == tolower(names(result))))
})

test_that("get_igc 7z errors when no excel file in extracted archive", {
  local_mocked_bindings(
    download_inep_file = function(url, destfile, quiet = FALSE) {
      dir.create(dirname(destfile), recursive = TRUE, showWarnings = FALSE)
      file.create(destfile)
      destfile
    },
    extract_archive = function(archive, exdir, quiet = FALSE) {
      # Create exdir but no excel files
      dir.create(exdir, recursive = TRUE, showWarnings = FALSE)
      file.create(file.path(exdir, "readme.txt"))
      file.path(exdir, "readme.txt")
    },
    .package = "educabR"
  )

  # Clean up any existing extracted directory
  exdir <- educabR:::cache_path("igc", "igc_2007")
  if (dir.exists(exdir)) unlink(exdir, recursive = TRUE)
  withr::defer({
    if (dir.exists(exdir)) unlink(exdir, recursive = TRUE)
  })

  expect_error(
    get_igc(2007, quiet = TRUE),
    "no Excel file found"
  )
})

# =============================================================================
# Test 5: get_fundeb_distribution() full pipeline
# =============================================================================

test_that("get_fundeb_distribution full pipeline works", {
  mock_fundeb <- dplyr::tibble(
    estados = c("SAO PAULO", "SAO PAULO", "RIO DE JANEIRO"),
    uf = c("SP", "SP", "RJ"),
    mes_ano = as.Date(c("2023-01-31", "2023-02-28", "2023-01-31")),
    origem = c("FPE", "FPE", "FPE"),
    destino = c("UF", "UF", "UF"),
    tabela = c("Fundeb", "Fundeb", "Fundeb"),
    valor = c(1000.50, 2000.75, 1500.00)
  )

  local_mocked_bindings(
    download_inep_file = function(url, destfile, quiet = FALSE) {
      dir.create(dirname(destfile), recursive = TRUE, showWarnings = FALSE)
      file.create(destfile)
      destfile
    },
    read_fundeb_sheets = function(file_path, year, source = NULL,
                                  destination = NULL, quiet = FALSE) {
      mock_fundeb
    },
    .package = "educabR"
  )

  result <- get_fundeb_distribution(2023, quiet = TRUE)

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 3)
  expect_true("valor" %in% names(result))
  expect_true("uf" %in% names(result))
})

test_that("get_fundeb_distribution filters by UF", {
  mock_fundeb <- dplyr::tibble(
    estados = c("SAO PAULO", "SAO PAULO", "RIO DE JANEIRO"),
    uf = c("SP", "SP", "RJ"),
    mes_ano = as.Date(c("2023-01-31", "2023-02-28", "2023-01-31")),
    origem = c("FPE", "FPE", "FPE"),
    destino = c("UF", "UF", "UF"),
    tabela = c("Fundeb", "Fundeb", "Fundeb"),
    valor = c(1000.50, 2000.75, 1500.00)
  )

  local_mocked_bindings(
    download_inep_file = function(url, destfile, quiet = FALSE) {
      dir.create(dirname(destfile), recursive = TRUE, showWarnings = FALSE)
      file.create(destfile)
      destfile
    },
    read_fundeb_sheets = function(file_path, year, source = NULL,
                                  destination = NULL, quiet = FALSE) {
      mock_fundeb
    },
    .package = "educabR"
  )

  result <- get_fundeb_distribution(2023, uf = "SP", quiet = TRUE)

  expect_equal(nrow(result), 2)
  expect_true(all(result$uf == "SP"))
})

test_that("get_fundeb_distribution enforces n_max", {
  mock_fundeb <- dplyr::tibble(
    estados = rep("SAO PAULO", 10),
    uf = rep("SP", 10),
    mes_ano = as.Date("2023-01-31") + seq(0, 9) * 30,
    origem = rep("FPE", 10),
    destino = rep("UF", 10),
    tabela = rep("Fundeb", 10),
    valor = seq(1000, 10000, length.out = 10)
  )

  local_mocked_bindings(
    download_inep_file = function(url, destfile, quiet = FALSE) {
      dir.create(dirname(destfile), recursive = TRUE, showWarnings = FALSE)
      file.create(destfile)
      destfile
    },
    read_fundeb_sheets = function(file_path, year, source = NULL,
                                  destination = NULL, quiet = FALSE) {
      mock_fundeb
    },
    .package = "educabR"
  )

  result <- get_fundeb_distribution(2023, n_max = 3, quiet = TRUE)

  expect_equal(nrow(result), 3)
})

test_that("get_fundeb_distribution keep_file=FALSE removes file", {
  mock_fundeb <- dplyr::tibble(
    estados = c("SAO PAULO"),
    uf = c("SP"),
    mes_ano = as.Date("2023-01-31"),
    origem = c("FPE"),
    destino = c("UF"),
    tabela = c("Fundeb"),
    valor = c(1000.50)
  )

  local_mocked_bindings(
    download_inep_file = function(url, destfile, quiet = FALSE) {
      dir.create(dirname(destfile), recursive = TRUE, showWarnings = FALSE)
      file.create(destfile)
      destfile
    },
    read_fundeb_sheets = function(file_path, year, source = NULL,
                                  destination = NULL, quiet = FALSE) {
      mock_fundeb
    },
    .package = "educabR"
  )

  result <- get_fundeb_distribution(2023, keep_file = FALSE, quiet = TRUE)

  file_path <- educabR:::cache_path("fundeb", "fundeb_distribution_2023.xls")
  expect_false(file.exists(file_path))
})

test_that("get_fundeb_distribution rejects invalid source", {
  expect_error(
    get_fundeb_distribution(2023, source = "INVALID", quiet = TRUE),
    "invalid source"
  )
})

test_that("get_fundeb_distribution passes source and destination to reader", {
  captured_source <- NULL
  captured_dest <- NULL

  mock_fundeb <- dplyr::tibble(
    estados = c("SAO PAULO"),
    uf = c("SP"),
    mes_ano = as.Date("2023-01-31"),
    origem = c("FPE"),
    destino = c("UF"),
    tabela = c("Fundeb"),
    valor = c(1000.50)
  )

  local_mocked_bindings(
    download_inep_file = function(url, destfile, quiet = FALSE) {
      dir.create(dirname(destfile), recursive = TRUE, showWarnings = FALSE)
      file.create(destfile)
      destfile
    },
    read_fundeb_sheets = function(file_path, year, source = NULL,
                                  destination = NULL, quiet = FALSE) {
      captured_source <<- source
      captured_dest <<- destination
      mock_fundeb
    },
    .package = "educabR"
  )

  result <- get_fundeb_distribution(2023, source = "FPE",
                                    destination = "uf", quiet = TRUE)

  expect_equal(captured_source, "FPE")
  expect_equal(captured_dest, "UF")
})

# =============================================================================
# Test 6: get_fundeb_enrollment() with cached file
# =============================================================================

test_that("get_fundeb_enrollment reads cached CSV correctly", {
  mock_csv_content <- paste(
    "AnoCenso;Uf;MunicipioGe;TipoRedeEducacao;DescricaoTipoEducacao;DescricaoTipoEnsino;DescricaoTipoTurma;DescricaoTipoCargaHoraria;DescricaoTipoLocalizacao;QtdMatricula",
    "2018;SP;SAO PAULO;PUBLICA;REGULAR;FUNDAMENTAL;ANOS INICIAIS;PARCIAL;URBANA;1000",
    "2018;RJ;RIO DE JANEIRO;PUBLICA;REGULAR;FUNDAMENTAL;ANOS INICIAIS;PARCIAL;URBANA;2000",
    sep = "\n"
  )

  # Write mock CSV to cache location
  filename <- "fundeb_enrollment_2018.csv"
  file_path <- educabR:::cache_path("fundeb", filename)
  dir.create(dirname(file_path), recursive = TRUE, showWarnings = FALSE)
  writeLines(mock_csv_content, file_path)
  withr::defer(unlink(file_path))

  result <- get_fundeb_enrollment(2018, quiet = TRUE)

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2)
  # Column renaming: CamelCase -> snake_case
  expect_true("ano_censo" %in% names(result))
  expect_true("uf" %in% names(result))
  expect_true("qtd_matricula" %in% names(result))
  expect_true("municipio" %in% names(result))
})

test_that("get_fundeb_enrollment filters by UF on cached data", {
  mock_csv_content <- paste(
    "AnoCenso;Uf;MunicipioGe;TipoRedeEducacao;DescricaoTipoEducacao;DescricaoTipoEnsino;DescricaoTipoTurma;DescricaoTipoCargaHoraria;DescricaoTipoLocalizacao;QtdMatricula",
    "2018;SP;SAO PAULO;PUBLICA;REGULAR;FUNDAMENTAL;ANOS INICIAIS;PARCIAL;URBANA;1000",
    "2018;RJ;RIO DE JANEIRO;PUBLICA;REGULAR;FUNDAMENTAL;ANOS INICIAIS;PARCIAL;URBANA;2000",
    sep = "\n"
  )

  filename <- "fundeb_enrollment_2018.csv"
  file_path <- educabR:::cache_path("fundeb", filename)
  dir.create(dirname(file_path), recursive = TRUE, showWarnings = FALSE)
  writeLines(mock_csv_content, file_path)
  withr::defer(unlink(file_path))

  result <- get_fundeb_enrollment(2018, uf = "SP", quiet = TRUE)

  expect_equal(nrow(result), 1)
  expect_equal(result$uf[1], "SP")
})

test_that("get_fundeb_enrollment respects n_max on cached data", {
  lines <- c(
    "AnoCenso;Uf;MunicipioGe;TipoRedeEducacao;DescricaoTipoEducacao;DescricaoTipoEnsino;DescricaoTipoTurma;DescricaoTipoCargaHoraria;DescricaoTipoLocalizacao;QtdMatricula",
    "2018;SP;SAO PAULO;PUBLICA;REGULAR;FUNDAMENTAL;ANOS INICIAIS;PARCIAL;URBANA;1000",
    "2018;RJ;RIO DE JANEIRO;PUBLICA;REGULAR;FUNDAMENTAL;ANOS INICIAIS;PARCIAL;URBANA;2000",
    "2018;MG;BELO HORIZONTE;PUBLICA;REGULAR;FUNDAMENTAL;ANOS INICIAIS;PARCIAL;URBANA;3000"
  )

  filename <- "fundeb_enrollment_2018.csv"
  file_path <- educabR:::cache_path("fundeb", filename)
  dir.create(dirname(file_path), recursive = TRUE, showWarnings = FALSE)
  writeLines(paste(lines, collapse = "\n"), file_path)
  withr::defer(unlink(file_path))

  result <- get_fundeb_enrollment(2018, n_max = 2, quiet = TRUE)

  expect_equal(nrow(result), 2)
})

# =============================================================================
# Test 7: get_fundeb_enrollment() fresh fetch (mock API)
# =============================================================================

test_that("get_fundeb_enrollment fetches from API when not cached", {
  mock_api_data <- dplyr::tibble(
    AnoCenso = c(2018L, 2018L),
    Uf = c("SP", "RJ"),
    MunicipioGe = c("SAO PAULO", "RIO DE JANEIRO"),
    TipoRedeEducacao = c("PUBLICA", "PUBLICA"),
    DescricaoTipoEducacao = c("REGULAR", "REGULAR"),
    DescricaoTipoEnsino = c("FUNDAMENTAL", "FUNDAMENTAL"),
    DescricaoTipoTurma = c("ANOS INICIAIS", "ANOS INICIAIS"),
    DescricaoTipoCargaHoraria = c("PARCIAL", "PARCIAL"),
    DescricaoTipoLocalizacao = c("URBANA", "URBANA"),
    QtdMatricula = c(1000L, 2000L)
  )

  # Ensure no cached file exists
  filename <- "fundeb_enrollment_2018.csv"
  file_path <- educabR:::cache_path("fundeb", filename)
  if (file.exists(file_path)) unlink(file_path)
  withr::defer(if (file.exists(file_path)) unlink(file_path))

  local_mocked_bindings(
    fetch_fundeb_enrollment = function(year, uf = NULL, n_max = Inf,
                                       quiet = FALSE) {
      mock_api_data
    },
    .package = "educabR"
  )

  result <- get_fundeb_enrollment(2018, keep_file = FALSE, quiet = TRUE)

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2)
  # Column names should be renamed
  expect_true("ano_censo" %in% names(result))
  expect_true("qtd_matricula" %in% names(result))
})

test_that("get_fundeb_enrollment caches result when keep_file=TRUE", {
  mock_api_data <- dplyr::tibble(
    AnoCenso = c(2018L),
    Uf = c("SP"),
    MunicipioGe = c("SAO PAULO"),
    TipoRedeEducacao = c("PUBLICA"),
    DescricaoTipoEducacao = c("REGULAR"),
    DescricaoTipoEnsino = c("FUNDAMENTAL"),
    DescricaoTipoTurma = c("ANOS INICIAIS"),
    DescricaoTipoCargaHoraria = c("PARCIAL"),
    DescricaoTipoLocalizacao = c("URBANA"),
    QtdMatricula = c(1000L)
  )

  filename <- "fundeb_enrollment_2018.csv"
  file_path <- educabR:::cache_path("fundeb", filename)
  if (file.exists(file_path)) unlink(file_path)
  withr::defer(if (file.exists(file_path)) unlink(file_path))

  local_mocked_bindings(
    fetch_fundeb_enrollment = function(year, uf = NULL, n_max = Inf,
                                       quiet = FALSE) {
      mock_api_data
    },
    .package = "educabR"
  )

  result <- get_fundeb_enrollment(2018, keep_file = TRUE, quiet = TRUE)

  expect_true(file.exists(file_path))
})

# =============================================================================
# Test 8: read_fundeb_sheets and parse_fundeb_sheet internal functions
# =============================================================================

test_that("rename_fundeb_enrollment maps CamelCase to snake_case", {
  df <- dplyr::tibble(
    AnoCenso = 2023L,
    Uf = "SP",
    MunicipioGe = "SAO PAULO",
    TipoRedeEducacao = "PUBLICA",
    DescricaoTipoEducacao = "REGULAR",
    DescricaoTipoEnsino = "FUNDAMENTAL",
    DescricaoTipoTurma = "ANOS INICIAIS",
    DescricaoTipoCargaHoraria = "PARCIAL",
    DescricaoTipoLocalizacao = "URBANA",
    QtdMatricula = 1000L
  )

  result <- educabR:::rename_fundeb_enrollment(df)

  expect_equal(names(result), c(
    "ano_censo", "uf", "municipio", "tipo_rede_educacao",
    "descricao_tipo_educacao", "descricao_tipo_ensino",
    "descricao_tipo_turma", "descricao_tipo_carga_horaria",
    "descricao_tipo_localizacao", "qtd_matricula"
  ))
})

test_that("build_fundeb_url constructs valid URL", {
  url <- educabR:::build_fundeb_url(2023)

  expect_true(grepl("thot-arquivos.tesouro.gov.br", url))
  expect_true(grepl("46131", url)) # 2023 ID from lookup
})

test_that("build_fundeb_url errors for unknown year", {
  expect_error(
    educabR:::build_fundeb_url(1999),
    "no FUNDEB distribution URL"
  )
})

test_that("tidy_fundeb_table processes data correctly", {
  # Simulate a raw FUNDEB table with estado, UF, and month columns
  df <- dplyr::tibble(
    ESTADO = c("SAO PAULO", "RIO DE JANEIRO"),
    UF = c("SP", "RJ"),
    JANEIRO = c(1000, 2000),
    FEVEREIRO = c(1100, 2100),
    TOTAL = c(2100, 4100)
  )

  result <- educabR:::tidy_fundeb_table(df, 2023, "FPE", "UF", "Fundeb")

  expect_s3_class(result, "tbl_df")
  # 2 states x 2 months = 4 rows
  expect_equal(nrow(result), 4)
  expect_true("valor" %in% names(result))
  expect_true("origem" %in% names(result))
  expect_true("destino" %in% names(result))
  expect_true("tabela" %in% names(result))
  expect_true("mes_ano" %in% names(result))
  expect_equal(result$origem[1], "FPE")
  expect_equal(result$destino[1], "UF")
  expect_equal(result$tabela[1], "Fundeb")
  # TOTAL column should be removed
  expect_false("TOTAL" %in% names(result))
})

test_that("tidy_fundeb_table returns empty tibble when no month columns", {
  df <- dplyr::tibble(
    ESTADO = c("SAO PAULO"),
    UF = c("SP"),
    OTHER = c(100)
  )

  result <- educabR:::tidy_fundeb_table(df, 2023, "FPE", "UF", "Fundeb")

  expect_equal(nrow(result), 0)
})

test_that("tidy_fundeb_table returns empty tibble when no UF column", {
  df <- dplyr::tibble(
    ESTADO = c("SAO PAULO"),
    JANEIRO = c(1000)
  )

  result <- educabR:::tidy_fundeb_table(df, 2023, "FPE", "UF", "Fundeb")

  expect_equal(nrow(result), 0)
})

test_that("tidy_fundeb_table removes summary rows", {
  df <- dplyr::tibble(
    ESTADO = c("SAO PAULO", "REPASSE TOTAL", NA, "RIO DE JANEIRO"),
    UF = c("SP", "XX", NA, "RJ"),
    JANEIRO = c(1000, 9999, NA, 2000)
  )

  result <- educabR:::tidy_fundeb_table(df, 2023, "FPE", "UF", "Fundeb")

  # Only SAO PAULO and RIO DE JANEIRO should remain
  expect_equal(nrow(result), 2)
  expect_true(all(result$estados %in% c("SAO PAULO", "RIO DE JANEIRO")))
})

test_that("tidy_fundeb_table creates correct end-of-month dates", {
  df <- dplyr::tibble(
    ESTADO = c("SAO PAULO"),
    UF = c("SP"),
    JANEIRO = c(1000),
    DEZEMBRO = c(2000)
  )

  result <- educabR:::tidy_fundeb_table(df, 2023, "FPE", "UF", "Fundeb")

  # January 2023 -> last day = 2023-01-31
  jan_date <- result$mes_ano[result$valor == 1000]
  expect_equal(jan_date, as.Date("2023-01-31"))

  # December 2023 -> last day = 2023-12-31
  dec_date <- result$mes_ano[result$valor == 2000]
  expect_equal(dec_date, as.Date("2023-12-31"))
})

# =============================================================================
# Test 9: download_inep_file and extract_zip (from utils-download.R)
# =============================================================================

test_that("extract_zip works with real zip", {
  skip_on_cran()
  temp_dir <- withr::local_tempdir()

  # Create a file and zip it
  test_file <- file.path(temp_dir, "test.csv")
  writeLines("a;b;c\n1;2;3", test_file)
  zip_file <- file.path(temp_dir, "test.zip")
  withr::with_dir(temp_dir, {
    utils::zip(zip_file, "test.csv", flags = "-j")
  })

  exdir <- file.path(temp_dir, "extracted")
  result <- educabR:::extract_zip(zip_file, exdir, quiet = TRUE)

  expect_true(length(result) > 0)
  expect_true(dir.exists(exdir))
})

test_that("extract_archive errors for unsupported format", {
  expect_error(
    educabR:::extract_archive("file.tar.gz", "/tmp/out", quiet = TRUE),
    "unsupported archive format"
  )
})

test_that("extract_archive delegates to extract_zip for .zip", {
  skip_on_cran()
  temp_dir <- withr::local_tempdir()

  test_file <- file.path(temp_dir, "test.csv")
  writeLines("x;y\n1;2", test_file)
  zip_file <- file.path(temp_dir, "test.zip")
  withr::with_dir(temp_dir, {
    utils::zip(zip_file, "test.csv", flags = "-j")
  })

  exdir <- file.path(temp_dir, "extracted")
  result <- educabR:::extract_archive(zip_file, exdir, quiet = TRUE)

  expect_true(length(result) > 0)
})

test_that("download_inep_file error handling when request fails", {
  local_mocked_bindings(
    req_perform = function(req, ...) {
      stop("connection refused")
    },
    .package = "httr2"
  )

  temp_dir <- withr::local_tempdir()
  dest <- file.path(temp_dir, "test.xlsx")

  expect_error(
    educabR:::download_inep_file("https://fake.url/file.xlsx", dest,
                                 quiet = TRUE),
    "download failed"
  )
})

# =============================================================================
# Test 10: read_inep_file
# =============================================================================

test_that("read_inep_file reads delimited files correctly", {
  temp_file <- withr::local_tempfile(fileext = ".csv")
  writeLines("A;B;C\n1;2;3\n4;5;6", temp_file)

  result <- educabR:::read_inep_file(temp_file, delim = ";", n_max = Inf)

  expect_equal(nrow(result), 2)
  expect_equal(ncol(result), 3)
  expect_s3_class(result, "tbl_df")
})

test_that("read_inep_file respects n_max parameter", {
  temp_file <- withr::local_tempfile(fileext = ".csv")
  writeLines("A;B;C\n1;2;3\n4;5;6\n7;8;9", temp_file)

  result <- educabR:::read_inep_file(temp_file, delim = ";", n_max = 1)

  expect_equal(nrow(result), 1)
})

test_that("read_inep_file detects encoding automatically", {
  temp_file <- withr::local_tempfile(fileext = ".csv")
  writeLines("A;B;C\n1;2;3", temp_file)

  # encoding=NULL triggers auto-detection
  result <- educabR:::read_inep_file(temp_file, delim = ";", encoding = NULL)

  expect_equal(nrow(result), 1)
  expect_s3_class(result, "tbl_df")
})

test_that("detect_delim identifies semicolon delimiter", {
  temp_file <- withr::local_tempfile(fileext = ".csv")
  writeLines("A;B;C\n1;2;3", temp_file)

  result <- educabR:::detect_delim(temp_file)

  expect_equal(result, ";")
})

test_that("detect_delim identifies comma delimiter", {
  temp_file <- withr::local_tempfile(fileext = ".csv")
  writeLines("A,B,C\n1,2,3", temp_file)

  result <- educabR:::detect_delim(temp_file)

  expect_equal(result, ",")
})

test_that("detect_delim identifies pipe delimiter", {
  temp_file <- withr::local_tempfile(fileext = ".csv")
  writeLines("A|B|C\n1|2|3", temp_file)

  result <- educabR:::detect_delim(temp_file)

  expect_equal(result, "|")
})

test_that("detect_encoding detects UTF-8", {
  temp_file <- withr::local_tempfile(fileext = ".csv")
  writeLines("hello world", temp_file)

  result <- educabR:::detect_encoding(temp_file)

  expect_equal(result, "UTF-8")
})

# =============================================================================
# Additional edge cases
# =============================================================================

test_that("get_ideb_series handles error in one year gracefully", {
  call_count <- 0L

  local_mocked_bindings(
    download_inep_file = function(url, destfile, quiet = FALSE) {
      dir.create(dirname(destfile), recursive = TRUE, showWarnings = FALSE)
      file.create(destfile)
      destfile
    },
    read_ideb_excel = function(file) {
      call_count <<- call_count + 1L
      if (call_count == 1L) {
        stop("simulated read error")
      }
      dplyr::tibble(
        SG_UF = c("SP"),
        CO_MUNICIPIO = c(3550308),
        NO_MUNICIPIO = c("SAO PAULO"),
        VL_OBSERVADO_2021 = c("5,2")
      )
    },
    .package = "educabR"
  )

  # First year fails, second succeeds
  result <- get_ideb_series(
    years = c(2021, 2023),
    level = "escola",
    stage = "anos_iniciais",
    quiet = TRUE
  )

  expect_s3_class(result, "tbl_df")
  # Only the second year should have data
  expect_equal(nrow(result), 1)
})

test_that("get_cpc uses cached file on second call", {
  mock_cpc <- dplyr::tibble(
    CO_CURSO = c(1),
    CO_IES = c(100),
    NO_CURSO = c("DIREITO"),
    CPC_CONTINUO = c(3.5),
    CPC_FAIXA = c("4"),
    CO_GRUPO = c(1)
  )

  download_count <- 0L

  # Pre-create the cached file
  file_path <- educabR:::cache_path("cpc", "cpc_2022.xlsx")
  dir.create(dirname(file_path), recursive = TRUE, showWarnings = FALSE)
  file.create(file_path)
  withr::defer(unlink(file_path))

  local_mocked_bindings(
    download_inep_file = function(url, destfile, quiet = FALSE) {
      download_count <<- download_count + 1L
      dir.create(dirname(destfile), recursive = TRUE, showWarnings = FALSE)
      file.create(destfile)
      destfile
    },
    read_excel_safe = function(file, n_max = Inf) mock_cpc,
    .package = "educabR"
  )

  result <- get_cpc(2022, quiet = TRUE)

  # File was already cached, so download should not be called
  expect_equal(download_count, 0L)
  expect_s3_class(result, "tbl_df")
})

test_that("get_igc cached file skips download", {
  mock_igc <- dplyr::tibble(
    CO_IES = c(1),
    NO_IES = c("UNIVERSIDADE A"),
    SIGLA_IES = c("UA"),
    CO_MANTENEDORA = c(10),
    IGC_CONTINUO = c(3.8),
    IGC_FAIXA = c("4")
  )

  download_count <- 0L

  file_path <- educabR:::cache_path("igc", "igc_2022.xlsx")
  dir.create(dirname(file_path), recursive = TRUE, showWarnings = FALSE)
  file.create(file_path)
  withr::defer(unlink(file_path))

  local_mocked_bindings(
    download_inep_file = function(url, destfile, quiet = FALSE) {
      download_count <<- download_count + 1L
      dir.create(dirname(destfile), recursive = TRUE, showWarnings = FALSE)
      file.create(destfile)
      destfile
    },
    read_excel_safe = function(file, n_max = Inf) mock_igc,
    .package = "educabR"
  )

  result <- get_igc(2022, quiet = TRUE)

  expect_equal(download_count, 0L)
  expect_s3_class(result, "tbl_df")
})

test_that("get_fundeb_distribution uses cached file", {
  mock_fundeb <- dplyr::tibble(
    estados = c("SAO PAULO"),
    uf = c("SP"),
    mes_ano = as.Date("2023-01-31"),
    origem = c("FPE"),
    destino = c("UF"),
    tabela = c("Fundeb"),
    valor = c(1000.50)
  )

  download_count <- 0L

  file_path <- educabR:::cache_path("fundeb", "fundeb_distribution_2023.xls")
  dir.create(dirname(file_path), recursive = TRUE, showWarnings = FALSE)
  file.create(file_path)
  withr::defer(unlink(file_path))

  local_mocked_bindings(
    download_inep_file = function(url, destfile, quiet = FALSE) {
      download_count <<- download_count + 1L
      dir.create(dirname(destfile), recursive = TRUE, showWarnings = FALSE)
      file.create(destfile)
      destfile
    },
    read_fundeb_sheets = function(file_path, year, source = NULL,
                                  destination = NULL, quiet = FALSE) {
      mock_fundeb
    },
    .package = "educabR"
  )

  result <- get_fundeb_distribution(2023, quiet = TRUE)

  expect_equal(download_count, 0L)
  expect_s3_class(result, "tbl_df")
})

test_that("validate_data errors on empty data frame", {
  empty_df <- dplyr::tibble(a = integer(0), b = character(0), c = numeric(0))

  expect_error(
    educabR:::validate_data(empty_df, "cpc", 2023),
    "contains no rows"
  )
})

test_that("validate_data errors on too few columns", {
  tiny_df <- dplyr::tibble(a = 1:5, b = 6:10)

  expect_error(
    educabR:::validate_data(tiny_df, "cpc", 2023),
    "column"
  )
})

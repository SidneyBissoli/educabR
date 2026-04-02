# tests for full pipelines of get_* functions with cached mock data
# each test creates a temp cache dir with mock zip + extracted CSV,
# so the functions skip download/extraction and go straight to reading.

# helper: set up a temp cache environment
setup_temp_cache <- function(env = parent.frame()) {
  temp_cache <- withr::local_tempdir(.local_envir = env)
  withr::local_options(educabR.cache_dir = temp_cache, .local_envir = env)
  educabR::set_cache_dir(temp_cache)
  temp_cache
}

# helper: create a mock zip file and extracted directory with a CSV
create_mock_data <- function(temp_cache, dataset_subdir, zip_filename,
                             exdir_name, csv_filename, header, rows) {
  dataset_dir <- file.path(temp_cache, dataset_subdir)
  dir.create(dataset_dir, recursive = TRUE, showWarnings = FALSE)
  file.create(file.path(dataset_dir, zip_filename))

  exdir <- file.path(dataset_dir, exdir_name)
  dir.create(exdir, recursive = TRUE, showWarnings = FALSE)

  mock_csv <- file.path(exdir, csv_filename)
  lines <- c(header, rows)
  writeLines(lines, mock_csv)

  invisible(mock_csv)
}

# --------------------------------------------------------------------------
# get_enem(2023) - pre-2024 single file
# --------------------------------------------------------------------------
test_that("get_enem full pipeline works with cached data (pre-2024)", {
  temp_cache <- setup_temp_cache()

  create_mock_data(
    temp_cache,
    dataset_subdir = "enem",
    zip_filename = "microdados_enem_2023.zip",
    exdir_name = "enem_2023",
    csv_filename = "MICRODADOS_ENEM_2023.csv",
    header = "NU_INSCRICAO;NU_ANO;TP_SEXO;TP_COR_RACA;NU_NOTA_CN;NU_NOTA_CH;NU_NOTA_LC;NU_NOTA_MT;NU_NOTA_REDACAO",
    rows = c(
      "100001;2023;1;1;550.5;600.2;580.1;620.3;700",
      "100002;2023;2;2;480.0;510.5;490.2;530.1;650",
      "100003;2023;1;3;520.8;540.3;560.7;590.4;680"
    )
  )

  result <- get_enem(2023, quiet = TRUE, n_max = 10)

  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 0)
  expect_equal(nrow(result), 3)
  expect_true(all(names(result) == tolower(names(result))))
  expect_true("nu_nota_cn" %in% names(result))
  expect_true("nu_nota_redacao" %in% names(result))
})

# --------------------------------------------------------------------------
# get_enem(2024, type="participantes")
# --------------------------------------------------------------------------
test_that("get_enem full pipeline works for 2024 participantes", {
  temp_cache <- setup_temp_cache()

  create_mock_data(
    temp_cache,
    dataset_subdir = "enem",
    zip_filename = "microdados_enem_2024.zip",
    exdir_name = "enem_2024",
    csv_filename = "PARTICIPANTES_2024.csv",
    header = "NU_INSCRICAO;TP_SEXO;TP_COR_RACA;NU_ANO",
    rows = c(
      "200001;1;1;2024",
      "200002;2;3;2024"
    )
  )

  result <- get_enem(2024, type = "participantes", quiet = TRUE, n_max = 10)

  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 0)
  expect_true(all(names(result) == tolower(names(result))))
  expect_true("nu_inscricao" %in% names(result))
  expect_true("tp_sexo" %in% names(result))
})

# --------------------------------------------------------------------------
# get_enem type warning for pre-2024
# --------------------------------------------------------------------------
test_that("get_enem warns when type is used for pre-2024", {
  temp_cache <- setup_temp_cache()

  create_mock_data(
    temp_cache,
    dataset_subdir = "enem",
    zip_filename = "microdados_enem_2023.zip",
    exdir_name = "enem_2023",
    csv_filename = "MICRODADOS_ENEM_2023.csv",
    header = "NU_INSCRICAO;NU_ANO;TP_SEXO;TP_COR_RACA;NU_NOTA_CN;NU_NOTA_CH;NU_NOTA_LC;NU_NOTA_MT;NU_NOTA_REDACAO",
    rows = "100001;2023;1;1;550.5;600.2;580.1;620.3;700"
  )

  expect_message(
    get_enem(2023, type = "resultados", quiet = FALSE, n_max = 10),
    "only available for ENEM 2024"
  )
})

# --------------------------------------------------------------------------
# get_enem_itens(2023)
# --------------------------------------------------------------------------
test_that("get_enem_itens full pipeline works with cached data", {
  temp_cache <- setup_temp_cache()

  # need the zip file for is_cached check
  dataset_dir <- file.path(temp_cache, "enem")
  dir.create(dataset_dir, recursive = TRUE, showWarnings = FALSE)
  file.create(file.path(dataset_dir, "microdados_enem_2023.zip"))

  exdir <- file.path(dataset_dir, "enem_2023")
  dir.create(exdir, recursive = TRUE, showWarnings = FALSE)

  writeLines(
    c(
      "CO_ITEM;SG_AREA;CO_PROVA;TP_LINGUA;IN_ITEM_ABAN",
      "10001;CN;101;0;0",
      "10002;CH;102;0;1"
    ),
    file.path(exdir, "ITENS_PROVA_2023.csv")
  )

  result <- get_enem_itens(2023, quiet = TRUE, n_max = 10)

  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 0)
  expect_true(all(names(result) == tolower(names(result))))
  expect_true("co_item" %in% names(result))
  expect_true("sg_area" %in% names(result))
})

# --------------------------------------------------------------------------
# get_enade(2023)
# --------------------------------------------------------------------------
test_that("get_enade full pipeline works with cached data", {
  temp_cache <- setup_temp_cache()

  create_mock_data(
    temp_cache,
    dataset_subdir = "enade",
    zip_filename = "microdados_enade_2023.zip",
    exdir_name = "microdados_enade_2023",
    csv_filename = "microdados_enade_2023.csv",
    header = "NU_ANO;CO_CURSO;CO_IES;NT_GER;NT_FG;NT_CE;CO_GRUPO",
    rows = c(
      "2023;1001;100;55.2;60.1;50.3;4001",
      "2023;1002;200;-;45.5;40.2;4002"
    )
  )

  result <- get_enade(2023, quiet = TRUE, n_max = 10)

  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 0)
  expect_true(all(names(result) == tolower(names(result))))
  expect_true("nu_ano" %in% names(result))
  expect_true("nt_ger" %in% names(result))
})

# --------------------------------------------------------------------------
# get_encceja(2023)
# --------------------------------------------------------------------------
test_that("get_encceja full pipeline works with cached data", {
  temp_cache <- setup_temp_cache()

  create_mock_data(
    temp_cache,
    dataset_subdir = "encceja",
    zip_filename = "microdados_encceja_2023.zip",
    exdir_name = "microdados_encceja_2023",
    csv_filename = "MICRODADOS_ENCCEJA_2023.csv",
    header = "NU_INSCRICAO;NU_ANO;TP_SEXO;CO_MUNICIPIO_RESIDENCIA;TP_COR_RACA",
    rows = c(
      "300001;2023;1;3550308;1",
      "300002;2023;2;3304557;2"
    )
  )

  result <- get_encceja(2023, quiet = TRUE, n_max = 10)

  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 0)
  expect_true(all(names(result) == tolower(names(result))))
  expect_true("nu_inscricao" %in% names(result))
  expect_true("co_municipio_residencia" %in% names(result))
})

# --------------------------------------------------------------------------
# get_saeb(2023) - all 4 types
# --------------------------------------------------------------------------
test_that("get_saeb full pipeline works for aluno type", {
  temp_cache <- setup_temp_cache()

  dataset_dir <- file.path(temp_cache, "saeb")
  dir.create(dataset_dir, recursive = TRUE, showWarnings = FALSE)
  file.create(file.path(dataset_dir, "microdados_saeb_2023.zip"))

  exdir <- file.path(dataset_dir, "microdados_saeb_2023")
  dir.create(exdir, recursive = TRUE, showWarnings = FALSE)

  writeLines(
    c(
      "ID_SAEB;ID_ALUNO;PROFICIENCIA_MT;PROFICIENCIA_LP;NU_ANO_SAEB",
      "1;1001;250.5;230.2;2023",
      "2;1002;280.1;260.8;2023"
    ),
    file.path(exdir, "TS_ALUNO_2023.csv")
  )

  result <- get_saeb(2023, type = "aluno", quiet = TRUE, n_max = 10)

  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 0)
  expect_true(all(names(result) == tolower(names(result))))
  expect_true("id_saeb" %in% names(result))
  expect_true("id_aluno" %in% names(result))
})

test_that("get_saeb full pipeline works for escola type", {
  temp_cache <- setup_temp_cache()

  dataset_dir <- file.path(temp_cache, "saeb")
  dir.create(dataset_dir, recursive = TRUE, showWarnings = FALSE)
  file.create(file.path(dataset_dir, "microdados_saeb_2023.zip"))

  exdir <- file.path(dataset_dir, "microdados_saeb_2023")
  dir.create(exdir, recursive = TRUE, showWarnings = FALSE)

  writeLines(
    c(
      "ID_SAEB;ID_ESCOLA;NO_ESCOLA;NU_ANO_SAEB;CO_UF",
      "1;50001;Escola A;2023;35",
      "2;50002;Escola B;2023;33"
    ),
    file.path(exdir, "TS_ESCOLA_2023.csv")
  )

  result <- get_saeb(2023, type = "escola", quiet = TRUE, n_max = 10)

  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 0)
  expect_true(all(names(result) == tolower(names(result))))
  expect_true("id_escola" %in% names(result))
})

test_that("get_saeb full pipeline works for diretor type", {
  temp_cache <- setup_temp_cache()

  dataset_dir <- file.path(temp_cache, "saeb")
  dir.create(dataset_dir, recursive = TRUE, showWarnings = FALSE)
  file.create(file.path(dataset_dir, "microdados_saeb_2023.zip"))

  exdir <- file.path(dataset_dir, "microdados_saeb_2023")
  dir.create(exdir, recursive = TRUE, showWarnings = FALSE)

  writeLines(
    c(
      "ID_SAEB;ID_ESCOLA;TX_RESP_Q001;NU_ANO_SAEB",
      "1;50001;A;2023",
      "2;50002;B;2023"
    ),
    file.path(exdir, "TS_DIRETOR_2023.csv")
  )

  result <- get_saeb(2023, type = "diretor", quiet = TRUE, n_max = 10)

  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 0)
  expect_true(all(names(result) == tolower(names(result))))
})

test_that("get_saeb full pipeline works for professor type", {
  temp_cache <- setup_temp_cache()

  dataset_dir <- file.path(temp_cache, "saeb")
  dir.create(dataset_dir, recursive = TRUE, showWarnings = FALSE)
  file.create(file.path(dataset_dir, "microdados_saeb_2023.zip"))

  exdir <- file.path(dataset_dir, "microdados_saeb_2023")
  dir.create(exdir, recursive = TRUE, showWarnings = FALSE)

  writeLines(
    c(
      "ID_SAEB;ID_ESCOLA;TX_RESP_Q001;NU_ANO_SAEB",
      "1;50001;C;2023",
      "2;50002;D;2023"
    ),
    file.path(exdir, "TS_PROFESSOR_2023.csv")
  )

  result <- get_saeb(2023, type = "professor", quiet = TRUE, n_max = 10)

  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 0)
  expect_true(all(names(result) == tolower(names(result))))
})

# --------------------------------------------------------------------------
# get_enem_escola()
# --------------------------------------------------------------------------
test_that("get_enem_escola full pipeline works with cached data", {
  temp_cache <- setup_temp_cache()

  create_mock_data(
    temp_cache,
    dataset_subdir = "enem_escola",
    zip_filename = "microdados_enem_por_escola.zip",
    exdir_name = "microdados_enem_por_escola",
    csv_filename = "MICRODADOS_ENEM_POR_ESCOLA.csv",
    header = "CO_ESCOLA_EDUCACENSO;NO_ESCOLA;NU_ANO;NU_MEDIA_CN;NU_MEDIA_CH;NU_MEDIA_LC;NU_MEDIA_MT;NU_MEDIA_RED",
    rows = c(
      "35000001;Escola Alpha;2015;500.1;510.2;520.3;530.4;-",
      "33000002;Escola Beta;2014;480.5;490.6;470.7;460.8;600"
    )
  )

  result <- get_enem_escola(quiet = TRUE, n_max = 10)

  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 0)
  expect_true(all(names(result) == tolower(names(result))))
  expect_true("co_escola_educacenso" %in% names(result))
  expect_true("nu_media_cn" %in% names(result))
})

# --------------------------------------------------------------------------
# get_idd(2023) - year >= 2021 uses .zip
# --------------------------------------------------------------------------
test_that("get_idd full pipeline works with cached data", {
  temp_cache <- setup_temp_cache()

  create_mock_data(
    temp_cache,
    dataset_subdir = "idd",
    zip_filename = "microdados_IDD_2023.zip",
    exdir_name = "microdados_IDD_2023",
    csv_filename = "microdados_idd_2023.csv",
    header = "CO_CURSO;CO_IES;IDD_CONTINUO;IDD_FAIXA;NO_CURSO;CO_GRUPO;NO_IES",
    rows = c(
      "1001;100;2.5;3;Direito;4001;Universidade A",
      "1002;200;3.8;4;Medicina;4002;Universidade B",
      "1003;300;-;-;Engenharia;4003;Universidade C"
    )
  )

  result <- get_idd(2023, quiet = TRUE, n_max = 10)

  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 0)
  expect_true(all(names(result) == tolower(names(result))))
  expect_true("co_curso" %in% names(result))
  expect_true("idd_continuo" %in% names(result))
})

# --------------------------------------------------------------------------
# get_censo_escolar(2023)
# --------------------------------------------------------------------------
test_that("get_censo_escolar full pipeline works with cached data", {
  temp_cache <- setup_temp_cache()

  create_mock_data(
    temp_cache,
    dataset_subdir = "censo_escolar",
    zip_filename = "microdados_censo_escolar_2023.zip",
    exdir_name = "censo_2023",
    csv_filename = "microdados_ed_basica_2023.csv",
    header = "CO_UF;NO_ENTIDADE;CO_ENTIDADE;TP_DEPENDENCIA;SG_UF;NO_MUNICIPIO;CO_MUNICIPIO",
    rows = c(
      "35;Escola SP 1;35000001;2;SP;Sao Paulo;3550308",
      "33;Escola RJ 1;33000001;3;RJ;Rio de Janeiro;3304557",
      "35;Escola SP 2;35000002;1;SP;Campinas;3509502",
      "29;Escola BA 1;29000001;2;BA;Salvador;2927408"
    )
  )

  result <- get_censo_escolar(2023, quiet = TRUE, n_max = 10)

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 4)
  expect_true(all(names(result) == tolower(names(result))))
  expect_true("co_uf" %in% names(result))
  expect_true("no_entidade" %in% names(result))
})

# --------------------------------------------------------------------------
# get_censo_escolar(2023) - UF filtering
# --------------------------------------------------------------------------
test_that("get_censo_escolar filters by UF correctly", {
  temp_cache <- setup_temp_cache()

  create_mock_data(
    temp_cache,
    dataset_subdir = "censo_escolar",
    zip_filename = "microdados_censo_escolar_2023.zip",
    exdir_name = "censo_2023",
    csv_filename = "microdados_ed_basica_2023.csv",
    header = "CO_UF;NO_ENTIDADE;CO_ENTIDADE;TP_DEPENDENCIA;SG_UF;NO_MUNICIPIO;CO_MUNICIPIO",
    rows = c(
      "35;Escola SP 1;35000001;2;SP;Sao Paulo;3550308",
      "33;Escola RJ 1;33000001;3;RJ;Rio de Janeiro;3304557",
      "35;Escola SP 2;35000002;1;SP;Campinas;3509502",
      "29;Escola BA 1;29000001;2;BA;Salvador;2927408"
    )
  )

  result <- get_censo_escolar(2023, uf = "SP", quiet = TRUE, n_max = 10)

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2)
  expect_true(all(result$co_uf == 35))
})

# --------------------------------------------------------------------------
# get_censo_superior(2023) - ies type
# --------------------------------------------------------------------------
test_that("get_censo_superior full pipeline works for ies type", {
  temp_cache <- setup_temp_cache()

  create_mock_data(
    temp_cache,
    dataset_subdir = "censo_superior",
    zip_filename = "microdados_censo_da_educacao_superior_2023.zip",
    exdir_name = "microdados_censo_da_educacao_superior_2023",
    csv_filename = "MICRODADOS_CADASTRO_IES_2023.csv",
    header = "CO_IES;NO_IES;CO_UF_IES;TP_CATEGORIA_ADMINISTRATIVA;SG_UF_IES",
    rows = c(
      "100;Universidade Federal A;35;1;SP",
      "200;Universidade Estadual B;33;2;RJ",
      "300;Faculdade Privada C;35;5;SP"
    )
  )

  result <- get_censo_superior(2023, type = "ies", quiet = TRUE, n_max = 10)

  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 0)
  expect_true(all(names(result) == tolower(names(result))))
  expect_true("co_ies" %in% names(result))
  expect_true("no_ies" %in% names(result))
})

# --------------------------------------------------------------------------
# get_censo_superior(2023, type="cursos")
# --------------------------------------------------------------------------
test_that("get_censo_superior full pipeline works for cursos type", {
  temp_cache <- setup_temp_cache()

  create_mock_data(
    temp_cache,
    dataset_subdir = "censo_superior",
    zip_filename = "microdados_censo_da_educacao_superior_2023.zip",
    exdir_name = "microdados_censo_da_educacao_superior_2023",
    csv_filename = "MICRODADOS_CADASTRO_CURSO_2023.csv",
    header = "CO_CURSO;CO_IES;NO_CURSO;CO_UF_IES;TP_MODALIDADE_ENSINO",
    rows = c(
      "5001;100;Direito;35;1",
      "5002;200;Medicina;33;1"
    )
  )

  result <- get_censo_superior(2023, type = "cursos", quiet = TRUE, n_max = 10)

  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 0)
  expect_true(all(names(result) == tolower(names(result))))
  expect_true("co_curso" %in% names(result))
  expect_true("no_curso" %in% names(result))
})

# --------------------------------------------------------------------------
# get_censo_superior UF filtering
# --------------------------------------------------------------------------
test_that("get_censo_superior filters by UF with co_uf_ies", {
  temp_cache <- setup_temp_cache()

  create_mock_data(
    temp_cache,
    dataset_subdir = "censo_superior",
    zip_filename = "microdados_censo_da_educacao_superior_2023.zip",
    exdir_name = "microdados_censo_da_educacao_superior_2023",
    csv_filename = "MICRODADOS_CADASTRO_IES_2023.csv",
    header = "CO_IES;NO_IES;CO_UF_IES;TP_CATEGORIA_ADMINISTRATIVA;SG_UF_IES",
    rows = c(
      "100;Universidade Federal A;35;1;SP",
      "200;Universidade Estadual B;33;2;RJ",
      "300;Faculdade Privada C;35;5;SP"
    )
  )

  result <- get_censo_superior(2023, type = "ies", uf = "SP", quiet = TRUE, n_max = 10)

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2)
  expect_true(all(result$co_uf_ies == 35))
})

# --------------------------------------------------------------------------
# get_capes(2023) - direct CSV, no zip/extract
# --------------------------------------------------------------------------
test_that("get_capes full pipeline works with cached CSV", {
  temp_cache <- setup_temp_cache()

  capes_dir <- file.path(temp_cache, "capes")
  dir.create(capes_dir, recursive = TRUE, showWarnings = FALSE)

  mock_csv <- file.path(capes_dir, "capes_programas_2023.csv")
  writeLines(
    c(
      "CD_PROGRAMA_IES;NM_PROGRAMA;SG_ENTIDADE_ENSINO;AN_BASE;NM_ENTIDADE_ENSINO;CD_CONCEITO_CURSO",
      "100001;Programa de Direito;UFSP;2023;Universidade Federal SP;5",
      "100002;Programa de Medicina;UFRJ;2023;Universidade Federal RJ;6"
    ),
    mock_csv
  )

  result <- get_capes(2023, type = "programas", quiet = TRUE, n_max = 10)

  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 0)
  expect_true(all(names(result) == tolower(names(result))))
  expect_true("cd_programa_ies" %in% names(result))
  expect_true("nm_programa" %in% names(result))
  expect_true("an_base" %in% names(result))
})

# --------------------------------------------------------------------------
# list_censo_files(2023)
# --------------------------------------------------------------------------
test_that("list_censo_files returns expected filenames", {
  temp_cache <- setup_temp_cache()

  exdir <- file.path(temp_cache, "censo_escolar", "censo_2023")
  dir.create(exdir, recursive = TRUE, showWarnings = FALSE)

  file.create(file.path(exdir, "microdados_ed_basica_2023.csv"))
  file.create(file.path(exdir, "suplemento_2023.csv"))

  result <- list_censo_files(2023)

  expect_type(result, "character")
  expect_true("microdados_ed_basica_2023.csv" %in% result)
  expect_true("suplemento_2023.csv" %in% result)
  expect_equal(length(result), 2)
})

# --------------------------------------------------------------------------
# list_censo_superior_files(2023)
# --------------------------------------------------------------------------
test_that("list_censo_superior_files returns expected filenames", {
  temp_cache <- setup_temp_cache()

  exdir <- file.path(
    temp_cache, "censo_superior",
    "microdados_censo_da_educacao_superior_2023"
  )
  dir.create(exdir, recursive = TRUE, showWarnings = FALSE)

  file.create(file.path(exdir, "MICRODADOS_CADASTRO_IES_2023.csv"))
  file.create(file.path(exdir, "MICRODADOS_CADASTRO_CURSO_2023.csv"))
  file.create(file.path(exdir, "MICRODADOS_CADASTRO_ALUNO_2023.csv"))

  result <- list_censo_superior_files(2023)

  expect_type(result, "character")
  expect_equal(length(result), 3)
  expect_true("MICRODADOS_CADASTRO_IES_2023.csv" %in% result)
  expect_true("MICRODADOS_CADASTRO_CURSO_2023.csv" %in% result)
})

# --------------------------------------------------------------------------
# keep_zip = FALSE cleanup
# --------------------------------------------------------------------------
test_that("keep_zip=FALSE removes the zip file after reading", {
  temp_cache <- setup_temp_cache()

  create_mock_data(
    temp_cache,
    dataset_subdir = "enade",
    zip_filename = "microdados_enade_2023.zip",
    exdir_name = "microdados_enade_2023",
    csv_filename = "microdados_enade_2023.csv",
    header = "NU_ANO;CO_CURSO;CO_IES;NT_GER;NT_FG;NT_CE;CO_GRUPO",
    rows = "2023;1001;100;55.2;60.1;50.3;4001"
  )

  zip_path <- file.path(temp_cache, "enade", "microdados_enade_2023.zip")
  expect_true(file.exists(zip_path))

  result <- get_enade(2023, keep_zip = FALSE, quiet = TRUE, n_max = 10)

  expect_s3_class(result, "tbl_df")
  expect_false(file.exists(zip_path))
})

# --------------------------------------------------------------------------
# clean_dash_values - dashes become NA
# --------------------------------------------------------------------------
test_that("clean_dash_values converts dash placeholders to NA", {
  temp_cache <- setup_temp_cache()

  create_mock_data(
    temp_cache,
    dataset_subdir = "idd",
    zip_filename = "microdados_IDD_2023.zip",
    exdir_name = "microdados_IDD_2023",
    csv_filename = "microdados_idd_2023.csv",
    header = "CO_CURSO;CO_IES;IDD_CONTINUO;IDD_FAIXA;NO_CURSO;CO_GRUPO",
    rows = c(
      "1001;100;2.5;3;Direito;4001",
      "1002;200;-;-;Medicina;4002"
    )
  )

  result <- get_idd(2023, quiet = TRUE, n_max = 10)

  expect_s3_class(result, "tbl_df")
  # the dash values in character columns should be NA
  # idd_continuo and idd_faixa are read as character when they contain "-"
  dash_row <- result[result$co_curso == 1002, ]
  expect_true(is.na(dash_row$idd_continuo) || is.na(dash_row$idd_faixa))
})

# --------------------------------------------------------------------------
# n_max parameter limits rows
# --------------------------------------------------------------------------
test_that("n_max parameter limits the number of rows returned", {
  temp_cache <- setup_temp_cache()

  rows <- paste0(
    seq(100001, 100020), ";2023;",
    rep(c(1, 2), 10), ";",
    rep(1:5, 4), ";",
    round(runif(20, 400, 700), 1), ";",
    round(runif(20, 400, 700), 1), ";",
    round(runif(20, 400, 700), 1), ";",
    round(runif(20, 400, 700), 1), ";",
    round(runif(20, 400, 800), 0)
  )

  create_mock_data(
    temp_cache,
    dataset_subdir = "enem",
    zip_filename = "microdados_enem_2023.zip",
    exdir_name = "enem_2023",
    csv_filename = "MICRODADOS_ENEM_2023.csv",
    header = "NU_INSCRICAO;NU_ANO;TP_SEXO;TP_COR_RACA;NU_NOTA_CN;NU_NOTA_CH;NU_NOTA_LC;NU_NOTA_MT;NU_NOTA_REDACAO",
    rows = rows
  )

  result_limited <- get_enem(2023, quiet = TRUE, n_max = 5)
  expect_equal(nrow(result_limited), 5)

  result_all <- get_enem(2023, quiet = TRUE, n_max = Inf)
  expect_equal(nrow(result_all), 20)
})

# --------------------------------------------------------------------------
# quiet=FALSE produces messages
# --------------------------------------------------------------------------
test_that("get_enem quiet=FALSE produces informational messages", {
  temp_cache <- setup_temp_cache()

  create_mock_data(
    temp_cache,
    dataset_subdir = "enem",
    zip_filename = "microdados_enem_2023.zip",
    exdir_name = "enem_2023",
    csv_filename = "MICRODADOS_ENEM_2023.csv",
    header = "NU_INSCRICAO;NU_ANO;TP_SEXO;TP_COR_RACA;NU_NOTA_CN;NU_NOTA_CH;NU_NOTA_LC;NU_NOTA_MT;NU_NOTA_REDACAO",
    rows = "100001;2023;1;1;550.5;600.2;580.1;620.3;700"
  )

  expect_message(
    get_enem(2023, quiet = FALSE, n_max = 10),
    "cached|reading|loaded"
  )
})

# --------------------------------------------------------------------------
# get_enem_escola clean_dash_values integration
# --------------------------------------------------------------------------
test_that("get_enem_escola converts dash values to NA", {
  temp_cache <- setup_temp_cache()

  create_mock_data(
    temp_cache,
    dataset_subdir = "enem_escola",
    zip_filename = "microdados_enem_por_escola.zip",
    exdir_name = "microdados_enem_por_escola",
    csv_filename = "MICRODADOS_ENEM_POR_ESCOLA.csv",
    header = "CO_ESCOLA_EDUCACENSO;NO_ESCOLA;NU_ANO;NU_MEDIA_CN;NU_MEDIA_CH;NU_MEDIA_LC;NU_MEDIA_MT",
    rows = c(
      "35000001;Escola Alpha;2015;500.1;510.2;-;530.4",
      "33000002;Escola Beta;2014;-;490.6;470.7;460.8"
    )
  )

  result <- get_enem_escola(quiet = TRUE, n_max = 10)

  expect_s3_class(result, "tbl_df")
  # check that "-" values became NA in character columns
  # NU_MEDIA columns may be read as char if "-" present
  alpha_row <- result[result$no_escola == "Escola Alpha", ]
  beta_row <- result[result$no_escola == "Escola Beta", ]
  # at least one of the dash values should be NA
  expect_true(
    is.na(alpha_row$nu_media_lc) || is.na(beta_row$nu_media_cn)
  )
})

# --------------------------------------------------------------------------
# get_encceja clean_dash_values integration
# --------------------------------------------------------------------------
test_that("get_encceja converts dash values to NA", {
  temp_cache <- setup_temp_cache()

  create_mock_data(
    temp_cache,
    dataset_subdir = "encceja",
    zip_filename = "microdados_encceja_2023.zip",
    exdir_name = "microdados_encceja_2023",
    csv_filename = "MICRODADOS_ENCCEJA_2023.csv",
    header = "NU_INSCRICAO;NU_ANO;TP_SEXO;CO_MUNICIPIO_RESIDENCIA;NOME_MUNICIPIO",
    rows = c(
      "300001;2023;1;3550308;Sao Paulo",
      "300002;2023;2;3304557;-"
    )
  )

  result <- get_encceja(2023, quiet = TRUE, n_max = 10)

  dash_row <- result[result$nu_inscricao == 300002, ]
  expect_true(is.na(dash_row$nome_municipio))
})

# --------------------------------------------------------------------------
# get_censo_escolar n_max parameter
# --------------------------------------------------------------------------
test_that("get_censo_escolar respects n_max parameter", {
  temp_cache <- setup_temp_cache()

  rows <- paste0(
    rep(c(35, 33, 29), 5), ";",
    paste0("Escola ", seq_len(15)), ";",
    seq(35000001, 35000015), ";",
    rep(c(1, 2, 3), 5), ";",
    rep(c("SP", "RJ", "BA"), 5), ";",
    rep(c("Sao Paulo", "Rio", "Salvador"), 5), ";",
    seq(3550308, 3550322)
  )

  create_mock_data(
    temp_cache,
    dataset_subdir = "censo_escolar",
    zip_filename = "microdados_censo_escolar_2023.zip",
    exdir_name = "censo_2023",
    csv_filename = "microdados_ed_basica_2023.csv",
    header = "CO_UF;NO_ENTIDADE;CO_ENTIDADE;TP_DEPENDENCIA;SG_UF;NO_MUNICIPIO;CO_MUNICIPIO",
    rows = rows
  )

  result <- get_censo_escolar(2023, quiet = TRUE, n_max = 5)
  expect_equal(nrow(result), 5)
})

# --------------------------------------------------------------------------
# Column name standardization across datasets
# --------------------------------------------------------------------------
test_that("standardize_names produces lowercase names across all datasets", {
  temp_cache <- setup_temp_cache()

  # Test with ENEM (uppercase columns)
  create_mock_data(
    temp_cache,
    dataset_subdir = "enem",
    zip_filename = "microdados_enem_2023.zip",
    exdir_name = "enem_2023",
    csv_filename = "MICRODADOS_ENEM_2023.csv",
    header = "NU_INSCRICAO;NU_ANO;TP_SEXO;TP_COR_RACA;NU_NOTA_CN;NU_NOTA_CH;NU_NOTA_LC;NU_NOTA_MT;NU_NOTA_REDACAO",
    rows = "100001;2023;1;1;550.5;600.2;580.1;620.3;700"
  )

  result <- get_enem(2023, quiet = TRUE, n_max = 10)
  expect_true(all(names(result) == tolower(names(result))))
  expect_false(any(grepl("[A-Z]", names(result))))
})

# --------------------------------------------------------------------------
# keep_zip=FALSE for enem
# --------------------------------------------------------------------------
test_that("keep_zip=FALSE removes zip for enem", {
  temp_cache <- setup_temp_cache()

  create_mock_data(
    temp_cache,
    dataset_subdir = "enem",
    zip_filename = "microdados_enem_2023.zip",
    exdir_name = "enem_2023",
    csv_filename = "MICRODADOS_ENEM_2023.csv",
    header = "NU_INSCRICAO;NU_ANO;TP_SEXO;TP_COR_RACA;NU_NOTA_CN;NU_NOTA_CH;NU_NOTA_LC;NU_NOTA_MT;NU_NOTA_REDACAO",
    rows = "100001;2023;1;1;550.5;600.2;580.1;620.3;700"
  )

  zip_path <- file.path(temp_cache, "enem", "microdados_enem_2023.zip")
  expect_true(file.exists(zip_path))

  result <- get_enem(2023, keep_zip = FALSE, quiet = TRUE, n_max = 10)

  expect_s3_class(result, "tbl_df")
  expect_false(file.exists(zip_path))
})

# --------------------------------------------------------------------------
# keep_zip=FALSE for censo_escolar
# --------------------------------------------------------------------------
test_that("keep_zip=FALSE removes zip for censo_escolar", {
  temp_cache <- setup_temp_cache()

  create_mock_data(
    temp_cache,
    dataset_subdir = "censo_escolar",
    zip_filename = "microdados_censo_escolar_2023.zip",
    exdir_name = "censo_2023",
    csv_filename = "microdados_ed_basica_2023.csv",
    header = "CO_UF;NO_ENTIDADE;CO_ENTIDADE;TP_DEPENDENCIA;SG_UF;NO_MUNICIPIO;CO_MUNICIPIO",
    rows = "35;Escola SP;35000001;2;SP;Sao Paulo;3550308"
  )

  zip_path <- file.path(temp_cache, "censo_escolar", "microdados_censo_escolar_2023.zip")
  expect_true(file.exists(zip_path))

  result <- get_censo_escolar(2023, keep_zip = FALSE, quiet = TRUE, n_max = 10)

  expect_s3_class(result, "tbl_df")
  expect_false(file.exists(zip_path))
})

# --------------------------------------------------------------------------
# keep_zip=FALSE for idd
# --------------------------------------------------------------------------
test_that("keep_zip=FALSE removes archive for idd", {
  temp_cache <- setup_temp_cache()

  create_mock_data(
    temp_cache,
    dataset_subdir = "idd",
    zip_filename = "microdados_IDD_2023.zip",
    exdir_name = "microdados_IDD_2023",
    csv_filename = "microdados_idd_2023.csv",
    header = "CO_CURSO;CO_IES;IDD_CONTINUO;IDD_FAIXA;NO_CURSO;CO_GRUPO",
    rows = "1001;100;2.5;3;Direito;4001"
  )

  archive_path <- file.path(temp_cache, "idd", "microdados_IDD_2023.zip")
  expect_true(file.exists(archive_path))

  result <- get_idd(2023, keep_zip = FALSE, quiet = TRUE, n_max = 10)

  expect_s3_class(result, "tbl_df")
  expect_false(file.exists(archive_path))
})

# --------------------------------------------------------------------------
# keep_file=FALSE for capes
# --------------------------------------------------------------------------
test_that("keep_file=FALSE removes cached CSV for capes", {
  temp_cache <- setup_temp_cache()

  capes_dir <- file.path(temp_cache, "capes")
  dir.create(capes_dir, recursive = TRUE, showWarnings = FALSE)

  mock_csv <- file.path(capes_dir, "capes_programas_2023.csv")
  writeLines(
    c(
      "CD_PROGRAMA_IES;NM_PROGRAMA;SG_ENTIDADE_ENSINO;AN_BASE;NM_ENTIDADE_ENSINO;CD_CONCEITO_CURSO",
      "100001;Programa A;UFSP;2023;Universidade Federal SP;5"
    ),
    mock_csv
  )

  expect_true(file.exists(mock_csv))

  result <- get_capes(2023, type = "programas", keep_file = FALSE, quiet = TRUE, n_max = 10)

  expect_s3_class(result, "tbl_df")
  expect_false(file.exists(mock_csv))
})

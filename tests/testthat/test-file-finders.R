# tests for find_*_file() internal functions
# these functions locate the correct CSV/TXT file inside extracted ZIP directories

# helper: create a mock file inside a temp directory
create_mock_file <- function(dir, ...) {
  paths <- file.path(dir, c(...))
  for (p in paths) {
    dir.create(dirname(p), recursive = TRUE, showWarnings = FALSE)
    writeLines("col1;col2\n1;2", p)
  }
  invisible(paths)
}

# ============================================================================
# find_enem_file
# ============================================================================

test_that("find_enem_file finds pre-2024 pattern (MICRODADOS_ENEM_YYYY)", {
  tmp <- withr::local_tempdir()
  create_mock_file(tmp, "DADOS/MICRODADOS_ENEM_2023.csv")

  result <- educabR:::find_enem_file(tmp, 2023, "participantes")
  expect_true(grepl("MICRODADOS_ENEM_2023\\.csv$", result))
})

test_that("find_enem_file finds pre-2024 fallback pattern (MICRODADOS_ENEM)", {
  tmp <- withr::local_tempdir()
  create_mock_file(tmp, "DADOS/MICRODADOS_ENEM.csv")

  result <- educabR:::find_enem_file(tmp, 2022, "participantes")
  expect_true(grepl("MICRODADOS_ENEM\\.csv$", result))
})

test_that("find_enem_file finds 2024+ PARTICIPANTES file", {
  tmp <- withr::local_tempdir()
  create_mock_file(tmp, "DADOS/PARTICIPANTES_2024.csv")

  result <- educabR:::find_enem_file(tmp, 2024, "participantes")
  expect_true(grepl("PARTICIPANTES_2024\\.csv$", result))
})

test_that("find_enem_file finds 2024+ RESULTADOS file", {
  tmp <- withr::local_tempdir()
  create_mock_file(tmp, "DADOS/RESULTADOS_2024.csv")

  result <- educabR:::find_enem_file(tmp, 2024, "resultados")
  expect_true(grepl("RESULTADOS_2024\\.csv$", result))
})

test_that("find_enem_file excludes ITENS files for pre-2024", {

  tmp <- withr::local_tempdir()
  create_mock_file(
    tmp,
    "DADOS/ITENS_MICRODADOS_ENEM_2023.csv",
    "DADOS/MICRODADOS_ENEM_2023.csv"
  )

  result <- educabR:::find_enem_file(tmp, 2023, "participantes")
  expect_false(grepl("ITENS", result))
  expect_true(grepl("MICRODADOS_ENEM_2023\\.csv$", result))
})

test_that("find_enem_file excludes ITENS files for 2024+ participantes", {
  tmp <- withr::local_tempdir()
  create_mock_file(
    tmp,
    "DADOS/ITENS_PROVA_PARTICIPANTES_2024.csv",
    "DADOS/PARTICIPANTES_2024.csv"
  )

  result <- educabR:::find_enem_file(tmp, 2024, "participantes")
  expect_false(grepl("ITENS", result))
  expect_true(grepl("PARTICIPANTES_2024\\.csv$", result))
})

test_that("find_enem_file falls back to ITENS file when it is the only match", {
  tmp <- withr::local_tempdir()
  create_mock_file(tmp, "DADOS/ITENS_MICRODADOS_ENEM_2023.csv")

  result <- educabR:::find_enem_file(tmp, 2023, "participantes")
  expect_true(grepl("ITENS", result))
})

test_that("find_enem_file prefers year-specific pattern over generic", {
  tmp <- withr::local_tempdir()
  create_mock_file(
    tmp,
    "DADOS/MICRODADOS_ENEM_2023.csv",
    "DADOS/MICRODADOS_ENEM.csv"
  )

  result <- educabR:::find_enem_file(tmp, 2023, "participantes")
  expect_true(grepl("MICRODADOS_ENEM_2023\\.csv$", result))
})

test_that("find_enem_file errors when no matching files found", {
  tmp <- withr::local_tempdir()
  create_mock_file(tmp, "DADOS/unrelated_file.xlsx")

  expect_error(
    educabR:::find_enem_file(tmp, 2023, "participantes"),
    "no ENEM data file found"
  )
})

# ============================================================================
# find_enade_file
# ============================================================================

test_that("find_enade_file finds microdados_enade_YYYY pattern", {
  tmp <- withr::local_tempdir()
  create_mock_file(tmp, "DADOS/microdados_enade_2023.csv")

  result <- educabR:::find_enade_file(tmp, 2023)
  expect_true(grepl("microdados_enade_2023\\.csv$", result))
})

test_that("find_enade_file finds microdadosYYYY pattern", {
  tmp <- withr::local_tempdir()
  create_mock_file(tmp, "DADOS/microdados2021.txt")

  result <- educabR:::find_enade_file(tmp, 2021)
  expect_true(grepl("microdados2021\\.txt$", result))
})

test_that("find_enade_file falls back to generic microdados_enade pattern", {
  tmp <- withr::local_tempdir()
  create_mock_file(tmp, "DADOS/microdados_enade.csv")

  result <- educabR:::find_enade_file(tmp, 2019)
  expect_true(grepl("microdados_enade\\.csv$", result))
})

test_that("find_enade_file falls back to generic microdados pattern", {
  tmp <- withr::local_tempdir()
  create_mock_file(tmp, "DADOS/microdados.txt")

  result <- educabR:::find_enade_file(tmp, 2018)
  expect_true(grepl("microdados\\.txt$", result))
})

test_that("find_enade_file prefers more specific pattern", {
  tmp <- withr::local_tempdir()
  create_mock_file(
    tmp,
    "DADOS/microdados_enade_2023.csv",
    "DADOS/microdados.csv"
  )

  result <- educabR:::find_enade_file(tmp, 2023)
  expect_true(grepl("microdados_enade_2023\\.csv$", result))
})

test_that("find_enade_file supports txt extension", {
  tmp <- withr::local_tempdir()
  create_mock_file(tmp, "DADOS/microdados_enade_2017.TXT")

  result <- educabR:::find_enade_file(tmp, 2017)
  expect_true(grepl("microdados_enade_2017\\.TXT$", result))
})

test_that("find_enade_file errors when no matching files found", {
  tmp <- withr::local_tempdir()
  create_mock_file(tmp, "DADOS/something_else.xlsx")

  expect_error(
    educabR:::find_enade_file(tmp, 2023),
    "no ENADE data file found"
  )
})

# ============================================================================
# find_encceja_file
# ============================================================================

test_that("find_encceja_file finds microdados_encceja_YYYY pattern", {
  tmp <- withr::local_tempdir()
  create_mock_file(tmp, "DADOS/microdados_encceja_2023.csv")

  result <- educabR:::find_encceja_file(tmp, 2023)
  expect_true(grepl("microdados_encceja_2023\\.csv$", result))
})

test_that("find_encceja_file excludes itens files", {
  tmp <- withr::local_tempdir()
  create_mock_file(
    tmp,
    "DADOS/itens_prova_encceja_2023.csv",
    "DADOS/microdados_encceja_2023.csv"
  )

  result <- educabR:::find_encceja_file(tmp, 2023)
  expect_false(grepl("itens", result, ignore.case = TRUE))
  expect_true(grepl("microdados_encceja_2023\\.csv$", result))
})

test_that("find_encceja_file excludes gabarito files", {
  tmp <- withr::local_tempdir()
  create_mock_file(
    tmp,
    "DADOS/gabarito_encceja_2023.csv",
    "DADOS/microdados_encceja_2023.csv"
  )

  result <- educabR:::find_encceja_file(tmp, 2023)
  expect_false(grepl("gabarito", result, ignore.case = TRUE))
  expect_true(grepl("microdados_encceja_2023\\.csv$", result))
})

test_that("find_encceja_file falls back to first candidate when no pattern matches", {
  tmp <- withr::local_tempdir()
  create_mock_file(tmp, "DADOS/encceja_dados_2023.csv")

  result <- educabR:::find_encceja_file(tmp, 2023)
  expect_true(grepl("encceja_dados_2023\\.csv$", result))
})

test_that("find_encceja_file falls back to all files if all are excluded", {
  tmp <- withr::local_tempdir()
  create_mock_file(tmp, "DADOS/itens_prova_encceja_2023.csv")

  result <- educabR:::find_encceja_file(tmp, 2023)
  expect_true(grepl("itens_prova_encceja_2023\\.csv$", result))
})

test_that("find_encceja_file supports txt extension", {
  tmp <- withr::local_tempdir()
  create_mock_file(tmp, "DADOS/microdados_encceja_2022.TXT")

  result <- educabR:::find_encceja_file(tmp, 2022)
  expect_true(grepl("microdados_encceja_2022\\.TXT$", result))
})

test_that("find_encceja_file errors when directory has no data files", {
  tmp <- withr::local_tempdir()
  create_mock_file(tmp, "DADOS/readme.pdf")

  expect_error(
    educabR:::find_encceja_file(tmp, 2023),
    "no ENCCEJA data file found"
  )
})

# ============================================================================
# find_enem_escola_file
# ============================================================================

test_that("find_enem_escola_file finds microdados_enem_por_escola pattern", {
  tmp <- withr::local_tempdir()
  create_mock_file(tmp, "DADOS/microdados_enem_por_escola.csv")

  result <- educabR:::find_enem_escola_file(tmp)
  expect_true(grepl("microdados_enem_por_escola\\.csv$", result))
})

test_that("find_enem_escola_file finds enem_por_escola pattern", {
  tmp <- withr::local_tempdir()
  create_mock_file(tmp, "DADOS/enem_por_escola_2005_2015.csv")

  result <- educabR:::find_enem_escola_file(tmp)
  expect_true(grepl("enem_por_escola", result))
})

test_that("find_enem_escola_file falls back to microdados pattern", {
  tmp <- withr::local_tempdir()
  create_mock_file(tmp, "DADOS/microdados.txt")

  result <- educabR:::find_enem_escola_file(tmp)
  expect_true(grepl("microdados\\.txt$", result))
})

test_that("find_enem_escola_file prefers most specific pattern", {
  tmp <- withr::local_tempdir()
  create_mock_file(
    tmp,
    "DADOS/microdados_enem_por_escola.csv",
    "DADOS/enem_por_escola.csv",
    "DADOS/microdados.csv"
  )

  result <- educabR:::find_enem_escola_file(tmp)
  expect_true(grepl("microdados_enem_por_escola\\.csv$", result))
})

test_that("find_enem_escola_file errors when no matching files found", {
  tmp <- withr::local_tempdir()
  create_mock_file(tmp, "DADOS/something.xlsx")

  expect_error(
    educabR:::find_enem_escola_file(tmp),
    "no ENEM por Escola data file found"
  )
})

# ============================================================================
# find_idd_file
# ============================================================================

test_that("find_idd_file finds microdados_idd_YYYY pattern", {
  tmp <- withr::local_tempdir()
  create_mock_file(tmp, "DADOS/microdados_idd_2023.csv")

  result <- educabR:::find_idd_file(tmp, 2023)
  expect_true(grepl("microdados_idd_2023\\.csv$", result))
})

test_that("find_idd_file finds idd_YYYY pattern", {
  tmp <- withr::local_tempdir()
  create_mock_file(tmp, "DADOS/idd_2022.txt")

  result <- educabR:::find_idd_file(tmp, 2022)
  expect_true(grepl("idd_2022\\.txt$", result))
})

test_that("find_idd_file falls back to generic microdados_idd pattern", {
  tmp <- withr::local_tempdir()
  create_mock_file(tmp, "DADOS/microdados_idd.csv")

  result <- educabR:::find_idd_file(tmp, 2019)
  expect_true(grepl("microdados_idd\\.csv$", result))
})

test_that("find_idd_file falls back to generic idd pattern", {
  tmp <- withr::local_tempdir()
  create_mock_file(tmp, "DADOS/idd.txt")

  result <- educabR:::find_idd_file(tmp, 2018)
  expect_true(grepl("idd\\.txt$", result))
})

test_that("find_idd_file prefers most specific pattern", {
  tmp <- withr::local_tempdir()
  create_mock_file(
    tmp,
    "DADOS/microdados_idd_2023.csv",
    "DADOS/idd_2023.csv",
    "DADOS/idd.csv"
  )

  result <- educabR:::find_idd_file(tmp, 2023)
  expect_true(grepl("microdados_idd_2023\\.csv$", result))
})

test_that("find_idd_file errors when no matching files found", {
  tmp <- withr::local_tempdir()
  create_mock_file(tmp, "DADOS/other_data.xlsx")

  expect_error(
    educabR:::find_idd_file(tmp, 2023),
    "no IDD data file found"
  )
})

# ============================================================================
# find_saeb_file
# ============================================================================

test_that("find_saeb_file finds TS_ALUNO_YYYY pattern", {
  tmp <- withr::local_tempdir()
  create_mock_file(tmp, "DADOS/TS_ALUNO_2023.csv")

  result <- educabR:::find_saeb_file(tmp, 2023, "aluno")
  expect_true(grepl("TS_ALUNO_2023\\.csv$", result))
})

test_that("find_saeb_file finds TS_ALUNO fallback pattern", {
  tmp <- withr::local_tempdir()
  create_mock_file(tmp, "DADOS/TS_ALUNO.csv")

  result <- educabR:::find_saeb_file(tmp, 2023, "aluno")
  expect_true(grepl("TS_ALUNO\\.csv$", result))
})

test_that("find_saeb_file finds ALUNO generic pattern", {
  tmp <- withr::local_tempdir()
  create_mock_file(tmp, "DADOS/ALUNO_SAEB_2023.csv")

  result <- educabR:::find_saeb_file(tmp, 2023, "aluno")
  expect_true(grepl("ALUNO", result))
})

test_that("find_saeb_file falls back to MICRODADOS_SAEB for aluno type", {
  tmp <- withr::local_tempdir()
  create_mock_file(tmp, "DADOS/MICRODADOS_SAEB_2023.csv")

  result <- educabR:::find_saeb_file(tmp, 2023, "aluno")
  expect_true(grepl("MICRODADOS_SAEB", result))
})

test_that("find_saeb_file finds TS_ESCOLA_YYYY pattern", {
  tmp <- withr::local_tempdir()
  create_mock_file(tmp, "DADOS/TS_ESCOLA_2023.csv")

  result <- educabR:::find_saeb_file(tmp, 2023, "escola")
  expect_true(grepl("TS_ESCOLA_2023\\.csv$", result))
})

test_that("find_saeb_file finds TS_DIRETOR_YYYY pattern", {
  tmp <- withr::local_tempdir()
  create_mock_file(tmp, "DADOS/TS_DIRETOR_2023.csv")

  result <- educabR:::find_saeb_file(tmp, 2023, "diretor")
  expect_true(grepl("TS_DIRETOR_2023\\.csv$", result))
})

test_that("find_saeb_file finds TS_PROFESSOR_YYYY pattern", {
  tmp <- withr::local_tempdir()
  create_mock_file(tmp, "DADOS/TS_PROFESSOR_2023.csv")

  result <- educabR:::find_saeb_file(tmp, 2023, "professor")
  expect_true(grepl("TS_PROFESSOR_2023\\.csv$", result))
})

test_that("find_saeb_file finds TS_EDUCACAO_INFANTIL pattern for aluno type", {
  tmp <- withr::local_tempdir()
  create_mock_file(tmp, "DADOS/TS_EDUCACAO_INFANTIL_2021.csv")

  result <- educabR:::find_saeb_file(tmp, 2021, "aluno")
  expect_true(grepl("TS_EDUCACAO_INFANTIL_2021\\.csv$", result))
})

test_that("find_saeb_file finds TS_SECRETARIO_MUNICIPAL pattern for escola type", {
  tmp <- withr::local_tempdir()
  create_mock_file(tmp, "DADOS/TS_SECRETARIO_MUNICIPAL_2023.csv")

  result <- educabR:::find_saeb_file(tmp, 2023, "escola")
  expect_true(grepl("TS_SECRETARIO_MUNICIPAL_2023\\.csv$", result))
})

test_that("find_saeb_file prefers year-specific over generic for aluno", {
  tmp <- withr::local_tempdir()
  create_mock_file(
    tmp,
    "DADOS/TS_ALUNO_2023.csv",
    "DADOS/TS_ALUNO.csv",
    "DADOS/MICRODADOS_SAEB.csv"
  )

  result <- educabR:::find_saeb_file(tmp, 2023, "aluno")
  expect_true(grepl("TS_ALUNO_2023\\.csv$", result))
})

test_that("find_saeb_file errors when no matching files found", {
  tmp <- withr::local_tempdir()
  create_mock_file(tmp, "DADOS/random_file.xlsx")

  expect_error(
    educabR:::find_saeb_file(tmp, 2023, "aluno"),
    "no SAEB"
  )
})

test_that("find_saeb_file errors for each type when empty", {
  tmp <- withr::local_tempdir()
  create_mock_file(tmp, "DADOS/random.xlsx")

  expect_error(educabR:::find_saeb_file(tmp, 2023, "escola"), "no SAEB")
  expect_error(educabR:::find_saeb_file(tmp, 2023, "diretor"), "no SAEB")
  expect_error(educabR:::find_saeb_file(tmp, 2023, "professor"), "no SAEB")
})

# ============================================================================
# find_censo_superior_file
# ============================================================================

test_that("find_censo_superior_file finds MICRODADOS_CADASTRO_IES_YYYY", {
  tmp <- withr::local_tempdir()
  create_mock_file(tmp, "DADOS/MICRODADOS_CADASTRO_IES_2023.csv")

  result <- educabR:::find_censo_superior_file(tmp, 2023, "ies")
  expect_true(grepl("MICRODADOS_CADASTRO_IES_2023\\.csv$", result))
})

test_that("find_censo_superior_file finds DM_IES_YYYY pattern", {
  tmp <- withr::local_tempdir()
  create_mock_file(tmp, "DADOS/DM_IES_2023.csv")

  result <- educabR:::find_censo_superior_file(tmp, 2023, "ies")
  expect_true(grepl("DM_IES_2023\\.csv$", result))
})

test_that("find_censo_superior_file finds MICRODADOS_CADASTRO_CURSO_YYYY", {
  tmp <- withr::local_tempdir()
  create_mock_file(tmp, "DADOS/MICRODADOS_CADASTRO_CURSO_2023.csv")

  result <- educabR:::find_censo_superior_file(tmp, 2023, "cursos")
  expect_true(grepl("MICRODADOS_CADASTRO_CURSO_2023\\.csv$", result))
})

test_that("find_censo_superior_file finds DM_CURSO_YYYY pattern", {
  tmp <- withr::local_tempdir()
  create_mock_file(tmp, "DADOS/DM_CURSO_2023.csv")

  result <- educabR:::find_censo_superior_file(tmp, 2023, "cursos")
  expect_true(grepl("DM_CURSO_2023\\.csv$", result))
})

test_that("find_censo_superior_file finds MICRODADOS_CADASTRO_ALUNO_YYYY", {
  tmp <- withr::local_tempdir()
  create_mock_file(tmp, "DADOS/MICRODADOS_CADASTRO_ALUNO_2023.csv")

  result <- educabR:::find_censo_superior_file(tmp, 2023, "alunos")
  expect_true(grepl("MICRODADOS_CADASTRO_ALUNO_2023\\.csv$", result))
})

test_that("find_censo_superior_file finds DM_ALUNO_YYYY pattern", {
  tmp <- withr::local_tempdir()
  create_mock_file(tmp, "DADOS/DM_ALUNO_2023.csv")

  result <- educabR:::find_censo_superior_file(tmp, 2023, "alunos")
  expect_true(grepl("DM_ALUNO_2023\\.csv$", result))
})

test_that("find_censo_superior_file finds MICRODADOS_CADASTRO_DOCENTE_YYYY", {
  tmp <- withr::local_tempdir()
  create_mock_file(tmp, "DADOS/MICRODADOS_CADASTRO_DOCENTE_2023.csv")

  result <- educabR:::find_censo_superior_file(tmp, 2023, "docentes")
  expect_true(grepl("MICRODADOS_CADASTRO_DOCENTE_2023\\.csv$", result))
})

test_that("find_censo_superior_file finds DM_DOCENTE_YYYY pattern", {
  tmp <- withr::local_tempdir()
  create_mock_file(tmp, "DADOS/DM_DOCENTE_2023.csv")

  result <- educabR:::find_censo_superior_file(tmp, 2023, "docentes")
  expect_true(grepl("DM_DOCENTE_2023\\.csv$", result))
})

test_that("find_censo_superior_file prefers MICRODADOS_CADASTRO over DM pattern", {
  tmp <- withr::local_tempdir()
  create_mock_file(
    tmp,
    "DADOS/MICRODADOS_CADASTRO_IES_2023.csv",
    "DADOS/DM_IES_2023.csv"
  )

  result <- educabR:::find_censo_superior_file(tmp, 2023, "ies")
  expect_true(grepl("MICRODADOS_CADASTRO_IES_2023\\.csv$", result))
})

test_that("find_censo_superior_file falls back to generic IES pattern", {
  tmp <- withr::local_tempdir()
  create_mock_file(tmp, "DADOS/IES_2023.csv")

  result <- educabR:::find_censo_superior_file(tmp, 2023, "ies")
  expect_true(grepl("IES_2023\\.csv$", result))
})

test_that("find_censo_superior_file falls back to generic MICRODADOS_CADASTRO_IES", {
  tmp <- withr::local_tempdir()
  create_mock_file(tmp, "DADOS/MICRODADOS_CADASTRO_IES.csv")

  result <- educabR:::find_censo_superior_file(tmp, 2023, "ies")
  expect_true(grepl("MICRODADOS_CADASTRO_IES\\.csv$", result))
})

test_that("find_censo_superior_file errors when no matching files found", {
  tmp <- withr::local_tempdir()
  create_mock_file(tmp, "DADOS/unrelated.xlsx")

  expect_error(
    educabR:::find_censo_superior_file(tmp, 2023, "ies"),
    "no Higher Education Census"
  )
  expect_error(
    educabR:::find_censo_superior_file(tmp, 2023, "cursos"),
    "no Higher Education Census"
  )
  expect_error(
    educabR:::find_censo_superior_file(tmp, 2023, "alunos"),
    "no Higher Education Census"
  )
  expect_error(
    educabR:::find_censo_superior_file(tmp, 2023, "docentes"),
    "no Higher Education Census"
  )
})

# ============================================================================
# build_saeb_zip_filename
# ============================================================================

test_that("build_saeb_zip_filename returns correct name for regular year", {
  result <- educabR:::build_saeb_zip_filename(2023)
  expect_equal(result, "microdados_saeb_2023.zip")
})

test_that("build_saeb_zip_filename returns correct name for regular year with default level", {
  result <- educabR:::build_saeb_zip_filename(2019, "fundamental_medio")
  expect_equal(result, "microdados_saeb_2019.zip")
})

test_that("build_saeb_zip_filename adds level suffix for 2021 fundamental_medio", {
  result <- educabR:::build_saeb_zip_filename(2021, "fundamental_medio")
  expect_equal(result, "microdados_saeb_2021_ensino_fundamental_e_medio.zip")
})

test_that("build_saeb_zip_filename adds level suffix for 2021 educacao_infantil", {
  result <- educabR:::build_saeb_zip_filename(2021, "educacao_infantil")
  expect_equal(result, "microdados_saeb_2021_educacao_infantil.zip")
})

test_that("build_saeb_zip_filename ignores level for non-2021 years", {
  result <- educabR:::build_saeb_zip_filename(2023, "educacao_infantil")
  expect_equal(result, "microdados_saeb_2023.zip")
})

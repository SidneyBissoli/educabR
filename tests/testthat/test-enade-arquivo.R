# get_enade() reads one file per call: INEP sorts each ENADE file by
# different variables (LGPD), so files cannot be joined row by row

local_enade_dir <- function(env = parent.frame()) {
  dir <- withr::local_tempdir(.local_envir = env)
  dados <- file.path(dir, "DADOS")
  dir.create(dados)
  # same courses, different row order in each file (as INEP ships them)
  writeLines(
    c("NU_ANO;CO_CURSO;CO_IES", "2023;10;1", "2023;20;2", "2023;30;3"),
    file.path(dados, "microdados2023_arq1.txt")
  )
  writeLines(
    c("NU_ANO;CO_CURSO;NT_GER", "2023;30;55.1", "2023;10;40.2", "2023;20;61.0"),
    file.path(dados, "microdados2023_arq2.txt")
  )
  writeLines(
    c("NU_ANO;CO_CURSO;QE_I01", "2023;20;A", "2023;30;B", "2023;10;C"),
    file.path(dados, "microdados2023_arq4.txt")
  )
  dir
}

test_that("get_enade reads only the requested file", {
  dir <- local_enade_dir()
  local_mocked_bindings(enade_prepare = function(...) dir)

  out <- get_enade(2023, arquivo = 2, quiet = TRUE)

  expect_equal(names(out), c("nu_ano", "co_curso", "nt_ger"))
  # rows keep the file's own order: nothing from arq1 is attached to them
  expect_equal(out$co_curso, c("30", "10", "20"))
})

test_that("get_enade uses the number in the file name (gaps allowed)", {
  dir <- local_enade_dir()
  local_mocked_bindings(enade_prepare = function(...) dir)

  out <- get_enade(2023, arquivo = 4, quiet = TRUE)
  expect_true("qe_i01" %in% names(out))

  expect_error(
    get_enade(2023, arquivo = 3, quiet = TRUE),
    "has no file"
  )
})

test_that("get_enade without arquivo reads file 1 and warns", {
  dir <- local_enade_dir()
  local_mocked_bindings(enade_prepare = function(...) dir)
  rlang::local_options(rlib_warning_verbosity = "verbose")

  expect_warning(
    out <- get_enade(2023, quiet = TRUE),
    "cannot be joined by student"
  )
  expect_equal(names(out), c("nu_ano", "co_curso", "co_ies"))
})

test_that("get_enade rejects more than one file", {
  expect_error(get_enade(2023, arquivo = c(1, 2)), "single file number")
})

test_that("list_enade_files maps each file to its variables", {
  dir <- local_enade_dir()
  local_mocked_bindings(enade_prepare = function(...) dir)

  files <- list_enade_files(2023, quiet = TRUE)

  expect_equal(files$arquivo, c(1L, 2L, 4L))
  expect_equal(files$variaveis, c("co_ies", "nt_ger", "qe_i01"))
  expect_equal(files$n_variaveis, c(1L, 1L, 1L))
})

test_that("enade_file_number reads the arq number", {
  expect_equal(
    enade_file_number(c(
      "microdados2023_arq12.txt",
      "x/microdados2013_arq4.txt",
      "microdados_enade_2010.csv"
    )),
    c(12L, 4L, 1L)
  )
})

test_that("ENADE 2004-2009 point to the LGPD files INEP still serves", {
  urls <- enade_urls[as.character(2004:2009)]
  expect_true(all(grepl("_LGPD\\.zip$", urls)))
})

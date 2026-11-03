# utils::unzip cannot decode Deflate64 entries (INEP used it for
# RESULTADOS_2025.csv in the ENEM 2025 archive) and silently skips them.
# extract_zip must notice the missing file and fall back to an external tool.

sevenz_available <- function() {
  cmd <- educabR:::find_7z()
  nzchar(Sys.which(cmd)) || file.exists(cmd)
}

make_mixed_zip <- function(dir) {
  stored <- file.path(dir, "PARTICIPANTES.csv")
  big <- file.path(dir, "RESULTADOS.csv")
  writeLines(c("a;b", "1;2"), stored)
  writeLines(c("x;y", rep("10;20", 5000)), big)
  zip <- file.path(dir, "mixed.zip")
  sevenz <- educabR:::find_7z()
  system2(
    sevenz,
    c("a", "-tzip", "-mm=Copy", shQuote(zip), shQuote(stored)),
    stdout = FALSE
  )
  system2(
    sevenz,
    c("a", "-tzip", "-mm=Deflate64", shQuote(zip), shQuote(big)),
    stdout = FALSE
  )
  zip
}

test_that("zip_file_count counts files and ignores directories", {
  dir <- withr::local_tempdir()
  dir.create(file.path(dir, "sub"))
  writeLines("a", file.path(dir, "sub", "one.txt"))
  writeLines("b", file.path(dir, "two.txt"))
  zip <- file.path(dir, "t.zip")
  withr::with_dir(dir, utils::zip(zip, c("sub", "two.txt"), flags = "-r -q"))

  expect_equal(educabR:::zip_file_count(zip), 2)
})

test_that("zip_file_count returns NA for an unreadable file", {
  bad <- withr::local_tempfile(fileext = ".zip")
  writeLines("not a zip", bad)
  expect_true(is.na(educabR:::zip_file_count(bad)))
})

test_that("extract_zip recovers a Deflate64 entry via an external tool", {
  skip_on_cran()
  skip_if_not(sevenz_available(), "7-Zip not available")
  dir <- withr::local_tempdir()
  zip <- make_mixed_zip(dir)
  skip_if_not(educabR:::zip_file_count(zip) == 2, "could not build test zip")

  exdir <- file.path(dir, "out")
  files <- educabR:::extract_zip(zip, exdir, quiet = TRUE)

  expect_setequal(basename(files), c("PARTICIPANTES.csv", "RESULTADOS.csv"))
  expect_equal(
    length(readLines(file.path(exdir, "RESULTADOS.csv"))),
    5001
  )
})

test_that("extract_zip errors when no tool can extract every file", {
  skip_on_cran()
  skip_if_not(sevenz_available(), "7-Zip not available")
  dir <- withr::local_tempdir()
  zip <- make_mixed_zip(dir)
  skip_if_not(educabR:::zip_file_count(zip) == 2, "could not build test zip")

  local_mocked_bindings(zip_external_tools = function() list())
  expect_error(
    educabR:::extract_zip(zip, file.path(dir, "out"), quiet = TRUE),
    "could not extract every file"
  )
})

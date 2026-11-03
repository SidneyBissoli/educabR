# readr guesses column types from the first 1,000 rows; a column that is
# empty there used to come back as logical with every later value NA

test_that("read_inep_file keeps values after 1,000 empty rows", {
  f <- withr::local_tempfile(fileext = ".csv")
  vals <- c(rep("", 1500), "7", "12", "3")
  writeLines(c("CO_ENTIDADE;VEM2206", paste0(seq_along(vals), ";", vals)), f)

  df <- suppressWarnings(suppressMessages(
    read_inep_file(f, delim = ";", encoding = "UTF-8", quiet = TRUE)
  ))

  expect_equal(sum(!is.na(df$VEM2206)), 3)
  expect_equal(tail(df$VEM2206, 3), c(7, 12, 3))
})

test_that("reread_problem_columns leaves clean reads untouched", {
  f <- withr::local_tempfile(fileext = ".csv")
  writeLines(c("A;B", "1;x", "2;y"), f)
  df <- readr::read_delim(f, delim = ";", show_col_types = FALSE)

  expect_identical(reread_problem_columns(df, f, ";", "UTF-8"), df)
})

test_that("detect_encoding finds a latin1 accent far into the file", {
  # Censo Escolar 2000: first accent at byte 238 MB of 318 MB
  f <- withr::local_tempfile(fileext = ".csv")
  writeBin(c(charToRaw(strrep("abc;", 5000)), as.raw(c(0x53, 0xE3, 0x6F))), f)

  expect_equal(detect_encoding(f, chunk_size = 1024), "latin1")
})

test_that("detect_encoding reads UTF-8 split across chunks", {
  f <- withr::local_tempfile(fileext = ".csv")
  # a 2-byte character (0xC3 0xA3) straddling the 1024-byte chunk boundary
  writeBin(
    c(rep(as.raw(0x61), 1023), as.raw(c(0xC3, 0xA3)), rep(as.raw(0x61), 10)),
    f
  )

  expect_equal(detect_encoding(f, chunk_size = 1024), "UTF-8")
})

test_that("detect_encoding calls an all-ASCII file UTF-8", {
  f <- withr::local_tempfile(fileext = ".csv")
  writeLines(c("A;B", "1;2"), f)
  expect_equal(detect_encoding(f), "UTF-8")
})

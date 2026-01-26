# tests for cache utilities

test_that("get_cache_dir returns a valid path", {
  cache_dir <- get_cache_dir()

  expect_true(is.character(cache_dir))
  expect_true(nchar(cache_dir) > 0)
})

test_that("set_cache_dir creates directory", {
  temp_dir <- file.path(tempdir(), "educabr_test_cache")

  # clean up if exists
  if (dir.exists(temp_dir)) {
    unlink(temp_dir, recursive = TRUE)
  }

  result <- set_cache_dir(temp_dir)

  expect_true(dir.exists(temp_dir))
  expect_equal(result, normalizePath(temp_dir, mustWork = FALSE))

  # clean up
  unlink(temp_dir, recursive = TRUE)
})

test_that("list_cache returns a tibble", {
  result <- list_cache()

  expect_s3_class(result, "tbl_df")
  expect_true(all(c("file", "size_mb", "modified") %in% names(result)))
})

test_that("available_years returns correct years", {
  censo_years <- available_years("censo_escolar")
  enem_years <- available_years("enem")
  ideb_years <- available_years("ideb")

  expect_true(all(censo_years >= 1995))
  expect_true(all(enem_years >= 1998))
  expect_true(all(ideb_years %in% c(2017, 2019, 2021, 2023)))
})

test_that("available_years validates dataset argument", {
  expect_error(
    available_years("invalid_dataset"),
    "should be one of"
  )
})

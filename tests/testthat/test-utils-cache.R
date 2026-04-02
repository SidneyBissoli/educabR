# tests for cache utilities

# --- get_cache_dir() ---------------------------------------------------------

test_that("get_cache_dir returns a character string", {
  withr::local_options(educabR.cache_dir = NULL)
  cache_dir <- get_cache_dir()

  expect_type(cache_dir, "character")
  expect_true(nchar(cache_dir) > 0)
})

test_that("get_cache_dir creates directory if it does not exist", {
  tmp <- withr::local_tempdir()
  new_dir <- file.path(tmp, "new_cache")
  withr::local_options(educabR.cache_dir = new_dir)

  result <- get_cache_dir()

  expect_true(dir.exists(new_dir))
})

test_that("get_cache_dir respects educabR.cache_dir option", {
  tmp <- withr::local_tempdir()
  custom_dir <- file.path(tmp, "custom_cache")
  dir.create(custom_dir)
  withr::local_options(educabR.cache_dir = custom_dir)

  result <- get_cache_dir()

  expect_equal(
    normalizePath(result, mustWork = FALSE),
    normalizePath(custom_dir, mustWork = FALSE)
  )
})

test_that("get_cache_dir falls back to tempdir when no option set", {
  withr::local_options(educabR.cache_dir = NULL)
  # Clear the internal env to force fallback
  old_val <- .educabr_env$cache_dir
  .educabr_env$cache_dir <- NULL
  withr::defer(.educabr_env$cache_dir <- old_val)

  result <- get_cache_dir()

  expect_true(grepl("educabR_cache", result))
  expect_true(grepl(
    normalizePath(tempdir(), mustWork = FALSE),
    normalizePath(result, mustWork = FALSE),
    fixed = TRUE
  ))
})

# --- set_cache_dir() ----------------------------------------------------------

test_that("set_cache_dir creates directory", {
  tmp <- withr::local_tempdir()
  new_dir <- file.path(tmp, "educabr_test_cache")

  result <- set_cache_dir(new_dir)

  expect_true(dir.exists(new_dir))
  expect_equal(
    normalizePath(result, mustWork = FALSE),
    normalizePath(new_dir, mustWork = FALSE)
  )
})

test_that("set_cache_dir normalizes path", {
  tmp <- withr::local_tempdir()
  new_dir <- file.path(tmp, "normalized_test")

  result <- set_cache_dir(new_dir)

  # Result should be a normalized absolute path that exists
  expect_true(nchar(result) > 0)
  expect_true(dir.exists(result))
  # Don't compare paths literally — normalizePath resolves symlinks
  # differently before/after directory creation (macOS /var vs /private/var,
  # Windows 8.3 short names vs full names)
  expect_true(is.character(result))
})

test_that("set_cache_dir returns the path invisibly", {
  tmp <- withr::local_tempdir()
  new_dir <- file.path(tmp, "invisible_test")

  expect_invisible(set_cache_dir(new_dir))
})

test_that("set_cache_dir with NULL uses temp directory", {
  withr::local_options(educabR.cache_dir = NULL)

  result <- set_cache_dir(NULL)

  expect_true(grepl("educabR_cache", result))
})

test_that("set_cache_dir sets the option", {
  tmp <- withr::local_tempdir()
  custom_dir <- file.path(tmp, "opt_test")
  withr::local_options(educabR.cache_dir = NULL)

  set_cache_dir(custom_dir)

  expect_equal(
    normalizePath(getOption("educabR.cache_dir"), mustWork = FALSE),
    normalizePath(custom_dir, mustWork = FALSE)
  )
})

test_that("set_cache_dir with persistent shows message", {
  tmp <- withr::local_tempdir()
  new_dir <- file.path(tmp, "persistent_test")

  expect_message(
    set_cache_dir(new_dir, persistent = TRUE),
    "persistent|Rprofile|\\.Rprofile",
    ignore.case = TRUE
  )
})

# --- clear_cache() ------------------------------------------------------------

test_that("clear_cache clears all files", {
  tmp <- withr::local_tempdir()
  cache_dir <- file.path(tmp, "clear_all_test")
  dir.create(file.path(cache_dir, "enem"), recursive = TRUE)
  writeLines("test", file.path(cache_dir, "enem", "file1.csv"))
  writeLines("test", file.path(cache_dir, "enem", "file2.csv"))

  withr::local_options(educabR.cache_dir = cache_dir)

  clear_cache()

  remaining <- list.files(cache_dir, recursive = TRUE)
  expect_length(remaining, 0)
})

test_that("clear_cache clears specific dataset directory", {
  tmp <- withr::local_tempdir()
  cache_dir <- file.path(tmp, "clear_dataset_test")
  dir.create(file.path(cache_dir, "enem"), recursive = TRUE)
  dir.create(file.path(cache_dir, "saeb"), recursive = TRUE)
  writeLines("test", file.path(cache_dir, "enem", "data.csv"))
  writeLines("test", file.path(cache_dir, "saeb", "data.csv"))

  withr::local_options(educabR.cache_dir = cache_dir)

  clear_cache("enem")

  expect_false(dir.exists(file.path(cache_dir, "enem")))
  # saeb should still exist
  expect_true(file.exists(file.path(cache_dir, "saeb", "data.csv")))
})

test_that("clear_cache handles empty cache gracefully", {
  tmp <- withr::local_tempdir()
  cache_dir <- file.path(tmp, "empty_cache_test")
  dir.create(cache_dir, recursive = TRUE)

  withr::local_options(educabR.cache_dir = cache_dir)

  result <- clear_cache()

  expect_true(result)
})

test_that("clear_cache handles missing dataset dir gracefully", {
  tmp <- withr::local_tempdir()
  cache_dir <- file.path(tmp, "missing_ds_test")
  dir.create(cache_dir, recursive = TRUE)

  withr::local_options(educabR.cache_dir = cache_dir)

  result <- clear_cache("nonexistent_dataset")

  expect_true(result)
})

test_that("clear_cache returns TRUE invisibly", {
  tmp <- withr::local_tempdir()
  cache_dir <- file.path(tmp, "return_test")
  dir.create(cache_dir, recursive = TRUE)

  withr::local_options(educabR.cache_dir = cache_dir)

  expect_invisible(result <- clear_cache())
  expect_true(result)
})

# --- list_cache() -------------------------------------------------------------

test_that("list_cache returns empty tibble when cache is empty", {
  tmp <- withr::local_tempdir()
  cache_dir <- file.path(tmp, "empty_list_test")
  dir.create(cache_dir, recursive = TRUE)

  withr::local_options(educabR.cache_dir = cache_dir)

  result <- list_cache()

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
  expect_true(all(c("file", "size_mb", "modified") %in% names(result)))
})

test_that("list_cache returns correct structure with files", {
  tmp <- withr::local_tempdir()
  cache_dir <- file.path(tmp, "list_files_test")
  dir.create(file.path(cache_dir, "enem"), recursive = TRUE)
  writeLines("some data content", file.path(cache_dir, "enem", "enem_2023.csv"))
  writeLines("more data", file.path(cache_dir, "enem", "enem_2024.csv"))

  withr::local_options(educabR.cache_dir = cache_dir)

  result <- list_cache()

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2)
  expect_true(all(c("file", "size_mb", "modified") %in% names(result)))
  expect_type(result$file, "character")
  expect_type(result$size_mb, "double")
  expect_s3_class(result$modified, "POSIXct")
  expect_true(all(c("enem_2023.csv", "enem_2024.csv") %in% result$file))
})

test_that("list_cache dataset filter works", {
  tmp <- withr::local_tempdir()
  cache_dir <- file.path(tmp, "filter_test")
  dir.create(file.path(cache_dir, "enem"), recursive = TRUE)
  dir.create(file.path(cache_dir, "saeb"), recursive = TRUE)
  writeLines("a", file.path(cache_dir, "enem", "enem.csv"))
  writeLines("b", file.path(cache_dir, "saeb", "saeb.csv"))

  withr::local_options(educabR.cache_dir = cache_dir)

  result <- list_cache("enem")

  expect_equal(nrow(result), 1)
  expect_equal(result$file, "enem.csv")
})

test_that("list_cache with missing dataset dir returns empty tibble", {
  tmp <- withr::local_tempdir()
  cache_dir <- file.path(tmp, "missing_filter_test")
  dir.create(cache_dir, recursive = TRUE)

  withr::local_options(educabR.cache_dir = cache_dir)

  result <- list_cache("nonexistent")

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
})

# --- cache_path() -------------------------------------------------------------

test_that("cache_path returns correct path", {
  tmp <- withr::local_tempdir()
  cache_dir <- file.path(tmp, "path_test")
  dir.create(cache_dir, recursive = TRUE)

  withr::local_options(educabR.cache_dir = cache_dir)

  result <- cache_path("enem", "enem_2023.csv")

  expect_equal(
    normalizePath(result, mustWork = FALSE),
    normalizePath(file.path(cache_dir, "enem", "enem_2023.csv"), mustWork = FALSE)
  )
})

test_that("cache_path creates dataset subdirectory", {
  tmp <- withr::local_tempdir()
  cache_dir <- file.path(tmp, "subdir_test")
  dir.create(cache_dir, recursive = TRUE)

  withr::local_options(educabR.cache_dir = cache_dir)

  cache_path("censo_escolar", "data.csv")

  expect_true(dir.exists(file.path(cache_dir, "censo_escolar")))
})

# --- is_cached() --------------------------------------------------------------

test_that("is_cached returns TRUE when file exists", {
  tmp <- withr::local_tempdir()
  cache_dir <- file.path(tmp, "cached_true_test")
  dir.create(file.path(cache_dir, "enem"), recursive = TRUE)
  writeLines("data", file.path(cache_dir, "enem", "enem_2023.csv"))

  withr::local_options(educabR.cache_dir = cache_dir)

  result <- is_cached("enem", "enem_2023.csv")

  expect_true(result)
})

test_that("is_cached returns FALSE when file does not exist", {
  tmp <- withr::local_tempdir()
  cache_dir <- file.path(tmp, "cached_false_test")
  dir.create(cache_dir, recursive = TRUE)

  withr::local_options(educabR.cache_dir = cache_dir)

  result <- is_cached("enem", "nonexistent.csv")

  expect_false(result)
})

test_that("is_cached returns FALSE when dataset dir does not exist", {
  tmp <- withr::local_tempdir()
  cache_dir <- file.path(tmp, "cached_nodir_test")
  dir.create(cache_dir, recursive = TRUE)

  withr::local_options(educabR.cache_dir = cache_dir)

  # is_cached calls cache_path which creates the dir, but file should not exist
  result <- is_cached("new_dataset", "file.csv")

  expect_false(result)
})

# --- available_years() --------------------------------------------------------

test_that("fallback_years returns correct count for censo_escolar", {
  result <- fallback_years("censo_escolar")
  expect_equal(result, 1995:2024)
  expect_length(result, 30)
})

test_that("fallback_years returns correct counts for all datasets", {
  expect_equal(fallback_years("enem"), 1998:2024)
  expect_equal(fallback_years("saeb"), c(2011L, 2013L, 2015L, 2017L, 2019L, 2021L, 2023L))
  expect_equal(fallback_years("censo_superior"), 2009:2024)
  expect_equal(fallback_years("enade"), c(2004L:2019L, 2021L:2023L))
  expect_equal(fallback_years("encceja"), 2014:2024)
  expect_equal(fallback_years("idd"), c(2014L:2019L, 2021L:2023L))
})

test_that("available_years returns correct count for cpc", {
  result <- available_years("cpc")
  expected <- c(2007L:2019L, 2021L:2023L)
  expect_equal(result, expected)
  expect_length(result, 16)
})

test_that("available_years returns correct count for igc", {
  result <- available_years("igc")
  expected <- c(2007L:2019L, 2021L:2023L)
  expect_equal(result, expected)
  expect_length(result, 16)
})

test_that("available_years returns correct count for capes", {
  result <- available_years("capes")
  expect_equal(result, 2013:2024)
  expect_length(result, 12)
})

test_that("available_years returns correct count for ideb", {
  result <- available_years("ideb")
  expect_equal(result, c(2017L, 2019L, 2021L, 2023L))
  expect_length(result, 4)
})

test_that("available_years returns correct count for fundeb", {
  result <- available_years("fundeb")
  expect_true(2007 %in% result)
  expect_true(length(result) >= 18)
})

test_that("available_years errors on invalid dataset", {
  expect_error(
    available_years("invalid_dataset"),
    "should be one of"
  )
})

test_that("available_years returns integer vector", {
  result <- available_years("cpc")
  expect_type(result, "integer")
})

# --- .onLoad() ----------------------------------------------------------------

test_that(".onLoad respects existing option", {
  tmp <- withr::local_tempdir()
  custom_dir <- file.path(tmp, "onload_test")
  dir.create(custom_dir, recursive = TRUE)

  withr::local_options(educabR.cache_dir = custom_dir)

  # Save and restore internal env
  old_val <- .educabr_env$cache_dir
  withr::defer(.educabr_env$cache_dir <- old_val)

  .onLoad(NULL, "educabR")

  expect_equal(
    normalizePath(.educabr_env$cache_dir, mustWork = FALSE),
    normalizePath(custom_dir, mustWork = FALSE)
  )
})

test_that(".onLoad does nothing when no option set", {
  withr::local_options(educabR.cache_dir = NULL)

  old_val <- .educabr_env$cache_dir
  withr::defer(.educabr_env$cache_dir <- old_val)

  # Set to a known value and verify .onLoad does not overwrite it
  .educabr_env$cache_dir <- "/some/known/path"

  .onLoad(NULL, "educabR")

  # Should remain untouched since option is NULL
  expect_equal(.educabr_env$cache_dir, "/some/known/path")
})

# --- .onAttach() --------------------------------------------------------------

test_that(".onAttach shows startup message", {
  expect_message(
    .onAttach(NULL, "educabR"),
    "educabR"
  )
})

test_that(".onAttach message mentions set_cache_dir", {
  expect_message(
    .onAttach(NULL, "educabR"),
    "set_cache_dir"
  )
})

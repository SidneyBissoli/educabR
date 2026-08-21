# dynamic year discovery must never remove known years (#17):
# a transient HEAD failure used to drop a valid year (e.g. 2022 for
# censo_escolar) from the session's available years

test_that("discover_inep_years keeps all known years when every HEAD fails", {
  local_mocked_bindings(
    inep_head_ok = function(url) FALSE,
    .package = "educabR"
  )

  years <- discover_inep_years("censo_escolar")
  known <- fallback_years("censo_escolar")

  expect_true(all(known %in% years))
  expect_true(2022L %in% years)
})

test_that("discover_inep_years adds newly confirmed years beyond the known list", {
  local_mocked_bindings(
    inep_head_ok = function(url) TRUE,
    .package = "educabR"
  )

  years <- discover_inep_years("censo_escolar")
  known <- fallback_years("censo_escolar")
  current_year <- as.integer(format(Sys.Date(), "%Y"))
  expected_new <- setdiff(
    seq(min(known), current_year),
    known
  )

  expect_true(all(known %in% years))
  expect_true(all(expected_new %in% years))
})

test_that("discover_inep_years only probes candidates beyond the known years", {
  probed <- integer(0)
  local_mocked_bindings(
    inep_head_ok = function(url) {
      year <- as.integer(regmatches(url, regexpr("[0-9]{4}", url)))
      probed <<- c(probed, year)
      FALSE
    },
    .package = "educabR"
  )

  discover_inep_years("censo_escolar")
  known <- fallback_years("censo_escolar")

  expect_true(all(probed > max(known)))
})

test_that("discover_enade_years keeps all known years when every HEAD fails", {
  local_mocked_bindings(
    inep_head_ok = function(url) FALSE,
    .package = "educabR"
  )

  years <- discover_enade_years()

  expect_identical(years, sort(as.integer(names(educabR:::enade_urls))))
})

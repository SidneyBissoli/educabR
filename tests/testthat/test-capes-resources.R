# CAPES packages and resource matching (2013-2020 years used to fail)

test_that("capes_resource_year reads the reference year, not any year", {
  x <- c(
    "br-capes-colsucup-prog-2017-2021-11-10.csv",
    "br-capes-btd-2013a2016-2017-12-01_2014.csv",
    "https://x/br-capes-colsucup-curso-2013a2016-2020-06-12_2016.csv",
    "br-capes-colsucup-discentes-2024-2025-12-01.csv",
    "leia-me.pdf"
  )
  expect_equal(capes_resource_year(x), c(2017L, 2014L, 2016L, 2024L, NA))
})

test_that("a 2013-2016 file is not taken for another year of the range", {
  # every name in the 2013-2016 packages contains "2016"
  urls <- sprintf("br-capes-btd-2013a2016-2017-12-01_%d.csv", 2013:2016)
  expect_equal(capes_resource_year(urls), 2013:2016)
})

test_that("every type and range resolves to a package slug", {
  for (type in names(capes_type_slugs)) {
    for (range in capes_year_ranges) {
      key <- paste(type, range$prefix)
      slug <- if (key %in% names(capes_package_slugs)) {
        capes_package_slugs[[key]]
      } else {
        paste0(range$prefix, "-", capes_type_slugs[[type]])
      }
      expect_true(nzchar(slug))
    }
  }
  expect_match(
    capes_package_slugs[["programas 2013-a-2016"]],
    "stricto-census"
  )
})

test_that("discover_capes_url uses the override slug and the right year", {
  asked <- NULL
  local_mocked_bindings(
    request = function(url) {
      asked <<- url
      structure(list(url = url), class = "httr2_request")
    },
    req_timeout = function(req, ...) req,
    req_retry = function(req, ...) req,
    req_perform = function(req) structure(list(), class = "httr2_response"),
    resp_body_json = function(resp) {
      list(
        success = TRUE,
        result = list(
          resources = lapply(2013:2016, function(y) {
            list(
              format = "CSV",
              name = sprintf("BR-CAPES-BTD-2013A2016-2017-12-01_%d", y),
              url = sprintf(
                "https://x/br-capes-btd-2013a2016-2017-12-01_%d.csv",
                y
              )
            )
          })
        )
      )
    },
    .package = "httr2"
  )

  url <- discover_capes_url(2016, "catalogo")

  expect_match(asked, "catalogo-de-teses-e-dissertacoes-de-2013-a-2016")
  expect_match(url, "_2016\\.csv$")
})

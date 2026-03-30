# tests for enem_summary

test_that("enem_summary calculates correct statistics", {
  df <- tibble::tibble(
    nu_nota_cn = c(400, 500, 600, 700, 800),
    nu_nota_ch = c(300, 400, 500, 600, 700),
    tp_sexo = c("M", "F", "M", "F", "M")
  )

  result <- enem_summary(df)

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2)
  expect_true(all(c("variable", "n", "n_valid", "mean", "sd",
                     "min", "q25", "median", "q75", "max") %in% names(result)))

  # check nu_nota_cn stats
  cn <- result[result$variable == "nu_nota_cn", ]
  expect_equal(cn$n, 5)
  expect_equal(cn$n_valid, 5)
  expect_equal(cn$mean, 600)
  expect_equal(cn$median, 600)
  expect_equal(cn$min, 400)
  expect_equal(cn$max, 800)
})

test_that("enem_summary handles NA values", {
  df <- tibble::tibble(
    nu_nota_cn = c(400, NA, 600, NA, 800)
  )

  result <- enem_summary(df)

  expect_equal(result$n, 5)
  expect_equal(result$n_valid, 3)
  expect_equal(result$mean, 600)
  expect_equal(result$median, 600)
})

test_that("enem_summary groups by variable", {
  df <- tibble::tibble(
    nu_nota_cn = c(400, 500, 600, 700),
    tp_sexo = c("M", "F", "M", "F")
  )

  result <- enem_summary(df, by = "tp_sexo")

  expect_equal(nrow(result), 2)
  expect_true("tp_sexo" %in% names(result))

  m_row <- result[result$tp_sexo == "M", ]
  f_row <- result[result$tp_sexo == "F", ]

  expect_equal(m_row$mean, 500)
  expect_equal(f_row$mean, 600)
  expect_equal(m_row$n, 2)
  expect_equal(f_row$n, 2)
})

test_that("enem_summary errors when no score columns found", {
  df <- tibble::tibble(
    tp_sexo = c("M", "F"),
    tp_cor_raca = c(1, 2)
  )

  expect_error(enem_summary(df), "no score columns found")
})

# tests for detect_encoding(): bytes are written raw so the result does
# not depend on the platform's native encoding or iconv implementation

write_bytes <- function(bytes) {
  f <- withr::local_tempfile(.local_envir = parent.frame())
  writeBin(as.raw(bytes), f)
  f
}

# "Cod;Cont" + i-acute
ascii <- as.integer(charToRaw("Cod;Cont"))

test_that("detect_encoding flags latin1 bytes (macOS iconv passed them)", {
  f <- write_bytes(c(ascii, 0xED, 0x6E, 0x75, 0x6F)) # "Cont\xednuo"
  expect_equal(educabR:::detect_encoding(f), "latin1")
})

test_that("detect_encoding accepts UTF-8", {
  f <- write_bytes(c(ascii, 0xC3, 0xAD, 0x6E, 0x75, 0x6F)) # UTF-8 i-acute
  expect_equal(educabR:::detect_encoding(f), "UTF-8")
})

test_that("detect_encoding accepts UTF-8 cut inside a character", {
  # 10,000-byte chunk ending in the first byte of a 2-byte character
  bytes <- c(rep(0x61, 9999), 0xC3, 0xAD)
  f <- write_bytes(bytes)
  expect_equal(educabR:::detect_encoding(f), "UTF-8")
})

test_that("detect_encoding keeps a latin1 byte at the end of the file", {
  # the whole file fits in the chunk, so nothing was cut
  f <- write_bytes(c(rep(0x61, 9999), 0xED))
  expect_equal(educabR:::detect_encoding(f), "latin1")
})

test_that("drop_incomplete_utf8_tail only drops incomplete sequences", {
  drop <- educabR:::drop_incomplete_utf8_tail
  expect_equal(drop(as.raw(c(0x61, 0xE2, 0x82))), as.raw(0x61))
  expect_equal(
    drop(as.raw(c(0x61, 0xE2, 0x82, 0xAC))),
    as.raw(c(0x61, 0xE2, 0x82, 0xAC))
  )
  expect_equal(drop(as.raw(c(0x61, 0x62))), as.raw(c(0x61, 0x62)))
  expect_equal(drop(raw(0)), raw(0))
})

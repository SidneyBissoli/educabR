# Fetch the IDEB xlsx into cache

Internal function to download the IDEB spreadsheet to `xlsx_path`. For
2023 and earlier, the URL points straight at the xlsx. From 2025 on,
INEP packages the xlsx inside a zip (alongside an ods copy and an md5
file); the zip is downloaded, the xlsx extracted into the cache, and the
zip and extraction leftovers removed.

## Usage

``` r
fetch_ideb_file(url, xlsx_path, quiet = FALSE)
```

## Arguments

- url:

  Download URL from
  [`build_ideb_url()`](https://sidneybissoli.github.io/educabR/reference/build_ideb_url.md)
  (`.xlsx` or `.zip`).

- xlsx_path:

  Cache destination for the xlsx.

- quiet:

  Logical. If `TRUE`, suppresses progress messages.

## Value

`xlsx_path`, invisibly.

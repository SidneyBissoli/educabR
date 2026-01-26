# Extract a ZIP file

Internal function to extract ZIP files with progress indication.

## Usage

``` r
extract_zip(zipfile, exdir, quiet = FALSE)
```

## Arguments

- zipfile:

  Path to the ZIP file.

- exdir:

  Directory to extract to.

- quiet:

  Logical. If `TRUE`, suppresses progress messages.

## Value

A character vector of extracted file paths.

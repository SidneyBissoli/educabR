# Extract a ZIP file

Internal function to extract ZIP files with progress indication.

[`utils::unzip()`](https://rdrr.io/r/utils/unzip.html) is tried first.
Its zlib backend cannot decode some entries INEP ships (Deflate64
compression, used for `RESULTADOS_2025.csv` in the ENEM 2025 archive)
and skips them with only a "zip file is corrupt" warning, so the number
of extracted files is compared with the archive's listing. When anything
is missing, the archive is extracted again with an external tool (7-Zip,
then PowerShell on Windows or `unzip` elsewhere), and an error is raised
if the archive is still incomplete.

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

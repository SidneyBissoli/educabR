# Extract an archive file (ZIP or 7z)

Internal function to extract archive files. Supports ZIP and 7z formats.
For ZIP files, delegates to
[`extract_zip()`](https://sidneybissoli.github.io/educabR/reference/extract_zip.md).
For 7z files, uses the system `7z` command.

## Usage

``` r
extract_archive(archive, exdir, quiet = FALSE)
```

## Arguments

- archive:

  Path to the archive file.

- exdir:

  Directory to extract to.

- quiet:

  Logical. If `TRUE`, suppresses progress messages.

## Value

A character vector of extracted file paths.

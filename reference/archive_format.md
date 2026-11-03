# Identify an archive format from its first bytes

Internal function. Returns `"zip"`, `"7z"` or `"rar"` from the file
signature, or `NA` when none matches. Used instead of the extension,
which INEP does not always get right (IDD 2022 is a RAR named `.zip`).

## Usage

``` r
archive_format(bytes)
```

## Arguments

- bytes:

  A raw vector with the first bytes of the file (at least 6).

## Value

A string or `NA_character_`.

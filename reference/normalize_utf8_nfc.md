# Normalize character columns to UTF-8 NFC

Ensures every character column in a data frame is valid UTF-8 in
canonical NFC form. Without this step, equality comparisons against
string literals fail silently on Windows when the source file's encoding
produces decomposed (NFD) or otherwise non-canonical strings (e.g.
`filter(rede == "Pública")` returns 0 rows even though `"Pública"` is in
the data). Applied at every read entrypoint —
[`read_inep_file()`](https://sidneybissoli.github.io/educabR/reference/read_inep_file.md),
[`read_ideb_excel()`](https://sidneybissoli.github.io/educabR/reference/read_ideb_excel.md),
[`read_excel_safe()`](https://sidneybissoli.github.io/educabR/reference/read_excel_safe.md),
and the FUNDEB OData fetcher — so downstream user code can compare with
literals safely on any platform.

## Usage

``` r
normalize_utf8_nfc(df)
```

## Arguments

- df:

  A data frame.

## Value

The data frame with character columns normalized; non-character columns
are returned unchanged.

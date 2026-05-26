# Decide which IDEB columns to keep for a given metric/year

Internal helper for
[`read_ideb_excel()`](https://sidneybissoli.github.io/educabR/reference/read_ideb_excel.md).
Keeps all non-`vl_*` columns (id columns) and the subset of `vl_*`
columns that match the requested metric (and year, if given). Matching
is done against a standardized lowercase/ASCII form of the names so it
works against the raw INEP headers regardless of accents or casing.

## Usage

``` r
ideb_keep_cols(col_names, metric, year = NULL)
```

## Arguments

- col_names:

  Character vector of raw column names from the xlsx header.

- metric:

  One of `"indicador"`, `"aprovacao"`, `"nota"`, `"meta"`.

- year:

  Optional integer vector of IDEB editions.

## Value

Logical vector of the same length as `col_names`.

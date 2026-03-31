# Clean IDEB numeric columns

Internal function to convert `vl_*` columns from character to numeric.
Handles `"-"` and `"ND"` as `NA`, and replaces comma decimal separators
with dots.

## Usage

``` r
clean_ideb_values(df)
```

## Arguments

- df:

  A data frame with IDEB data.

## Value

The data frame with `vl_*` columns as numeric.

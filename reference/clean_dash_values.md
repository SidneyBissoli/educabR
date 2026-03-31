# Clean dash placeholder values

Internal function to replace dash placeholders (`"-"`, `"\u2013"`) with
`NA` in all character columns. Common in INEP datasets where missing
values are encoded as dashes.

## Usage

``` r
clean_dash_values(df)
```

## Arguments

- df:

  A data frame.

## Value

The data frame with dashes replaced by `NA`.

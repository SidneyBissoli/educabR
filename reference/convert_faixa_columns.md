# Convert faixa columns to numeric

Internal function to convert columns ending in `_faixa` from character
to numeric. Values like `"SC"` (Sem Conceito) are converted to `NA`.

## Usage

``` r
convert_faixa_columns(df)
```

## Arguments

- df:

  A data frame.

## Value

The data frame with faixa columns as numeric.

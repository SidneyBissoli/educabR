# Convert faixa and continuo columns to numeric

Internal function to convert score columns (names ending in `_faixa`,
`_faixas` or `_continuo`) from character to numeric. Non-numeric markers
such as `"SC"` (Sem Conceito) and `"sub judice"` are converted to `NA`.
Stacking the sheets of the IGC 2007-2016 can turn these columns into
text when only one sheet carries such a marker.

## Usage

``` r
convert_faixa_columns(df)
```

## Arguments

- df:

  A data frame.

## Value

The data frame with score columns as numeric.

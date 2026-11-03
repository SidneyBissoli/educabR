# Standardize column names

Internal function to standardize column names to lowercase with
underscores.

When two names collide after standardization (CPC 2007/2008 have both
"Docentes Doutores" and "% Docentes Doutores"), a "%" in the colliding
original name becomes "pct"; any collision left gets a numeric suffix
(`_2`, `_3`, ...). Names that do not collide are unchanged.

## Usage

``` r
standardize_names(df)
```

## Arguments

- df:

  A data frame.

## Value

The data frame with standardized names.

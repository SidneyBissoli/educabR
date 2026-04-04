# Fix regiao/estado unnamed columns and filter rows

Internal function to rename unnamed columns in regiao_uf data and filter
to keep only regions or states depending on the requested level.

## Usage

``` r
fix_regiao_uf_cols(df, level)
```

## Arguments

- df:

  Data frame with regiao_uf data.

- level:

  `"regiao"` or `"estado"`.

## Value

Data frame with renamed columns, filtered to the requested level.

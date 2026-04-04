# Reshape IDEB data from wide to long format

Internal function to transform IDEB data from wide format (one column
per year/metric) to tidy long format, filtered by the requested metric
type.

## Usage

``` r
reshape_ideb(df, level, metric, stage = NULL)
```

## Arguments

- df:

  Data frame with IDEB data (wide format, standardized names).

- level:

  Geographic level (determines ID columns).

- metric:

  Type of metric to extract.

## Value

A tibble in long format.

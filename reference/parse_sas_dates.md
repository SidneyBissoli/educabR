# Parse SAS datetime columns to Date

Internal function to convert columns with SAS datetime format (e.g.
"12FEB2024:00:00:00") to Date objects.

## Usage

``` r
parse_sas_dates(df)
```

## Arguments

- df:

  A data frame.

## Value

The data frame with date columns converted.

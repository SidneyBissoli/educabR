# Parse date columns (dt\_*, dh\_*) to Date

Internal function to convert text date columns to Date objects. INEP and
CAPES use several formats: SAS datetime ("12FEB2024:00:00:00"),
"12/12/2013 00:00:00", "12/12/2013" and ISO "2013-12-12". For each
column the format that reads every non-empty value is used. If no format
reads them all, the column is kept as text: converting with a single
fixed format turned every value of the CAPES catalogo 2013-2016 dates
into `NA`.

## Usage

``` r
parse_sas_dates(df)
```

## Arguments

- df:

  A data frame.

## Value

The data frame with date columns converted.

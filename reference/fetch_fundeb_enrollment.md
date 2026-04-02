# Fetch FUNDEB enrollment data from FNDE OData API

Internal function to fetch FUNDEB enrollment data from FNDE's OData API
with pagination support.

## Usage

``` r
fetch_fundeb_enrollment(year, uf = NULL, n_max = Inf, quiet = FALSE)
```

## Arguments

- year:

  The year.

- uf:

  Optional UF code to filter at the API level.

- n_max:

  Maximum number of rows to fetch.

- quiet:

  Logical. If `TRUE`, suppresses progress messages.

## Value

A tibble with enrollment data.

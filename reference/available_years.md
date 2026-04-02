# Check available years for a dataset

Returns the years available for a given dataset. On the first call in a
session, queries the data source to discover which years are actually
available (requires internet). Results are cached for the session. Falls
back to a known list if discovery fails.

## Usage

``` r
available_years(dataset)
```

## Arguments

- dataset:

  The dataset name.

## Value

An integer vector of available years.

## Examples

``` r
if (FALSE) { # \dontrun{
available_years("enem")
available_years("enade")
available_years("fundeb_enrollment")
} # }
```

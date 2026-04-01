# Discover CAPES download URL via CKAN API

Internal function to discover the download URL for a specific CAPES
dataset and year using the CKAN API. CAPES URLs contain UUIDs and cannot
be predicted, so they must be discovered dynamically.

## Usage

``` r
discover_capes_url(year, type)
```

## Arguments

- year:

  The year.

- type:

  The data type.

## Value

A character string with the download URL.

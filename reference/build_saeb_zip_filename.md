# Build SAEB ZIP filename

Internal function to build the correct ZIP filename for SAEB data.
Handles the special case of 2021 (split into two files).

## Usage

``` r
build_saeb_zip_filename(year, level = "fundamental_medio")
```

## Arguments

- year:

  The year.

- level:

  The level (only relevant for 2021).

## Value

The ZIP filename.

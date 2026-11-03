# Resolve the source file of a Conceito Enade edition

Internal function. Returns the URL, the sheet and the resolved `type`
for a year: the Conceito Enade spreadsheet, the combined Enade/CPC table
for 2007-2011, or one of the two 2025 files.

## Usage

``` r
conceito_enade_source(year, type = NULL)
```

## Arguments

- year:

  The year.

- type:

  `NULL`, or `"licenciaturas"` / `"medicina"` for 2025.

## Value

A list with `url`, `sheet` and `type`.

# Get ENEM item response data

Downloads and processes ENEM item response (gabarito) data, which
contains detailed information about each question.

## Usage

``` r
get_enem_itens(year, n_max = Inf, quiet = FALSE)
```

## Arguments

- year:

  The year of the exam (2009-2023).

- n_max:

  Maximum number of rows to read.

- quiet:

  Logical. If `TRUE`, suppresses progress messages.

## Value

A tibble with item response data.

## Examples

``` r
# \donttest{
# get item data for 2023
itens <- get_enem_itens(2023)
#> ℹ reading ENEM item data...
#> ℹ reading file with encoding: "UTF-8"
#> ✔ loaded 5550 rows and 14 columns
# }
```

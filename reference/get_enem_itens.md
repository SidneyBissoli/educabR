# Get ENEM item response data

Downloads and processes ENEM item response (gabarito) data, which
contains detailed information about each question.

## Usage

``` r
get_enem_itens(year, n_max = Inf, keep_zip = TRUE, quiet = FALSE)
```

## Arguments

- year:

  The year of the exam (1998-2024).

- n_max:

  Maximum number of rows to read.

- keep_zip:

  Logical. If `TRUE`, keeps the downloaded ZIP file in cache.

- quiet:

  Logical. If `TRUE`, suppresses progress messages.

## Value

A tibble with item response data.

## See also

Other ENEM functions:
[`enem_summary()`](https://sidneybissoli.github.io/educabR/reference/enem_summary.md),
[`get_enem()`](https://sidneybissoli.github.io/educabR/reference/get_enem.md),
[`get_enem_escola()`](https://sidneybissoli.github.io/educabR/reference/get_enem_escola.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# get item data for 2023
itens <- get_enem_itens(2023)
} # }
```

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
#> ℹ downloading ENEM 2023...
#> ℹ downloading from INEP...
#> Error in value[[3L]](cond): download failed
#> ✖ url: <https://download.inep.gov.br/microdados/microdados_enem_2023.zip>
#> ℹ error: Failed to perform HTTP request. Caused by error in
#>   `curl::curl_fetch_memory()`: ! Timeout was reached [download.inep.gov.br]:
#>   Operation timed out after 600000 milliseconds with 455272254 out of 520568121
#>   bytes received
# }
```

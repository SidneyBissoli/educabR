# Summary statistics for ENEM scores

Calculates summary statistics for ENEM scores, optionally grouped by
demographic variables.

## Usage

``` r
enem_summary(data, by = NULL)
```

## Arguments

- data:

  A tibble with ENEM data (from
  [`get_enem()`](https://sidneybissoli.github.io/educabR/reference/get_enem.md)).

- by:

  Optional grouping variable(s) as character vector.

## Value

A tibble with summary statistics for each score area.

## Examples

``` r
# \donttest{
enem <- get_enem(2023, n_max = 10000)
#> ℹ downloading ENEM 2023...
#> ! ENEM files are large (1-3 GB). this may take a while...
#> ℹ downloading from INEP...
#> Error in value[[3L]](cond): download failed
#> ✖ url: <https://download.inep.gov.br/microdados/microdados_enem_2023.zip>
#> ℹ error: Failed to perform HTTP request. Caused by error in
#>   `curl::curl_fetch_memory()`: ! Timeout was reached [download.inep.gov.br]:
#>   Operation timed out after 600000 milliseconds with 452982509 out of 520568121
#>   bytes received

# overall summary
enem_summary(enem)
#> Error: object 'enem' not found

# summary by sex
enem_summary(enem, by = "tp_sexo")
#> Error: object 'enem' not found
# }
```

# Get IDEB historical series

Downloads and combines IDEB data across multiple years to create a
historical series.

## Usage

``` r
get_ideb_series(
  years = NULL,
  level = c("escola", "municipio"),
  stage = c("anos_iniciais", "anos_finais", "ensino_medio"),
  uf = NULL,
  quiet = FALSE
)
```

## Arguments

- years:

  Vector of years to include (default: all available).

- level:

  The aggregation level.

- stage:

  The education stage.

- uf:

  Optional. Filter by state.

- quiet:

  Logical. If `TRUE`, suppresses progress messages.

## Value

A tibble with IDEB data for all requested years.

## Examples

``` r
if (FALSE) { # \dontrun{
# get IDEB history for municipalities
ideb_hist <- get_ideb_series(
  years = c(2017, 2019, 2021),
  level = "municipio",
  stage = "anos_iniciais"
)
} # }
```

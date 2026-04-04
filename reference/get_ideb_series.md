# Get IDEB historical series

**\[deprecated\]**

`get_ideb_series()` is deprecated because the new
[`get_ideb()`](https://sidneybissoli.github.io/educabR/reference/get_ideb.md)
already returns data in long format with all historical editions. Use
`get_ideb(level, stage, metric)` instead.

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

A tibble with IDEB data.

## See also

Other IDEB functions:
[`get_ideb()`](https://sidneybissoli.github.io/educabR/reference/get_ideb.md),
[`list_ideb_available()`](https://sidneybissoli.github.io/educabR/reference/list_ideb_available.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# deprecated: use get_ideb() instead
ideb <- get_ideb("municipio", "anos_iniciais", "indicador")
} # }
```

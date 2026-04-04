# List available IDEB data

Lists the IDEB data combinations available for download.

## Usage

``` r
list_ideb_available()
```

## Value

A tibble with available IDEB datasets (level, stage, metric).

## See also

Other IDEB functions:
[`get_ideb()`](https://sidneybissoli.github.io/educabR/reference/get_ideb.md),
[`get_ideb_series()`](https://sidneybissoli.github.io/educabR/reference/get_ideb_series.md)

## Examples

``` r
list_ideb_available()
#> # A tibble: 60 × 3
#>    level  stage         metric   
#>    <chr>  <chr>         <chr>    
#>  1 brasil anos_finais   aprovacao
#>  2 brasil anos_finais   indicador
#>  3 brasil anos_finais   meta     
#>  4 brasil anos_finais   nota     
#>  5 brasil anos_iniciais aprovacao
#>  6 brasil anos_iniciais indicador
#>  7 brasil anos_iniciais meta     
#>  8 brasil anos_iniciais nota     
#>  9 brasil ensino_medio  aprovacao
#> 10 brasil ensino_medio  indicador
#> # ℹ 50 more rows
```

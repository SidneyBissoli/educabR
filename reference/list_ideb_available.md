# List available IDEB data

Lists the IDEB data files available in the INEP portal.

## Usage

``` r
list_ideb_available()
```

## Value

A tibble with available IDEB datasets.

## Examples

``` r
list_ideb_available()
#> # A tibble: 24 × 3
#>     year level     stage        
#>    <int> <chr>     <chr>        
#>  1  2017 escola    anos_finais  
#>  2  2017 escola    anos_iniciais
#>  3  2017 escola    ensino_medio 
#>  4  2017 municipio anos_finais  
#>  5  2017 municipio anos_iniciais
#>  6  2017 municipio ensino_medio 
#>  7  2019 escola    anos_finais  
#>  8  2019 escola    anos_iniciais
#>  9  2019 escola    ensino_medio 
#> 10  2019 municipio anos_finais  
#> # ℹ 14 more rows
```

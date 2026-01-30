# List available Censo Escolar files

Lists the data files available in a downloaded School Census.

## Usage

``` r
list_censo_files(year)
```

## Arguments

- year:

  The year of the census.

## Value

A character vector of file names found.

## Examples

``` r
# \donttest{
list_censo_files(2023)
#> [1] "microdados_ed_basica_2023.csv"       "suplemento_cursos_tecnicos_2023.csv"
# }
```

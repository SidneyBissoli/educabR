# List available Censo Escolar files

Lists the data files available in a downloaded School Census. Use this
to discover which files are available for a given year, then pass the
desired file name to
[`get_censo_escolar()`](https://sidneybissoli.github.io/educabR/reference/get_censo_escolar.md)'s
`file` parameter.

## Usage

``` r
list_censo_files(year)
```

## Arguments

- year:

  The year of the census.

## Value

A character vector of file names found.

## See also

Other School Census functions:
[`get_censo_escolar()`](https://sidneybissoli.github.io/educabR/reference/get_censo_escolar.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# first download the data
get_censo_escolar(1995)

# then see what files are available
list_censo_files(1995)
# [1] "CENSOESC_1995.CSV" "DADOS_DESP_1995.CSV" "DADOSCURSO_1995.CSV"

# load a specific file
cursos <- get_censo_escolar(1995, file = "DADOSCURSO")
} # }
```

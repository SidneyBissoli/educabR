# List cached files

Lists all files currently in the educabR cache.

## Usage

``` r
list_cache(dataset = NULL)
```

## Arguments

- dataset:

  Optional. Filter by dataset name.

## Value

A tibble with information about cached files.

## Examples

``` r
# \donttest{
list_cache()
#> # A tibble: 99 × 3
#>    file                                              size_mb modified           
#>    <chr>                                               <dbl> <dttm>             
#>  1 "dicion\xa0rio_dados_educa\x87\xc6o_b\xa0sica.xl…    0.12 2026-01-30 13:29:24
#>  2 "Aluno.pdf"                                          0.07 2026-01-30 13:29:24
#>  3 "Escola.pdf"                                         0.1  2026-01-30 13:29:24
#>  4 "Gestor Escolar.pdf"                                 0.06 2026-01-30 13:29:24
#>  5 "Profissional Escolar.pdf"                           0.07 2026-01-30 13:29:24
#>  6 "Turma.pdf"                                          0.08 2026-01-30 13:29:24
#>  7 "md5_microdados_ed_basica_2023.txt"                  0    2026-01-30 13:29:24
#>  8 "microdados_ed_basica_2023.csv"                    200.   2026-01-30 13:29:25
#>  9 "suplemento_cursos_tecnicos_2023.csv"                3.83 2026-01-30 13:29:25
#> 10 "Leia-me.pdf"                                        0.18 2026-01-30 13:29:25
#> # ℹ 89 more rows
# }
```

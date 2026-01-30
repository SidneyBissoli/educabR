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
#> # A tibble: 15 × 3
#>    file                                              size_mb modified           
#>    <chr>                                               <dbl> <dttm>             
#>  1 "dicion\xa0rio_dados_educa\x87\xc6o_b\xa0sica.xl…    0.12 2026-01-30 12:48:06
#>  2 "Aluno.pdf"                                          0.07 2026-01-30 12:48:06
#>  3 "Escola.pdf"                                         0.1  2026-01-30 12:48:06
#>  4 "Gestor Escolar.pdf"                                 0.06 2026-01-30 12:48:06
#>  5 "Profissional Escolar.pdf"                           0.07 2026-01-30 12:48:06
#>  6 "Turma.pdf"                                          0.08 2026-01-30 12:48:06
#>  7 "md5_microdados_ed_basica_2023.txt"                  0    2026-01-30 12:48:06
#>  8 "microdados_ed_basica_2023.csv"                    200.   2026-01-30 12:48:07
#>  9 "suplemento_cursos_tecnicos_2023.csv"                3.83 2026-01-30 12:48:07
#> 10 "Leia-me.pdf"                                        0.18 2026-01-30 12:48:07
#> 11 "microdados_censo_escolar_2023.zip"                 30.6  2026-01-30 12:48:06
#> 12 "divulgacao_anos_iniciais_escolas_2021.xlsx"         7.23 2026-01-30 13:18:33
#> 13 "divulgacao_anos_iniciais_municipios_2019.xlsx"      8.94 2026-01-30 13:18:54
#> 14 "divulgacao_anos_iniciais_municipios_2021.xlsx"      1.28 2026-01-30 13:18:36
#> 15 "divulgacao_ensino_medio_municipios_2023.xlsx"       3.21 2026-01-30 13:18:41
# }
```

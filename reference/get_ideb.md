# Get IDEB (Índice de Desenvolvimento da Educação Básica) data

Downloads and processes IDEB data from INEP. IDEB is the main indicator
of education quality in Brazil, combining student performance (from
SAEB) with grade promotion rates.

## Usage

``` r
get_ideb(
  year,
  level = c("escola", "municipio"),
  stage = c("anos_iniciais", "anos_finais", "ensino_medio"),
  uf = NULL,
  quiet = FALSE
)
```

## Arguments

- year:

  The year of the IDEB (available: 2017, 2019, 2021, 2023).

- level:

  The aggregation level:

  - `"escola"`: School level

  - `"municipio"`: Municipality level

- stage:

  The education stage:

  - `"anos_iniciais"`: Early elementary (1st-5th grade)

  - `"anos_finais"`: Late elementary (6th-9th grade)

  - `"ensino_medio"`: High school

- uf:

  Optional. Filter by state (UF code or abbreviation).

- quiet:

  Logical. If `TRUE`, suppresses progress messages.

## Value

A tibble with IDEB data in tidy format.

## Details

IDEB is calculated every two years since 2005 based on:

- **Learning**: Average scores in Portuguese and Mathematics from SAEB

- **Flow**: Grade promotion rate (inverse of repetition/dropout)

The index ranges from 0 to 10. Brazil's national goal is to reach 6.0 by
2022 (the level of developed countries in PISA).

**Note:** IDEB data is relatively small compared to other INEP datasets,
so no `n_max` parameter is provided.

## Data source

Official IDEB portal:
<https://www.gov.br/inep/pt-br/areas-de-atuacao/pesquisas-estatisticas-e-indicadores/ideb>

## Examples

``` r
# \donttest{
# get school-level IDEB for early elementary in 2021
ideb_escolas <- get_ideb(2021, level = "escola", stage = "anos_iniciais")
#> ℹ downloading IDEB 2021 - "anos_iniciais" - "escola"...
#> ℹ downloading from INEP...
#> ✔ downloaded 7.23 MB
#> ℹ reading IDEB data...
#> ✔ loaded 63529 rows and 17 columns

# get municipality-level IDEB for São Paulo state
ideb_sp <- get_ideb(2021, level = "municipio", stage = "anos_iniciais", uf = "SP")
#> ℹ downloading IDEB 2021 - "anos_iniciais" - "municipio"...
#> ℹ downloading from INEP...
#> ✔ downloaded 1.28 MB
#> ℹ reading IDEB data...
#> ✔ loaded 1536 rows and 15 columns

# get high school IDEB for all municipalities
ideb_em <- get_ideb(2023, level = "municipio", stage = "ensino_medio")
#> ℹ downloading IDEB 2023 - "ensino_medio" - "municipio"...
#> ℹ downloading from INEP...
#> ✔ downloaded 3.21 MB
#> ℹ reading IDEB data...
#> ✔ loaded 11735 rows and 46 columns
# }
```

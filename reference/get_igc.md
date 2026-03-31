# Get IGC (Indice Geral de Cursos) data

Downloads and processes IGC data from INEP. The IGC is a quality
indicator for higher education institutions in Brazil, calculated as a
weighted average of CPC scores across all evaluated courses plus CAPES
scores for graduate programs.

## Usage

``` r
get_igc(year, n_max = Inf, keep_file = TRUE, quiet = FALSE)
```

## Arguments

- year:

  The year of the indicator (2007-2019, 2021-2023). Note: there is no
  2020 edition. Years 2004-2006 used a different indicator ("Conceito
  Enade").

- n_max:

  Maximum number of rows to read. Default is `Inf` (all rows).

- keep_file:

  Logical. If `TRUE`, keeps the downloaded file in cache. Default is
  `TRUE`.

- quiet:

  Logical. If `TRUE`, suppresses progress messages.

## Value

A tibble with IGC data in tidy format.

## Details

IGC is calculated by INEP as part of the higher education quality
assessment system (SINAES). It provides an overall quality measure for
institutions, considering both undergraduate and graduate programs.

The data includes:

- Institution identifiers (code, name, organization type)

- IGC scores (continuous and categorical/faixa)

- Number of courses and students considered

- Component breakdown (undergraduate CPC average, graduate CAPES scores)

**Important notes:**

- IGC is published annually based on the last three ENADE cycles.

- There is no 2020 edition (COVID-19 suspension).

- Column names are standardized to lowercase with underscores.

- Files are in Excel format (xls/xlsx), except 2007 which is 7z.

## Data dictionary

For detailed information about variables, see INEP's documentation:
<https://www.gov.br/inep/pt-br/areas-de-atuacao/pesquisas-estatisticas-e-indicadores/indicadores-de-qualidade-da-educacao-superior>

## See also

Other CPC/IGC functions:
[`get_cpc()`](https://sidneybissoli.github.io/educabR/reference/get_cpc.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# get IGC data for 2023
igc <- get_igc(2023)

# get IGC data for 2021 with limited rows
igc_2021 <- get_igc(2021, n_max = 1000)
} # }
```

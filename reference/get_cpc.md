# Get CPC (Conceito Preliminar de Curso) data

Downloads and processes CPC data from INEP. The CPC is a quality
indicator for undergraduate courses in Brazil, composed of ENADE scores,
IDD, faculty qualifications, pedagogical resources, and other
institutional factors.

## Usage

``` r
get_cpc(year, n_max = Inf, keep_file = TRUE, quiet = FALSE)
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

A tibble with CPC data in tidy format.

## Details

CPC is calculated by INEP as part of the higher education quality
assessment system (SINAES). It serves as a preliminary indicator used to
determine which courses require on-site evaluation.

The data includes:

- Course and institution identifiers

- CPC scores (continuous and categorical/faixa)

- Component scores (ENADE, IDD, faculty, infrastructure, etc.)

- Number of students evaluated

**Important notes:**

- CPC follows ENADE's rotating cycle of course areas, so each year
  covers a specific set of fields.

- There is no 2020 edition (COVID-19 suspension).

- Column names are standardized to lowercase with underscores.

- Files are in Excel format (xls/xlsx), not CSV.

## Data dictionary

For detailed information about variables, see INEP's documentation:
<https://www.gov.br/inep/pt-br/areas-de-atuacao/pesquisas-estatisticas-e-indicadores/indicadores-de-qualidade-da-educacao-superior>

## See also

Other CPC/IGC functions:
[`get_igc()`](https://sidneybissoli.github.io/educabR/reference/get_igc.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# get CPC data for 2023
cpc <- get_cpc(2023)

# get CPC data for 2021 with limited rows
cpc_2021 <- get_cpc(2021, n_max = 1000)
} # }
```

# Get IDD (Indicador de Diferença entre os Desempenhos Observado e Esperado) data

Downloads and processes microdata from IDD, an indicator that measures
the value added by an undergraduate course to student performance. It
compares ENADE scores with expected performance based on students' prior
achievement (ENEM scores at admission).

## Usage

``` r
get_idd(year, n_max = Inf, keep_zip = TRUE, quiet = FALSE)
```

## Arguments

- year:

  The year of the indicator (2014-2019, 2021-2023). Note: there is no
  2020 edition.

- n_max:

  Maximum number of rows to read. Default is `Inf` (all rows).

- keep_zip:

  Logical. If `TRUE`, keeps the downloaded ZIP file in cache.

- quiet:

  Logical. If `TRUE`, suppresses progress messages.

## Value

A tibble with IDD data in tidy format.

## Details

IDD is calculated by INEP as part of the higher education quality
assessment system. It complements ENADE by isolating the contribution of
the course itself to student learning, controlling for student input
quality.

The data includes:

- Course and institution identifiers

- IDD scores (continuous and categorical)

- Number of students considered in the calculation

- Related ENADE and ENEM metrics

**Important notes:**

- IDD is published alongside ENADE results, following the same rotating
  cycle of course areas.

- Column names are standardized to lowercase with underscores.

- Not all courses have IDD values (minimum sample requirements apply).

## Data dictionary

For detailed information about variables, see INEP's documentation:
<https://www.gov.br/inep/pt-br/acesso-a-informacao/dados-abertos/microdados/idd>

## Examples

``` r
if (FALSE) { # \dontrun{
# get IDD data for 2023
idd <- get_idd(2023)

# get IDD data for 2021 with limited rows
idd_2021 <- get_idd(2021, n_max = 1000)
} # }
```

# Get Conceito Enade data

Downloads and processes the Conceito Enade spreadsheets published by
INEP. The Conceito Enade is the course-level quality indicator derived
from the performance of graduating students in ENADE, on a continuous
scale and in five levels (faixas 1 to 5).

Unlike
[`get_enade()`](https://sidneybissoli.github.io/educabR/reference/get_enade.md),
which returns student-level microdata, this function returns one row per
course (or per course unit, before 2015) with the official indicator.

## Usage

``` r
get_conceito_enade(
  year,
  type = NULL,
  n_max = Inf,
  keep_file = TRUE,
  quiet = FALSE
)
```

## Arguments

- year:

  The year of the indicator (2004-2019, 2021-2023, 2025). There is no
  2020 edition (ENADE was not held) and no 2024 edition.

- type:

  Only for 2025, which INEP publishes as two files with their own
  methodology: `"licenciaturas"` (Enade das Licenciaturas) or
  `"medicina"` (Enade Medicina). Must be `NULL` for other years.

- n_max:

  Maximum number of rows to read. Default is `Inf` (all rows).

- keep_file:

  Logical. If `TRUE`, keeps the downloaded file in cache. Default is
  `TRUE`.

- quiet:

  Logical. If `TRUE`, suppresses progress messages.

## Value

A tibble with Conceito Enade data in tidy format.

## Details

**Unit of observation.** Up to 2014 a row is a "course unit": all
courses of the same institution, municipality and evaluation area,
identified by the institution, municipality and area codes (the number
of courses grouped is in a column such as
`numero_de_cursos_da_unidade`). From 2015 on, a row is a course,
identified by `codigo_do_curso` (the e-MEC course code).

**Sources by edition.**

- 2004-2006 and 2012-2023: INEP's Conceito Enade spreadsheet.

- 2007-2011: INEP publishes the Conceito Enade inside the combined
  Enade/CPC table, so this function returns that table (the same one as
  [`get_cpc()`](https://sidneybissoli.github.io/educabR/reference/get_cpc.md)).
  The Conceito Enade is in `conceito_enade` (2007, 2008) or
  `conceito_enade_faixa` (2009-2011).

- 2025: see `type`. These files report the share of graduates at or
  above a proficiency standard and the faixa, with no continuous score.

**Important notes:**

- Column names change across editions and are standardized to lowercase
  with underscores, not harmonized: map them to a common set before
  stacking years.

- Faixa and continuous columns are numeric; "SC" (sem conceito) and
  similar markers become `NA`.

- Files are in Excel format (xls/xlsx).

## Data dictionary

For detailed information about variables, see INEP's documentation:
<https://www.gov.br/inep/pt-br/areas-de-atuacao/pesquisas-estatisticas-e-indicadores/indicadores-de-qualidade-da-educacao-superior>

## See also

Other CPC/IGC functions:
[`get_cpc()`](https://sidneybissoli.github.io/educabR/reference/get_cpc.md),
[`get_igc()`](https://sidneybissoli.github.io/educabR/reference/get_igc.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Conceito Enade 2023
ce <- get_conceito_enade(2023)

# 2025 comes in two files
ce_lic <- get_conceito_enade(2025, type = "licenciaturas")

# a series: one call per year, then harmonize column names
series <- purrr::map(c(2017, 2018, 2019), get_conceito_enade)
} # }
```

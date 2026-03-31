# Get ENADE (Exame Nacional de Desempenho dos Estudantes) data

Downloads and processes microdata from ENADE, the Brazilian National
Student Performance Exam. ENADE evaluates the performance of
undergraduate students in higher education.

## Usage

``` r
get_enade(year, n_max = Inf, keep_zip = TRUE, quiet = FALSE)
```

## Arguments

- year:

  The year of the exam (2004-2024).

- n_max:

  Maximum number of rows to read. Default is `Inf` (all rows). Consider
  using a smaller value for exploration.

- keep_zip:

  Logical. If `TRUE`, keeps the downloaded ZIP file in cache.

- quiet:

  Logical. If `TRUE`, suppresses progress messages.

## Value

A tibble with ENADE microdata in tidy format.

## Details

ENADE is conducted annually by INEP and evaluates undergraduate students
nearing the end of their programs. Each year, a different set of course
areas is assessed on a rotating cycle (typically every 3 years per
area).

The microdata includes:

- Student performance scores (general and specific knowledge)

- Socioeconomic questionnaire responses

- Course and institution identifiers

**Important notes:**

- ENADE files can be large (several hundred MB for recent years).

- Use `n_max` to read a sample first for exploration.

- Column names are standardized to lowercase with underscores.

- Not all course areas are assessed every year due to the rotating
  cycle.

## Data dictionary

For detailed information about variables, see INEP's documentation:
<https://www.gov.br/inep/pt-br/acesso-a-informacao/dados-abertos/microdados/enade>

## Examples

``` r
if (FALSE) { # \dontrun{
# get ENADE data for 2023
enade <- get_enade(2023, n_max = 10000)

# get full dataset for 2021
enade_2021 <- get_enade(2021)
} # }
```

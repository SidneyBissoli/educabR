# Get ENEM (Exame Nacional do Ensino Médio) data

Downloads and processes microdata from ENEM, the Brazilian National High
School Exam. ENEM is used for university admissions and as a high school
equivalency exam.

## Usage

``` r
get_enem(
  year,
  type = "participantes",
  n_max = Inf,
  keep_zip = TRUE,
  quiet = FALSE
)
```

## Arguments

- year:

  The year of the exam (1998-2024).

- type:

  Type of data to load. Only used for ENEM 2024+, where microdata is
  split into separate files. Options: `"participantes"` (demographics
  and socioeconomic data, default), `"resultados"` (scores). Ignored for
  years before 2024 (single file with all data).

- n_max:

  Maximum number of rows to read. Default is `Inf` (all rows). Consider
  using a smaller value for exploration, as ENEM files contain millions
  of rows.

- keep_zip:

  Logical. If `TRUE`, keeps the downloaded ZIP file in cache.

- quiet:

  Logical. If `TRUE`, suppresses progress messages.

## Value

A tibble with the ENEM microdata in tidy format.

## Details

ENEM is conducted annually by INEP and is the largest exam in Brazil,
with millions of participants. The microdata includes:

- Participant demographics (age, sex, race, etc.)

- Socioeconomic questionnaire responses

- Scores for each test area

- Essay scores

- School information (when applicable)

**Important notes:**

- ENEM files are very large (several GB when extracted).

- Use `n_max` to read a sample first for exploration.

- Column names are standardized to lowercase with underscores.

- Score variables start with `nu_nota_` prefix.

- From 2024 onwards, INEP split the microdata into separate files. Use
  the `type` parameter to choose which file to load.

## Data dictionary

For detailed information about variables, see INEP's documentation:
<https://www.gov.br/inep/pt-br/acesso-a-informacao/dados-abertos/microdados/enem>

## See also

Other ENEM functions:
[`enem_summary()`](https://sidneybissoli.github.io/educabR/reference/enem_summary.md),
[`get_enem_itens()`](https://sidneybissoli.github.io/educabR/reference/get_enem_itens.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# get a sample of 10000 rows for exploration
enem_sample <- get_enem(2023, n_max = 10000)

# get full data (warning: large file)
enem_2023 <- get_enem(2023)

# ENEM 2024+: choose data type
participantes <- get_enem(2024, type = "participantes", n_max = 1000)
resultados <- get_enem(2024, type = "resultados", n_max = 1000)
} # }
```

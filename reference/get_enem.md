# Get ENEM (Exame Nacional do Ensino Médio) data

Downloads and processes microdata from ENEM, the Brazilian National High
School Exam. ENEM is used for university admissions and as a high school
equivalency exam.

## Usage

``` r
get_enem(year, n_max = Inf, keep_zip = TRUE, quiet = FALSE)
```

## Arguments

- year:

  The year of the exam (2009-2023).

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

## Data dictionary

For detailed information about variables, see INEP's documentation:
<https://www.gov.br/inep/pt-br/acesso-a-informacao/dados-abertos/microdados/enem>

## Examples

``` r
# \donttest{
# get a sample of 10000 rows for exploration
enem_sample <- get_enem(2023, n_max = 10000)
#> ✔ using cached file
#> ℹ reading ENEM data...
#> ℹ reading file with encoding: "UTF-8"
#> ✔ loaded 10000 rows and 76 columns

# get full data (warning: large file)
enem_2023 <- get_enem(2023)
#> ✔ using cached file
#> ℹ reading ENEM data...
#> ! reading full file. use `n_max` to limit rows if needed.
#> ℹ reading file with encoding: "UTF-8"
#> ✔ loaded 3933955 rows and 76 columns
# }
```

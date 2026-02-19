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
#> ℹ downloading ENEM 2023...
#> ! ENEM files are large (1-3 GB). this may take a while...
#> ℹ downloading from INEP...
#> Error in value[[3L]](cond): download failed
#> ✖ url: <https://download.inep.gov.br/microdados/microdados_enem_2023.zip>
#> ℹ error: Failed to perform HTTP request. Caused by error in
#>   `curl::curl_fetch_memory()`: ! Timeout was reached [download.inep.gov.br]:
#>   Operation timed out after 600000 milliseconds with 458649525 out of 520568121
#>   bytes received

# get full data (warning: large file)
enem_2023 <- get_enem(2023)
#> ℹ downloading ENEM 2023...
#> ! ENEM files are large (1-3 GB). this may take a while...
#> ℹ downloading from INEP...
#> Error in value[[3L]](cond): download failed
#> ✖ url: <https://download.inep.gov.br/microdados/microdados_enem_2023.zip>
#> ℹ error: Failed to perform HTTP request. Caused by error in
#>   `curl::curl_fetch_memory()`: ! Timeout was reached [download.inep.gov.br]:
#>   Operation timed out after 600001 milliseconds with 455680670 out of 520568121
#>   bytes received
# }
```

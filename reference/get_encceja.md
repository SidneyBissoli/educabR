# Get ENCCEJA (Exame Nacional para Certificação de Competências de Jovens e Adultos) data

Downloads and processes microdata from ENCCEJA, the Brazilian National
Exam for Youth and Adult Education Certification. ENCCEJA assesses
competencies of young people and adults who did not complete basic
education at the regular age.

## Usage

``` r
get_encceja(
  year,
  type = c("regular", "ppl"),
  n_max = Inf,
  keep_zip = TRUE,
  quiet = FALSE
)
```

## Arguments

- year:

  The year of the exam (2014, 2017-2020, 2022-2025; INEP published no
  microdata for 2015, 2016 and 2021).

- type:

  Which participants to load. INEP ships two microdata files per
  edition:

  - `"regular"`: the national regular exam (`REG_NAC` / `REGULAR` file),
    with almost all participants (default)

  - `"ppl"`: the exam applied to people deprived of liberty (`PPL_NAC` /
    `PPL` file)

- n_max:

  Maximum number of rows to read. Default is `Inf` (all rows). Consider
  using a smaller value for exploration.

- keep_zip:

  Logical. If `TRUE`, keeps the downloaded ZIP file in cache.

- quiet:

  Logical. If `TRUE`, suppresses progress messages.

## Value

A tibble with ENCCEJA microdata in tidy format.

## Details

ENCCEJA is conducted by INEP and provides certification for elementary
and high school equivalency for youth and adults (EJA). The exam covers
four knowledge areas:

- Natural Sciences (Ciências Naturais)

- Mathematics (Matemática)

- Portuguese Language (Língua Portuguesa)

- Social Sciences (Ciências Humanas)

**Important notes:**

- ENCCEJA files can be large (several hundred MB).

- Use `n_max` to read a sample first for exploration.

- Column names are standardized to lowercase with underscores.

## Data dictionary

For detailed information about variables, see INEP's documentation:
<https://www.gov.br/inep/pt-br/acesso-a-informacao/dados-abertos/microdados/encceja>

## Examples

``` r
if (FALSE) { # \dontrun{
# get ENCCEJA data for 2023
encceja <- get_encceja(2023, n_max = 10000)

# get full dataset for 2022
encceja_2022 <- get_encceja(2022)

# participants deprived of liberty (PPL)
encceja_ppl <- get_encceja(2023, type = "ppl")
} # }
```

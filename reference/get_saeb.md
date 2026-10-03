# Get SAEB (Sistema de Avaliação da Educação Básica) data

Downloads and processes microdata from SAEB, the Brazilian Basic
Education Assessment System. SAEB evaluates educational quality through
student performance assessments in Portuguese and Mathematics.

## Usage

``` r
get_saeb(
  year,
  type = c("aluno", "escola", "diretor", "professor"),
  level = c("fundamental_medio", "educacao_infantil"),
  serie = NULL,
  n_max = Inf,
  keep_zip = TRUE,
  quiet = FALSE
)
```

## Arguments

- year:

  The year of the assessment (2011, 2013, 2015, 2017, 2019, 2021, 2023).

- type:

  Type of data to load. Options:

  - `"aluno"`: Student results (default)

  - `"escola"`: School questionnaire

  - `"diretor"`: Principal questionnaire

  - `"professor"`: Teacher questionnaire

- level:

  For 2021 only, SAEB was split into two files:

  - `"fundamental_medio"`: Elementary and High School (default)

  - `"educacao_infantil"`: Early Childhood Education Ignored for other
    years.

- serie:

  For `type = "aluno"`, the grade to load. Since 2013 INEP publishes one
  student file per grade (`TS_ALUNO_<serie>.csv`), so `get_saeb()` reads
  one grade per call. Use INEP's codes, in any case:

  - `"2ef"`: 2nd grade of elementary school (2019, 2021, 2023)

  - `"5ef"`: 5th grade of elementary school (2013-2023)

  - `"9ef"`: 9th grade of elementary school (2013-2023)

  - `"3em"`: 3rd grade of high school (2013, 2015)

  - `"3em_ag"`, `"3em_esc"`: 3rd grade of high school, aggregated and
    school samples (2017)

  - `"34em"`: 3rd and 4th grades of high school (2019, 2021, 2023)

  The numbers `2`, `5` and `9` are accepted as shortcuts for `"2ef"`,
  `"5ef"` and `"9ef"`. Required when the edition has more than one
  student file; the error message lists the grades available for the
  year. Ignored for 2011 (a single results file covers all grades) and
  for the 2021 early childhood file.

- n_max:

  Maximum number of rows to read. Default is `Inf` (all rows). Consider
  using a smaller value for exploration.

- keep_zip:

  Logical. If `TRUE`, keeps the downloaded ZIP file in cache.

- quiet:

  Logical. If `TRUE`, suppresses progress messages.

## Value

A tibble with SAEB microdata in tidy format.

## Details

SAEB is conducted biennially by INEP and assesses students in grades 5
and 9 of elementary school, and grade 3 of high school. The data
includes:

- Student performance scores in Portuguese and Mathematics

- School infrastructure and management questionnaires

- Teacher and principal profiles

**Important notes:**

- SAEB files can be large (several hundred MB).

- Use `n_max` to read a sample first for exploration.

- Column names are standardized to lowercase with underscores.

- In 2021, INEP split SAEB into two separate downloads (elementary/high
  school and early childhood). Use the `level` parameter to choose.

- Student files are split by grade from 2013 on; choose one with
  `serie`. The 5th and 9th grade files are about 1 GB of CSV each. To
  combine grades, call once per grade, e.g.
  `purrr::map(c("5ef", "9ef"), function(s) get_saeb(2023, serie = s))`.

- For 2011, `type = "aluno"` reads `TS_RESULTADO_ALUNO` (proficiency
  results), which covers all grades in one file.

## Data dictionary

For detailed information about variables, see INEP's documentation:
<https://www.gov.br/inep/pt-br/acesso-a-informacao/dados-abertos/microdados/saeb>

## Examples

``` r
if (FALSE) { # \dontrun{
# get 5th grade student results for 2023
saeb_5ef <- get_saeb(2023, serie = "5ef", n_max = 10000)

# 5th and 9th grades, one call per grade
saeb_ef <- purrr::map(c("5ef", "9ef"), function(s) get_saeb(2023, serie = s))

# get school questionnaire data
saeb_escola <- get_saeb(2023, type = "escola")

# SAEB 2021: early childhood education
saeb_infantil <- get_saeb(2021, level = "educacao_infantil", n_max = 1000)
} # }
```

# Get Higher Education Census (Censo da Educação Superior) data

Downloads and processes microdata from the Brazilian Higher Education
Census (Censo da Educação Superior), conducted annually by INEP. Returns
data on institutions, courses, students, or faculty.

## Usage

``` r
get_censo_superior(
  year,
  type = c("ies", "cursos", "alunos", "docentes"),
  uf = NULL,
  n_max = Inf,
  keep_zip = TRUE,
  quiet = FALSE
)
```

## Arguments

- year:

  The year of the census (2009-2024).

- type:

  Type of data to load. Options:

  - `"ies"`: Higher education institutions (default)

  - `"cursos"`: Undergraduate courses

  - `"alunos"`: Student enrollment

  - `"docentes"`: Faculty/professors

- uf:

  Optional. Filter by state (UF code or abbreviation).

- n_max:

  Maximum number of rows to read. Default is `Inf` (all rows). Consider
  using a smaller value for exploration.

- keep_zip:

  Logical. If `TRUE`, keeps the downloaded ZIP file in cache.

- quiet:

  Logical. If `TRUE`, suppresses progress messages.

## Value

A tibble with Higher Education Census microdata in tidy format.

## Details

The Higher Education Census is the most comprehensive statistical survey
on higher education institutions (HEIs) in Brazil. It collects data from
all HEIs offering undergraduate and graduate programs.

**Data types:**

- `"ies"`: One row per institution — administrative data, location,
  academic organization, funding type.

- `"cursos"`: One row per undergraduate course — area of study, modality
  (in-person/distance), enrollment counts.

- `"alunos"`: One row per student enrollment — demographics, program,
  admission type, enrollment status.

- `"docentes"`: One row per faculty member — education level, employment
  type, teaching regime.

**Important notes:**

- Student files (`"alunos"`) can be very large (several GB). Use `n_max`
  to read a sample first.

- Column names are standardized to lowercase with underscores.

- Use the `uf` parameter to filter by state for faster processing.

## Data dictionary

For detailed information about variables, see INEP's documentation:
<https://www.gov.br/inep/pt-br/acesso-a-informacao/dados-abertos/microdados/censo-da-educacao-superior>

## See also

Other Higher Education Census functions:
[`list_censo_superior_files()`](https://sidneybissoli.github.io/educabR/reference/list_censo_superior_files.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# get institution data for 2023
ies <- get_censo_superior(2023)

# get course data for Sao Paulo
cursos_sp <- get_censo_superior(2023, type = "cursos", uf = "SP")

# get a sample of student data
alunos <- get_censo_superior(2023, type = "alunos", n_max = 10000)

# get faculty data
docentes <- get_censo_superior(2023, type = "docentes")
} # }
```

# Get FUNDEB enrollment data

Downloads and processes FUNDEB enrollment data from FNDE's OData API.
These are the enrollment counts considered for FUNDEB funding
calculation.

## Usage

``` r
get_fundeb_enrollment(
  year,
  uf = NULL,
  n_max = Inf,
  keep_file = TRUE,
  quiet = FALSE
)
```

## Arguments

- year:

  The year of the data (2007-2026).

- uf:

  Optional. A UF code (e.g., `"SP"`, `"RJ"`) to filter by state. The
  filter is applied at the API level for efficiency. Default is `NULL`
  (all states).

- n_max:

  Maximum number of rows to read. Default is `Inf` (all rows).

- keep_file:

  Logical. If `TRUE`, caches the API result as a local CSV file. Default
  is `TRUE`.

- quiet:

  Logical. If `TRUE`, suppresses progress messages.

## Value

A tibble with columns:

- ano_censo:

  Census year

- uf:

  State code (UF)

- municipio:

  Municipality name

- tipo_rede_educacao:

  Education network type

- descricao_tipo_educacao:

  Education type description

- descricao_tipo_ensino:

  Teaching type description

- descricao_tipo_turma:

  Class type description

- descricao_tipo_carga_horaria:

  Class hours type description

- descricao_tipo_localizacao:

  Location type description

- qtd_matricula:

  Number of enrollments

## Details

Enrollment data comes from FNDE (Fundo Nacional de Desenvolvimento da
Educacao) via its OData API. It includes the number of enrollments
considered for FUNDEB funding, broken down by state, municipality,
education type, school network, class type, and location.

**Important notes:**

- Data is sourced from FNDE, not INEP.

- Requires the `jsonlite` package.

- Results are cached locally as CSV after first download.

- Column names are standardized to lowercase with underscores.

- When `uf` is used with a cached file, filtering is done locally.

## Data source

FNDE: `https://www.fnde.gov.br`

## See also

Other FUNDEB functions:
[`get_fundeb_distribution()`](https://sidneybissoli.github.io/educabR/reference/get_fundeb_distribution.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# get FUNDEB enrollment data for 2023
mat_2023 <- get_fundeb_enrollment(2023)

# get enrollment data for Sao Paulo only
mat_sp <- get_fundeb_enrollment(2023, uf = "SP")

# get enrollment data with limited rows
mat_sample <- get_fundeb_enrollment(2023, n_max = 1000)
} # }
```

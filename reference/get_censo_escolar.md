# Get School Census (Censo Escolar) data

Downloads and processes microdata from the Brazilian School Census
(Censo Escolar), conducted annually by INEP. Returns school-level data
with information about infrastructure, location, and administrative
details.

## Usage

``` r
get_censo_escolar(
  year,
  file = NULL,
  uf = NULL,
  n_max = Inf,
  keep_zip = TRUE,
  quiet = FALSE
)
```

## Arguments

- year:

  The year of the census (1995-2025).

- file:

  Optional. Name (or partial name) of a specific CSV file to load. By
  default, loads the main school data file. Use
  [`list_censo_files()`](https://sidneybissoli.github.io/educabR/reference/list_censo_files.md)
  to see available files for a given year. Older years (1995-2006)
  include multiple files (e.g. `"EDUCPROF"`, `"DADOSCURSO"`).

- uf:

  Optional. Filter by state (UF code or abbreviation).

- n_max:

  Maximum number of rows to read. Default is `Inf` (all rows).

- keep_zip:

  Logical. If `TRUE`, keeps the downloaded ZIP file in cache.

- quiet:

  Logical. If `TRUE`, suppresses progress messages.

## Value

A tibble with school data in tidy format.

## Details

The School Census is the main statistical survey on basic education in
Brazil. It collects data from all public and private schools offering
basic education (early childhood, elementary, and high school).

**Important notes:**

- The microdata contains one row per school (~217,000 schools in 2023).

- Column names are standardized to lowercase with underscores.

- Use the `uf` parameter to filter by state for faster processing.

- Older years (1995-2006) contain multiple CSV files with different
  data. Use
  [`list_censo_files()`](https://sidneybissoli.github.io/educabR/reference/list_censo_files.md)
  to discover available files, then pass the desired file name to the
  `file` parameter.

## Data dictionary

For detailed information about variables, see INEP's documentation:
<https://www.gov.br/inep/pt-br/acesso-a-informacao/dados-abertos/microdados/censo-escolar>

## See also

Other School Census functions:
[`list_censo_files()`](https://sidneybissoli.github.io/educabR/reference/list_censo_files.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# get schools data for 2023
escolas <- get_censo_escolar(2023)

# get schools from Sao Paulo state only
escolas_sp <- get_censo_escolar(2023, uf = "SP")

# read only first 1000 rows for exploration
escolas_sample <- get_censo_escolar(2023, n_max = 1000)

# list available files for an older year
list_censo_files(1995)
# [1] "CENSOESC_1995.CSV" "DADOS_DESP_1995.CSV" "DADOSCURSO_1995.CSV"

# load a specific file from an older year
cursos <- get_censo_escolar(1995, file = "DADOSCURSO")
} # }
```

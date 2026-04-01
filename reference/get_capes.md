# Get CAPES graduate education data

Downloads and processes data from CAPES (Coordenacao de Aperfeicoamento
de Pessoal de Nivel Superior) on Brazilian graduate programs (stricto
sensu). Data is retrieved from the CAPES Open Data Portal via the CKAN
API.

## Usage

``` r
get_capes(
  year,
  type = c("programas", "discentes", "docentes", "cursos", "catalogo"),
  n_max = Inf,
  keep_file = TRUE,
  quiet = FALSE
)
```

## Arguments

- year:

  The year of the data (2013-2024).

- type:

  The type of data to download. One of:

  - `"programas"`: Graduate programs

  - `"discentes"`: Students

  - `"docentes"`: Faculty

  - `"cursos"`: Courses

  - `"catalogo"`: Theses and dissertations catalog

- n_max:

  Maximum number of rows to read. Default is `Inf` (all rows).

- keep_file:

  Logical. If `TRUE`, keeps the downloaded file in cache. Default is
  `TRUE`.

- quiet:

  Logical. If `TRUE`, suppresses progress messages.

## Value

A tibble with CAPES data in tidy format.

## Details

CAPES is the federal agency responsible for evaluating and regulating
graduate programs in Brazil. The data covers stricto sensu programs
(master's and doctoral).

The data types include:

- **programas**: Program identifiers, area, evaluation scores

- **discentes**: Student enrollment, demographics, scholarship status

- **docentes**: Faculty information, qualifications, employment

- **cursos**: Course details, modality, start dates

- **catalogo**: Catalog of theses and dissertations

**Important notes:**

- Data is sourced from the CAPES Open Data Portal (CKAN), not INEP.

- Files are large CSV files. Downloading may take several minutes.

- Column names are standardized to lowercase with underscores.

- Internet connection is required to discover download URLs via the CKAN
  API before downloading.

## Data source

<https://dadosabertos.capes.gov.br>

## Examples

``` r
if (FALSE) { # \dontrun{
# get graduate programs for 2023
programas <- get_capes(2023, type = "programas")

# get student data for 2022 with limited rows
discentes <- get_capes(2022, type = "discentes", n_max = 1000)
} # }
```

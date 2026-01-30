# Get School Census (Censo Escolar) data

Downloads and processes microdata from the Brazilian School Census
(Censo Escolar), conducted annually by INEP. Returns school-level data
with information about infrastructure, location, and administrative
details.

## Usage

``` r
get_censo_escolar(year, uf = NULL, n_max = Inf, keep_zip = TRUE, quiet = FALSE)
```

## Arguments

- year:

  The year of the census (2007-2024).

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

## Data dictionary

For detailed information about variables, see INEP's documentation:
<https://www.gov.br/inep/pt-br/acesso-a-informacao/dados-abertos/microdados/censo-escolar>

## Examples

``` r
# \donttest{
# get schools data for 2023
escolas <- get_censo_escolar(2023)
#> ℹ downloading Censo Escolar 2023...
#> ℹ downloading from INEP...
#> ✔ downloaded 30.61 MB
#> ℹ extracting files...
#> ✔ extracted 10 file(s)
#> ℹ reading school data...
#> ℹ reading file with encoding: "UTF-8"
#> ✔ loaded 217625 rows and 408 columns

# get schools from Sao Paulo state only
escolas_sp <- get_censo_escolar(2023, uf = "SP")
#> ✔ using cached file
#> ℹ reading school data...
#> ℹ reading file with encoding: "UTF-8"
#> ✔ loaded 34099 rows and 408 columns

# read only first 1000 rows for exploration
escolas_sample <- get_censo_escolar(2023, n_max = 1000)
#> ✔ using cached file
#> ℹ reading school data...
#> ℹ reading file with encoding: "UTF-8"
#> ✔ loaded 1000 rows and 408 columns
# }
```

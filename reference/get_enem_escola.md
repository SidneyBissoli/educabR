# Get ENEM por Escola (ENEM by School) data

Downloads and processes ENEM results aggregated by school. This dataset
contains average ENEM scores, participation rates, and other indicators
for each school in Brazil.

## Usage

``` r
get_enem_escola(n_max = Inf, keep_zip = TRUE, quiet = FALSE)
```

## Arguments

- n_max:

  Maximum number of rows to read. Default is `Inf` (all rows).

- keep_zip:

  Logical. If `TRUE`, keeps the downloaded ZIP file in cache.

- quiet:

  Logical. If `TRUE`, suppresses progress messages.

## Value

A tibble with ENEM by School data in tidy format.

## Details

ENEM por Escola is a single bundled dataset covering years 2005 to 2015.
It was discontinued by INEP after 2015 and no per-year files exist.

The data includes:

- School identification (code, name, municipality, state)

- Average ENEM scores by knowledge area

- Number of participants and participation rates

- School-level indicators

**Important notes:**

- This is a single file covering all years (2005-2015), not per-year.

- Column names are standardized to lowercase with underscores.

- Data was discontinued after 2015.

## Data dictionary

For detailed information about variables, see INEP's documentation:
<https://www.gov.br/inep/pt-br/acesso-a-informacao/dados-abertos/microdados/enem-por-escola>

## See also

Other ENEM functions:
[`enem_summary()`](https://sidneybissoli.github.io/educabR/reference/enem_summary.md),
[`get_enem()`](https://sidneybissoli.github.io/educabR/reference/get_enem.md),
[`get_enem_itens()`](https://sidneybissoli.github.io/educabR/reference/get_enem_itens.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# get all ENEM by School data (2005-2015)
enem_escola <- get_enem_escola()

# read only first 1000 rows for exploration
enem_escola_sample <- get_enem_escola(n_max = 1000)
} # }
```

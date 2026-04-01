# Get FUNDEB distribution data

Downloads and processes FUNDEB resource distribution data from STN
(Secretaria do Tesouro Nacional). Each year's Excel file contains
multiple sheets with monthly transfer data by state/municipality, broken
down by funding source.

## Usage

``` r
get_fundeb_distribution(
  year,
  uf = NULL,
  source = NULL,
  destination = NULL,
  n_max = Inf,
  keep_file = TRUE,
  quiet = FALSE
)
```

## Arguments

- year:

  The year of the data (2007-2026).

- uf:

  Optional. A UF code (e.g., `"SP"`, `"RJ"`) to filter by state. Default
  is `NULL` (all states).

- source:

  Optional. The funding source to filter by. One of: `"FPE"`, `"FPM"`,
  `"IPI"`, `"ITR"`, `"VAAF"`, `"VAAT"`, `"VAAR"`, `"ICMS"`, `"IPVA"`,
  `"ITCMD"`. Default is `NULL` (all sources).

- destination:

  Optional. The transfer destination. One of:

  - `"uf"`: Transfers to states and the Federal District

  - `"municipio"`: Transfers to municipalities

  Default is `NULL` (both).

- n_max:

  Maximum number of rows to return. Default is `Inf` (all rows).

- keep_file:

  Logical. If `TRUE`, keeps the downloaded file in cache. Default is
  `TRUE`.

- quiet:

  Logical. If `TRUE`, suppresses progress messages.

## Value

A tibble in tidy (long) format with columns:

- estados:

  State name

- uf:

  State code (UF)

- mes_ano:

  Date (last day of the month)

- origem:

  Funding source (FPE, FPM, ICMS, etc.)

- destino:

  Transfer destination ("UF" or "Municipio")

- tabela:

  Table type ("Fundeb" or "Ajuste Fundeb")

- valor:

  Transfer amount in BRL (numeric)

## Details

FUNDEB (Fundo de Manutencao e Desenvolvimento da Educacao Basica e de
Valorizacao dos Profissionais da Educacao) is the main funding mechanism
for basic education in Brazil.

Each Excel file from STN contains ~20 data sheets named with a prefix
indicating the destination (`E_` for states, `M_` for municipalities)
and a suffix indicating the funding source (e.g., `E_FPE`, `M_ICMS`).
Each sheet contains two tables: the main FUNDEB transfers and a FUNDEB
adjustment table.

**Important notes:**

- Data is sourced from STN (Tesouro Nacional), not INEP.

- Files are in Excel format (XLS) — requires the `readxl` package.

- Column names are standardized to lowercase with underscores.

- Summary sheets (Resumo, Total, etc.) are automatically excluded.

## Data source

<https://www.tesourotransparente.gov.br>

## See also

Other FUNDEB functions:
[`get_fundeb_enrollment()`](https://sidneybissoli.github.io/educabR/reference/get_fundeb_enrollment.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# get all FUNDEB distribution data for 2023
dist_2023 <- get_fundeb_distribution(2023)

# get only FPE transfers to states
fpe_estados <- get_fundeb_distribution(2023, source = "FPE",
                                        destination = "uf")

# get data for Sao Paulo only
sp <- get_fundeb_distribution(2023, uf = "SP")
} # }
```

# Get IDEB (Índice de Desenvolvimento da Educação Básica) data

Downloads and processes IDEB data from INEP in tidy (long) format. IDEB
is the main indicator of education quality in Brazil, combining student
performance (from SAEB) with grade promotion rates.

## Usage

``` r
get_ideb(level, stage, metric, year = NULL, quiet = FALSE)
```

## Arguments

- level:

  The geographic level. **Required.**

  - `"escola"`: School level

  - `"municipio"`: Municipality level

  - `"estado"`: State level

  - `"regiao"`: Region level (Norte, Nordeste, Sudeste, Sul,
    Centro-Oeste)

  - `"brasil"`: National level

- stage:

  The education stage. **Required.**

  - `"anos_iniciais"`: Early elementary (1st-5th grade)

  - `"anos_finais"`: Late elementary (6th-9th grade)

  - `"ensino_medio"`: High school

- metric:

  The type of data to return. **Required.**

  - `"indicador"`: IDEB components (rendimento, nota padronizada, ideb)

  - `"aprovacao"`: Approval rates by school year

  - `"nota"`: SAEB scores by subject (math/portuguese)

  - `"meta"`: IDEB targets/projections

- year:

  Optional. Integer vector of IDEB editions to filter (e.g.,
  `c(2019, 2021, 2023)`). `NULL` returns all available editions.

- quiet:

  Logical. If `TRUE`, suppresses progress messages.

## Value

A tibble in tidy (long) format. Columns vary by `level` and `metric`:

**ID columns** (vary by `level`):

- `escola`: `uf_sigla`, `municipio_codigo`, `municipio_nome`,
  `escola_id`, `escola_nome`, `rede`

- `municipio`: `uf_sigla`, `municipio_codigo`, `municipio_nome`, `rede`

- `brasil`: `rede`

- `estado`: `uf_nome`, `uf_sigla`, `rede`

- `regiao`: `regiao`, `rede`

**Value columns** (vary by `metric`):

- `indicador`: `ano`, `indicador`, `valor`

- `aprovacao`: `ano`, `ano_escolar` or `serie` (ensino_medio),
  `taxa_aprovacao`

- `nota`: `ano`, `disciplina`, `nota`

- `meta`: `ano`, `meta`

## Details

IDEB is calculated every two years since 2005 based on:

- **Learning**: Average scores in Portuguese and Mathematics from SAEB

- **Flow**: Grade promotion rate (inverse of repetition/dropout)

The index ranges from 0 to 10. Brazil's national goal is to reach 6.0 by
2022 (the level of developed countries in PISA).

The function always downloads the most recent IDEB file available from
INEP, which contains the full historical series (2005-2023).

## Data source

Official IDEB portal:
<https://www.gov.br/inep/pt-br/areas-de-atuacao/pesquisas-estatisticas-e-indicadores/ideb>

## See also

Other IDEB functions:
[`get_ideb_series()`](https://sidneybissoli.github.io/educabR/reference/get_ideb_series.md),
[`list_ideb_available()`](https://sidneybissoli.github.io/educabR/reference/list_ideb_available.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# school-level IDEB indicators for early elementary
ideb <- get_ideb("escola", "anos_iniciais", "indicador")

# municipality-level approval rates, only 2021 and 2023
aprov <- get_ideb("municipio", "anos_finais", "aprovacao", year = c(2021, 2023))

# national IDEB targets
metas <- get_ideb("brasil", "ensino_medio", "meta")

# state-level SAEB scores
notas <- get_ideb("estado", "anos_iniciais", "nota")

# region-level IDEB indicators
regioes <- get_ideb("regiao", "anos_finais", "indicador")
} # }
```

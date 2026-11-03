# Get ENADE (Exame Nacional de Desempenho dos Estudantes) data

Downloads and processes microdata from ENADE, the Brazilian National
Student Performance Exam. ENADE evaluates the performance of
undergraduate students in higher education.

Every edition is published as several files (`arq1`, `arq2`, ...), each
with one group of variables. **The files cannot be joined student by
student**: to comply with the LGPD, INEP sorts each file by different
variables, so the first row of one file is not the same student as the
first row of another. `get_enade()` therefore reads one file per call;
use
[`list_enade_files()`](https://sidneybissoli.github.io/educabR/reference/list_enade_files.md)
to see which variables each file holds.

## Usage

``` r
get_enade(year, arquivo = NULL, n_max = Inf, keep_zip = TRUE, quiet = FALSE)
```

## Arguments

- year:

  The year of the exam (2004-2019, 2021-2023).

- arquivo:

  The file to read: the number in its name (`microdados2023_arq3.txt` is
  `arquivo = 3`). Default `NULL` reads file 1 (course and institution
  identifiers) and warns that the edition is split.

- n_max:

  Maximum number of rows to read. Default is `Inf` (all rows). Consider
  using a smaller value for exploration.

- keep_zip:

  Logical. If `TRUE`, keeps the downloaded ZIP file in cache.

- quiet:

  Logical. If `TRUE`, suppresses progress messages.

## Value

A tibble with the microdata of one ENADE file.

## Details

ENADE is conducted annually by INEP and evaluates undergraduate students
nearing the end of their programs. Each year, a different set of course
areas is assessed on a rotating cycle (typically every 3 years per
area).

Every file carries `nu_ano` and `co_curso`, so files can be combined at
the course level (for example, averages by `co_curso`), as INEP's user
manual recommends. Combining them row by row produces records that mix
different students; up to educabR 1.2.0, `get_enade()` did exactly that.
Student-level linkage is only available through INEP's protected data
service (Sedap).

**Important notes:**

- Use `n_max` to read a sample first for exploration.

- Column names are standardized to lowercase with underscores.

- Not all course areas are assessed every year due to the rotating
  cycle.

- The numbering of files can skip numbers (2013 has no `arq3`).

## Data dictionary

Each edition ships a dictionary of files and variables
(`Dicionario_arquivos_variaveis_microdados_Enade_<year>.xlsx`) in the
downloaded archive. See also INEP's documentation:
<https://www.gov.br/inep/pt-br/acesso-a-informacao/dados-abertos/microdados/enade>

## See also

Other ENADE functions:
[`list_enade_files()`](https://sidneybissoli.github.io/educabR/reference/list_enade_files.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# which variables are in which file?
list_enade_files(2023)

# read one file
arq3 <- get_enade(2023, arquivo = 3)

# combine files at the course level (co_curso), never row by row
scores <- get_enade(2023, arquivo = 3)
by_course <- aggregate(nt_ger ~ co_curso, data = scores, FUN = mean)
} # }
```

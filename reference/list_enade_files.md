# List the files of an ENADE edition

Downloads (if needed) the microdata of an ENADE edition and lists its
data files with the variables each one holds. Use the `arquivo` number
with
[`get_enade()`](https://sidneybissoli.github.io/educabR/reference/get_enade.md).

## Usage

``` r
list_enade_files(year, quiet = FALSE)
```

## Arguments

- year:

  The year of the exam.

- quiet:

  Logical. If `TRUE`, suppresses progress messages.

## Value

A tibble with one row per file: `arquivo` (number to pass to
[`get_enade()`](https://sidneybissoli.github.io/educabR/reference/get_enade.md)),
`nome` (file name), `n_variaveis` and `variaveis` (the variables other
than `nu_ano` and `co_curso`, comma-separated).

## See also

Other ENADE functions:
[`get_enade()`](https://sidneybissoli.github.io/educabR/reference/get_enade.md)

## Examples

``` r
if (FALSE) { # \dontrun{
files <- list_enade_files(2023)

# which file has the overall score?
files[grepl("nt_ger", files$variaveis), ]
} # }
```

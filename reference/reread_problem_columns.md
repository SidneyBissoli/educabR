# Re-read columns that readr failed to parse

Internal helper for
[`read_inep_file()`](https://sidneybissoli.github.io/educabR/reference/read_inep_file.md).
readr guesses each column type from the first 1,000 rows; a column that
is empty there is read as logical and every later value becomes `NA`
(Censo Escolar 1995: 234 values of `VEM2206`, 1997: 567 of `VPE626`).
Columns with parsing problems are read again as text and their type is
guessed from all values. Columns without problems are untouched.

## Usage

``` r
reread_problem_columns(df, file, delim, encoding, n_max = Inf)
```

## Arguments

- df:

  The tibble returned by
  [`readr::read_delim()`](https://readr.tidyverse.org/reference/read_delim.html).

- file, delim, encoding, n_max:

  The arguments of that read.

## Value

The tibble with those columns replaced.

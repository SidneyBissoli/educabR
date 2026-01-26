# Summary statistics for ENEM scores

Calculates summary statistics for ENEM scores, optionally grouped by
demographic variables.

## Usage

``` r
enem_summary(data, by = NULL)
```

## Arguments

- data:

  A tibble with ENEM data (from
  [`get_enem()`](https://sidneybissoli.github.io/educabR/reference/get_enem.md)).

- by:

  Optional grouping variable(s) as character vector.

## Value

A tibble with summary statistics for each score area.

## Examples

``` r
if (FALSE) { # \dontrun{
enem <- get_enem(2023, n_max = 10000)

# overall summary
enem_summary(enem)

# summary by sex
enem_summary(enem, by = "tp_sexo")
} # }
```

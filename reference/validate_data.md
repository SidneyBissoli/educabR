# Validate downloaded data structure

Internal function to validate that downloaded data has the expected
structure. Issues warnings for potential problems and errors for
critical issues.

## Usage

``` r
validate_data(data, dataset, year)
```

## Arguments

- data:

  A tibble with the downloaded data.

- dataset:

  The dataset name ("enem", "enem_itens", "ideb", "censo_escolar").

- year:

  The year of the data.

## Value

The input data (invisibly), or aborts with an error.

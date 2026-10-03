# Find the per-grade SAEB student file

Internal function that matches `TS_ALUNO_<serie>.csv` by exact name.

## Usage

``` r
find_saeb_aluno_by_serie(exdir, year, serie = NULL)
```

## Arguments

- exdir:

  The extraction directory.

- year:

  The year.

- serie:

  For `"aluno"`, the normalized grade code (e.g. `"5ef"`), or `NULL`.

## Value

The path to the file, or `NULL` when the edition has no per-grade
student files.

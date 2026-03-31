# Find the Higher Education Census data file

Internal function to locate a Higher Education Census data file within
the extracted directory based on the requested type.

## Usage

``` r
find_censo_superior_file(exdir, year, type = "ies")
```

## Arguments

- exdir:

  The extraction directory.

- year:

  The year.

- type:

  The data type ("ies", "cursos", "alunos", "docentes").

## Value

The path to the data file.

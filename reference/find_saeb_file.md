# Find the SAEB data file

Internal function to locate a SAEB data file within the extracted
directory based on the requested type.

## Usage

``` r
find_saeb_file(exdir, year, type = "aluno")
```

## Arguments

- exdir:

  The extraction directory.

- year:

  The year.

- type:

  The data type ("aluno", "escola", "diretor", "professor").

## Value

The path to the data file.

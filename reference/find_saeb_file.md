# Find the SAEB data file

Internal function to locate a SAEB data file within the extracted
directory based on the requested type.

## Usage

``` r
find_saeb_file(exdir, year, type = "aluno", serie = NULL)
```

## Arguments

- exdir:

  The extraction directory.

- year:

  The year.

- type:

  The data type ("aluno", "escola", "diretor", "professor").

- serie:

  For `"aluno"`, the normalized grade code (e.g. `"5ef"`), or `NULL`.

## Value

The path to the data file.

## Details

Since 2013 INEP ships one student file per grade (`TS_ALUNO_2EF.csv`,
`TS_ALUNO_5EF.csv`, ...). These are matched by exact name: with more
than one grade available and no `serie`, the function aborts listing the
grades instead of picking one silently.

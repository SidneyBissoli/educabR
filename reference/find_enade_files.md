# Find ENADE data files

Internal function to locate all ENADE data files within the extracted
directory. INEP distributes ENADE microdata split across multiple files
(`arq1.txt`, `arq2.txt`, ...) that share the columns `NU_ANO` and
`CO_CURSO` but are sorted differently (they cannot be joined by row).

## Usage

``` r
find_enade_files(exdir, year)
```

## Arguments

- exdir:

  The extraction directory.

- year:

  The year.

## Value

A character vector of file paths, sorted by split number.

# Find ENADE data files

Internal function to locate all ENADE data files within the extracted
directory. INEP distributes ENADE microdata split across multiple files
(`arq1.txt`, `arq2.txt`, ...) that share key columns (`NU_ANO`,
`CO_CURSO`) and contain different variable groups.

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

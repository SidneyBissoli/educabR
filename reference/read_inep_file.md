# Read INEP data file

Internal function to read INEP data files with appropriate settings.

## Usage

``` r
read_inep_file(file, delim = ";", encoding = NULL, n_max = Inf)
```

## Arguments

- file:

  Path to the data file.

- delim:

  The delimiter character.

- encoding:

  The file encoding.

- n_max:

  Maximum number of rows to read.

## Value

A tibble with the data.

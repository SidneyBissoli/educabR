# Find data files in extracted directory

Internal function to locate the main data files after extraction.

## Usage

``` r
find_data_files(exdir, pattern = "\\.(csv|CSV|txt|TXT)$")
```

## Arguments

- exdir:

  The extraction directory.

- pattern:

  Optional regex pattern to filter files.

## Value

A character vector of file paths.

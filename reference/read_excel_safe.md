# Read Excel file safely

Internal function to read Excel files (xls/xlsx) with error handling.
Tries to read the first sheet by default.

## Usage

``` r
read_excel_safe(file, n_max = Inf)
```

## Arguments

- file:

  Path to the Excel file.

- n_max:

  Maximum number of rows to read.

## Value

A tibble with the data.

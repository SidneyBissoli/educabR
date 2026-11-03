# Find how many title rows precede the header of an Excel sheet

Internal function. Returns the number of rows to skip so that the header
is the first row where at least half of the columns are filled. A sheet
whose first row is already the header returns 0.

## Usage

``` r
excel_header_skip(file, sheet = 1)
```

## Arguments

- file:

  Path to the Excel file.

- sheet:

  Sheet name or position.

## Value

An integer.

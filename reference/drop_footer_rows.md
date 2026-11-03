# Drop blank, footnote and total rows from a sheet read with readxl

Internal function. INEP spreadsheets end with blank rows, footnotes
written in the first column, or a lone total in one column (CPC 2022). A
data row always fills several columns, so rows with at most one filled
cell are dropped.

## Usage

``` r
drop_footer_rows(df)
```

## Arguments

- df:

  A data frame.

## Value

The data frame without those rows.

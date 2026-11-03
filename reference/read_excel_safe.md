# Read Excel file safely

Internal function to read Excel files (xls/xlsx) with error handling.
Reads the first sheet by default. Three INEP layout quirks are handled:

- a title row above the header (e.g. IGC 2009) is skipped, by taking as
  header the first row where at least half of the columns are filled;

- a sub-header row below the header (e.g. IGC 2008: "IGC" over
  "Continuo" and "Faixas") is merged into the column names;

- blank, footnote and total rows (e.g. CPC 2021 and 2022, IGC 2021),
  i.e. rows with at most one filled cell, are dropped.

## Usage

``` r
read_excel_safe(file, n_max = Inf, sheet = 1)
```

## Arguments

- file:

  Path to the Excel file.

- n_max:

  Maximum number of rows to read.

- sheet:

  Sheet name or position. Default is the first sheet.

## Value

A tibble with the data.

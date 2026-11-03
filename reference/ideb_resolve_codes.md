# Fix IDEB column codes that INEP repeated with the wrong year

Internal helper for
[`read_ideb_excel()`](https://sidneybissoli.github.io/educabR/reference/read_ideb_excel.md).
Row 10 of an IDEB sheet holds the column codes
(`VL_INDICADOR_REND_2023`); rows above it hold the block headers ("Taxa
de Aprovacao - 2025"), merged over the columns of each edition. When a
`VL_*` code appears more than once, the year of each copy is taken from
its block header. Codes that are not repeated are returned unchanged.

## Usage

``` r
ideb_resolve_codes(file, sheet, col_names)
```

## Arguments

- file:

  Path to the Excel file.

- sheet:

  Sheet name or position.

- col_names:

  Column names as read from row 10 (readxl may have appended `...N` to
  repeated names).

## Value

A character vector of column names.

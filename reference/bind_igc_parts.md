# Stack the parts of an IGC table

Internal function. Stacks the per-institution-type parts of an IGC
table. Parts with the same number of columns take the column names of
the first part, because INEP sometimes words the same header differently
across sheets (IGC 2010: "Porcentagem de" in one sheet, "%" in the
others). Otherwise parts are stacked by name. Columns whose type differs
across parts are converted to character.

## Usage

``` r
bind_igc_parts(parts)
```

## Arguments

- parts:

  A list of data frames.

## Value

A tibble.

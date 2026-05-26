# Read IDEB Excel file

Internal function to read IDEB Excel files. When `metric` is provided,
performs a two-pass read: the header is parsed first to identify which
`vl_*` columns belong to the requested metric (and optionally the
requested `year`s), then the file is re-read with `col_types = "skip"`
on the irrelevant columns. This drastically reduces peak memory for
school-level files, which can otherwise balloon to several GB when read
in full.

## Usage

``` r
read_ideb_excel(file, sheet = NULL, metric = NULL, year = NULL)
```

## Arguments

- file:

  Path to the Excel file.

- sheet:

  Sheet name to read (NULL for first sheet).

- metric:

  Optional. If provided, restricts the read to the `vl_*` columns
  matching this metric. When `NULL`, the whole sheet is read (legacy
  behavior).

- year:

  Optional. Integer vector. When provided alongside `metric`, further
  restricts the read to `vl_*` columns whose embedded year is in this
  set.

## Value

A tibble with the data.

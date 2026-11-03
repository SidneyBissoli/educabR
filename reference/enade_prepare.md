# Download and extract an ENADE edition

Internal function shared by
[`get_enade()`](https://sidneybissoli.github.io/educabR/reference/get_enade.md)
and
[`list_enade_files()`](https://sidneybissoli.github.io/educabR/reference/list_enade_files.md).

## Usage

``` r
enade_prepare(year, keep_zip = TRUE, quiet = FALSE)
```

## Arguments

- year:

  The year.

- keep_zip:

  Logical. Keep the downloaded archive.

- quiet:

  Logical. Suppress messages.

## Value

The extraction directory.

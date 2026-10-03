# Find the ENCCEJA data file

Internal function to locate the ENCCEJA data file within the extracted
directory.

## Usage

``` r
find_encceja_file(exdir, year, type = "regular")
```

## Arguments

- exdir:

  The extraction directory.

- year:

  The year.

- type:

  `"regular"` or `"ppl"`.

## Value

The path to the data file.

## Details

Every published edition ships a regular file (`REG_NAC` or `REGULAR`)
and a PPL file (`PPL_NAC` or `PPL`), plus PPL questionnaire and item
files. The participant file is chosen by type, so the small PPL file is
never returned in place of the regular one. Layouts without either
marker fall back to the generic name patterns.

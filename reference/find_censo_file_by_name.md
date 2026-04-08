# Find a Censo Escolar file by user-supplied name

Internal function to locate a specific CSV file within the extracted
census directory by partial name match.

## Usage

``` r
find_censo_file_by_name(exdir, file, year)
```

## Arguments

- exdir:

  The extraction directory.

- file:

  The file name or partial name to match.

- year:

  The year (used in error messages).

## Value

The full path to the matched file.

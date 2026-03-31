# Find the ENEM data file

Internal function to locate the main ENEM data file within the extracted
directory.

## Usage

``` r
find_enem_file(exdir, year, type = "participantes")
```

## Arguments

- exdir:

  The extraction directory.

- year:

  The year.

- type:

  The data type (`"participantes"` or `"resultados"`).

## Value

The path to the data file.

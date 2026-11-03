# Find the institution-level sheets of an IGC spreadsheet

Internal function. From 2008 to 2016, INEP splits the IGC table into one
sheet per type of institution ("Universidades", "Centros
Universitarios", "Faculdades" or "Outros"), followed by sheets with
course- or program-level inputs. Returns the institution sheets, or the
first sheet when the file is not split (2017 onwards).

## Usage

``` r
igc_institution_sheets(file)
```

## Arguments

- file:

  Path to the Excel file.

## Value

A character vector of sheet names.

# Detect file delimiter

Internal function to detect the delimiter used in a CSV file by reading
the first line and counting occurrences of common delimiters.

## Usage

``` r
detect_delim(file)
```

## Arguments

- file:

  Path to the data file.

## Value

The detected delimiter character.

# Detect file encoding

Internal function to detect the encoding of a text file. INEP files
typically use Latin-1 or UTF-8.

## Usage

``` r
detect_encoding(file)
```

## Arguments

- file:

  Path to the file.

## Value

A character string with the encoding name.

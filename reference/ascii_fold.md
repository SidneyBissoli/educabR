# Fold text to ASCII the same way on every platform

Internal function used to build column names and to compare sheet names.
`iconv(to = "ASCII//TRANSLIT")` is platform-dependent: macOS turns
"i-acute" into "'i", so names such as "Municipio" (with accent) came out
as `munic_ipio` there. This uses ICU's Latin-ASCII transform and then
reproduces the names educabR already produced on Windows: ordinal
indicators become letters ("N.o" -\> "no"), superscript digits become
digits, and Greek letters and sharp s are dropped.

## Usage

``` r
ascii_fold(x)
```

## Arguments

- x:

  A character vector.

## Value

A character vector.

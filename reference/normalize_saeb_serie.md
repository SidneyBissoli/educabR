# Normalize the SAEB grade argument

Internal function that turns the user's `serie` into INEP's lowercase
grade code: `5` becomes `"5ef"`, `"5EF"` becomes `"5ef"`.

## Usage

``` r
normalize_saeb_serie(serie)
```

## Arguments

- serie:

  A single grade code or number, or `NULL`.

## Value

A lowercase string, or `NULL`.

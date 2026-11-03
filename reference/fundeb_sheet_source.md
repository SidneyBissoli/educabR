# Source name of a FUNDEB sheet

Internal function. The sheet name is the destination prefix (`E_` for
states, `M_` for municipalities) followed by the source. The VAAF, VAAT
and VAAR shares of the Complementacao da Uniao (`E_COUN_VAAF`) keep the
short name (`"VAAF"`); every other sheet keeps its full suffix (`E_COUN`
-\> `"COUN"`, `E_AFE_EC123` -\> `"AFE_EC123"`).

## Usage

``` r
fundeb_sheet_source(sheet)
```

## Arguments

- sheet:

  A sheet name.

## Value

A string.

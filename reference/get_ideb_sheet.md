# Get IDEB Excel sheet name

Internal function to determine which sheet to read for brasil/regiao_uf
levels.

## Usage

``` r
get_ideb_sheet(level, stage)
```

## Arguments

- level:

  Geographic level.

- stage:

  Education stage.

## Value

Sheet name (character) or NULL for escola/municipio.

# Reference year of a CAPES resource

Internal function. CAPES file names carry the reference year followed by
the publication date (`br-capes-colsucup-prog-2017-2021-11-10.csv`) or,
in the 2013-2016 packages, a range and a `_YYYY` suffix
(`br-capes-btd-2013a2016-2017-12-01_2014.csv`). Matching on "contains
the year" picked the wrong file there (every 2013-2016 name contains
"2016"), so the year is read from that structure.

## Usage

``` r
capes_resource_year(x)
```

## Arguments

- x:

  Resource names or URLs.

## Value

An integer vector (`NA` when no year is found).

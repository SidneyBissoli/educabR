# Check available years for a dataset

Returns the years available for a given INEP dataset.

## Usage

``` r
available_years(dataset)
```

## Arguments

- dataset:

  The dataset name.

## Value

An integer vector of available years.

## Examples

``` r
available_years("censo_escolar")
#>  [1] 1995 1996 1997 1998 1999 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009
#> [16] 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020 2021 2022 2023 2024
available_years("enem")
#>  [1] 1998 1999 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012
#> [16] 2013 2014 2015 2016 2017 2018 2019 2020 2021 2022 2023 2024
```

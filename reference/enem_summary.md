# Summary statistics for ENEM scores

Calculates summary statistics for ENEM scores, optionally grouped by
demographic variables.

## Usage

``` r
enem_summary(data, by = NULL)
```

## Arguments

- data:

  A tibble with ENEM data (from
  [`get_enem()`](https://sidneybissoli.github.io/educabR/reference/get_enem.md)).

- by:

  Optional grouping variable(s) as character vector.

## Value

A tibble with summary statistics for each score area.

## Examples

``` r
# \donttest{
enem <- get_enem(2023, n_max = 10000)
#> ℹ downloading ENEM 2023...
#> ! ENEM files are large (1-3 GB). this may take a while...
#> ℹ downloading from INEP...
#> ✔ downloaded 496.45 MB
#> ℹ extracting files...
#> ✔ extracted 83 file(s)
#> ℹ reading ENEM data...
#> ℹ reading file with encoding: "UTF-8"
#> ✔ loaded 10000 rows and 76 columns

# overall summary
enem_summary(enem)
#> # A tibble: 10 × 10
#>    variable            n n_valid  mean    sd   min   q25 median   q75   max
#>    <chr>           <int>   <int> <dbl> <dbl> <dbl> <dbl>  <dbl> <dbl> <dbl>
#>  1 nu_nota_cn      10000    7281  492.  79.8     0  440.   489.  541.  817.
#>  2 nu_nota_ch      10000    7562  529.  81.7     0  480.   535.  584.  823 
#>  3 nu_nota_lc      10000    7562  520.  70.4     0  476.   524.  568.  731.
#>  4 nu_nota_mt      10000    7281  520. 121.      0  426.   507.  608   945.
#>  5 nu_nota_comp1   10000    7562  126.  32.1     0  120    120   160   200 
#>  6 nu_nota_comp2   10000    7562  147.  48.4     0  120    160   200   200 
#>  7 nu_nota_comp3   10000    7562  124.  41.0     0  100    120   160   200 
#>  8 nu_nota_comp4   10000    7562  136.  41.2     0  120    120   160   200 
#>  9 nu_nota_comp5   10000    7562  117.  60.0     0   80    120   160   200 
#> 10 nu_nota_redacao 10000    7562  649. 201.      0  520    640   820   980 

# summary by sex
enem_summary(enem, by = "tp_sexo")
#> # A tibble: 20 × 11
#>    tp_sexo variable         n n_valid  mean    sd   min   q25 median   q75   max
#>    <chr>   <chr>        <int>   <int> <dbl> <dbl> <dbl> <dbl>  <dbl> <dbl> <dbl>
#>  1 F       nu_nota_cn    7042    5130  485.  76.5     0  435    481.  532   817.
#>  2 M       nu_nota_cn    2958    2151  507.  85.1     0  455.   508.  560.  804.
#>  3 F       nu_nota_ch    7042    5328  527.  78.6     0  480.   532.  579.  784.
#>  4 M       nu_nota_ch    2958    2234  535.  88.2     0  483.   542.  596.  823 
#>  5 F       nu_nota_lc    7042    5328  520.  68.2     0  476.   523.  566.  731.
#>  6 M       nu_nota_lc    2958    2234  522.  75.5     0  478.   527.  574.  729.
#>  7 F       nu_nota_mt    7042    5130  509. 116.      0  420.   494.  589   944.
#>  8 M       nu_nota_mt    2958    2151  547. 129.      0  447.   540.  643.  945.
#>  9 F       nu_nota_com…  7042    5328  128.  30.8     0  120    120   160   200 
#> 10 M       nu_nota_com…  2958    2234  121.  34.6     0  100    120   140   200 
#> 11 F       nu_nota_com…  7042    5328  149.  47.4     0  120    160   200   200 
#> 12 M       nu_nota_com…  2958    2234  142.  50.3     0  120    140   180   200 
#> 13 F       nu_nota_com…  7042    5328  125.  40.0     0  100    120   160   200 
#> 14 M       nu_nota_com…  2958    2234  120.  42.9     0  100    120   140   200 
#> 15 F       nu_nota_com…  7042    5328  137.  40.3     0  120    120   160   200 
#> 16 M       nu_nota_com…  2958    2234  132.  43.0     0  120    120   160   200 
#> 17 F       nu_nota_com…  7042    5328  118.  60.1     0   80    120   160   200 
#> 18 M       nu_nota_com…  2958    2234  115.  59.9     0   80    120   160   200 
#> 19 F       nu_nota_red…  7042    5328  657. 197.      0  540    660   820   980 
#> 20 M       nu_nota_red…  2958    2234  629. 210.      0  520    620   800   980 
# }
```

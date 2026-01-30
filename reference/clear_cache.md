# Clear the educabR cache

Removes all cached files from the educabR cache directory.

## Usage

``` r
clear_cache(dataset = NULL)
```

## Arguments

- dataset:

  Optional. A character string specifying which dataset cache to clear.
  If `NULL`, clears all caches.

## Value

Invisibly returns `TRUE` if successful.

## Examples

``` r
# \donttest{
# clear all cached data
clear_cache()
#> ℹ cache is already empty

# clear only ENEM cache
clear_cache("enem")
#> ℹ no cache found for "enem"
# }
```

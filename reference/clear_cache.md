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

## See also

Other cache functions:
[`get_cache_dir()`](https://sidneybissoli.github.io/educabR/reference/get_cache_dir.md),
[`list_cache()`](https://sidneybissoli.github.io/educabR/reference/list_cache.md),
[`set_cache_dir()`](https://sidneybissoli.github.io/educabR/reference/set_cache_dir.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# clear all cached data
clear_cache()

# clear only ENEM cache
clear_cache("enem")
} # }
```

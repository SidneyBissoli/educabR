# List cached files

Lists all files currently in the educabR cache.

## Usage

``` r
list_cache(dataset = NULL)
```

## Arguments

- dataset:

  Optional. Filter by dataset name.

## Value

A tibble with information about cached files.

## See also

Other cache functions:
[`clear_cache()`](https://sidneybissoli.github.io/educabR/reference/clear_cache.md),
[`get_cache_dir()`](https://sidneybissoli.github.io/educabR/reference/get_cache_dir.md),
[`set_cache_dir()`](https://sidneybissoli.github.io/educabR/reference/set_cache_dir.md)

## Examples

``` r
if (FALSE) { # \dontrun{
list_cache()
} # }
```

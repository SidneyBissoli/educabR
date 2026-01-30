# Set the cache directory for educabR

Sets the directory where downloaded files will be cached. This avoids
repeated downloads of the same data.

## Usage

``` r
set_cache_dir(path = NULL, persistent = FALSE)
```

## Arguments

- path:

  A character string with the path to the cache directory. If `NULL`,
  uses a temporary directory (default).

- persistent:

  Logical. If `TRUE`, the cache directory setting is saved to the user's
  R profile for future sessions.

## Value

Invisibly returns the cache directory path.

## Examples

``` r
# \donttest{
# set a persistent cache directory
set_cache_dir("~/educabR_cache")
#> ✔ cache directory created: /home/runner/educabR_cache
# }
```

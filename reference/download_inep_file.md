# Download a file from INEP

Internal function to download files from INEP's servers with progress
indication and error handling.

## Usage

``` r
download_inep_file(url, destfile, quiet = FALSE)
```

## Arguments

- url:

  The URL to download from.

- destfile:

  The destination file path.

- quiet:

  Logical. If `TRUE`, suppresses progress messages.

## Value

The path to the downloaded file.

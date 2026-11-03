# Drop an incomplete UTF-8 sequence at the end of a raw vector

Internal function. A fixed-size chunk read from a UTF-8 file can cut a
multibyte character. Only a trailing lead byte whose sequence is
incomplete (with its continuation bytes) is dropped, so a latin1 byte at
the end is kept and still makes the chunk invalid.

## Usage

``` r
drop_incomplete_utf8_tail(bytes)
```

## Arguments

- bytes:

  A raw vector.

## Value

The raw vector, possibly shorter.

# Changelog

## educabR 0.1.2

CRAN release: 2026-02-19

### New features

- [`get_ideb_series()`](https://sidneybissoli.github.io/educabR/reference/get_ideb_series.md)
  now shows per-year progress indication (e.g., “processing IDEB 2017
  (1/4)”) and propagates the `quiet` parameter to inner
  [`get_ideb()`](https://sidneybissoli.github.io/educabR/reference/get_ideb.md)
  calls.

### Documentation

- Added English README (`README.md`) as default; Portuguese version
  renamed to `README.pt-br.md` with cross-links between both.
- Fixed `@param year` ranges in documentation to match
  [`available_years()`](https://sidneybissoli.github.io/educabR/reference/available_years.md):
  - [`get_enem()`](https://sidneybissoli.github.io/educabR/reference/get_enem.md)
    /
    [`get_enem_itens()`](https://sidneybissoli.github.io/educabR/reference/get_enem_itens.md):
    2009-2023 -\> 1998-2024
  - [`get_censo_escolar()`](https://sidneybissoli.github.io/educabR/reference/get_censo_escolar.md):
    2007-2024 -\> 1995-2024
- Added `@family` tags to group related functions in help pages (ENEM,
  IDEB, School Census, cache).
- Fixed Portuguese accents in `README.pt-br.md`.

### Tests

- Added tests for
  [`enem_summary()`](https://sidneybissoli.github.io/educabR/reference/enem_summary.md):
  statistics calculation, NA handling, grouping by variable, and error
  on missing score columns.

### CRAN

- Replaced `\donttest` with `\dontrun` in all examples per CRAN request.

## educabR 0.1.1

### Bug fixes

- Fixed
  [`set_cache_dir()`](https://sidneybissoli.github.io/educabR/reference/set_cache_dir.md)
  example that created a directory in the user’s home
  (`~/educabR_cache`) during CRAN checks. Now uses
  [`tempdir()`](https://rdrr.io/r/base/tempfile.html) in examples.

## educabR 0.1.0

CRAN release: 2026-02-03

First public release.

### New features

#### IDEB

- [`get_ideb()`](https://sidneybissoli.github.io/educabR/reference/get_ideb.md):
  Download IDEB data (years 2017, 2019, 2021, 2023).
- [`get_ideb_series()`](https://sidneybissoli.github.io/educabR/reference/get_ideb_series.md):
  Download IDEB historical series across multiple years.
- [`list_ideb_available()`](https://sidneybissoli.github.io/educabR/reference/list_ideb_available.md):
  List available year/stage/level combinations.

#### ENEM

- [`get_enem()`](https://sidneybissoli.github.io/educabR/reference/get_enem.md):
  Download ENEM microdata (years 1998-2024).
- [`get_enem_itens()`](https://sidneybissoli.github.io/educabR/reference/get_enem_itens.md):
  Download ENEM item response data.
- [`enem_summary()`](https://sidneybissoli.github.io/educabR/reference/enem_summary.md):
  Calculate summary statistics for ENEM scores.

#### School Census

- [`get_censo_escolar()`](https://sidneybissoli.github.io/educabR/reference/get_censo_escolar.md):
  Download School Census microdata (years 1995-2024).
- [`list_censo_files()`](https://sidneybissoli.github.io/educabR/reference/list_censo_files.md):
  List available files in a downloaded census.

#### Cache management

- [`set_cache_dir()`](https://sidneybissoli.github.io/educabR/reference/set_cache_dir.md):
  Set custom cache directory.
- [`get_cache_dir()`](https://sidneybissoli.github.io/educabR/reference/get_cache_dir.md):
  Get current cache directory.
- [`clear_cache()`](https://sidneybissoli.github.io/educabR/reference/clear_cache.md):
  Clear cached files.
- [`list_cache()`](https://sidneybissoli.github.io/educabR/reference/list_cache.md):
  List cached files with metadata.

#### Utilities

- [`available_years()`](https://sidneybissoli.github.io/educabR/reference/available_years.md):
  Get available years for each dataset.

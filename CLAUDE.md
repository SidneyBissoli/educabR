# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What is educabR

An R package (v0.9.0) for downloading and processing Brazilian public education data from INEP, FNDE, STN, and CAPES. Provides 14+ `get_*()` functions that fetch, cache, extract, and return tidy data frames. All text output (column names, CLI messages) is in Portuguese.

## Common Commands

```bash
# Check package (full R CMD check)
Rscript -e "devtools::check()"

# Run all tests
Rscript -e "devtools::test()"

# Run a single test file
Rscript -e "devtools::test(filter = 'utils-cache')"

# Regenerate documentation (roxygen2 → man/ + NAMESPACE)
Rscript -e "devtools::document()"

# Load package for interactive testing
Rscript -e "devtools::load_all()"

# Build pkgdown site
Rscript -e "pkgdown::build_site()"
```

## Architecture

### Data pipeline pattern (every `get_*()` function)

```
validate parameters → check cache → download if needed → extract archive → read file → standardize column names → transform → validate output → return tibble
```

Key internal modules:
- `R/utils-cache.R` — Local cache system (`tempdir()/educabR_cache` or user-configured). Functions: `cache_path()`, `is_cached()`, `get_cache_dir()`, `set_cache_dir()`, `clear_cache()`, `list_cache()`
- `R/utils-download.R` — HTTP downloads with retry (3 attempts, 600s timeout), archive extraction (ZIP/7z/RAR), URL construction, dynamic year discovery via HEAD requests
- `R/utils-validation.R` — Per-dataset validators checking column counts, expected names, non-empty results
- `R/zzz.R` — Package init, reads `educabR.cache_dir` option

### Data source variations

Not all datasets follow the same pattern:
- **CSV-in-ZIP** (most): ENEM, SAEB, Censo Escolar, Censo Superior, ENADE, ENCCEJA
- **Excel** (IDEB, FUNDEB distribution, some CAPES): Use `readxl`, multi-sheet logic
- **OData API** (FUNDEB enrollment): `httr2` JSON requests to FNDE API
- **ENEM 2024+**: Split into "participantes" (demographics) and "resultados" (scores) — two separate files

### Platform-specific code

ZIP extraction has Windows-specific paths: PowerShell `Expand-Archive` fallback for encoding issues, 7-Zip path hunting in Program Files. Check `.Platform$OS.type` when modifying extraction logic.

## Testing

- Framework: testthat edition 3, with snapshot tests in `tests/testthat/_snaps/`
- `tests/testthat/setup.R` sets `EDUCABR_SKIP_DISCOVERY=true` to prevent HTTP requests during tests
- Tests use `withr::local_tempdir()` for isolation and `withr::local_options()` for scoped settings
- No live downloads in tests — functions are tested against structure/logic, not network calls
- CI runs on macOS, Windows, Ubuntu (R release, devel, oldrel-1)

## Important Conventions

- All `get_*()` functions return data in **long (tidy) format** with standardized lowercase/underscore column names
- Portuguese accents are preserved in data values but column names use ASCII
- Roxygen2 generates `man/` and `NAMESPACE` — never edit those by hand
- `docs/` folder is for the pkgdown site, local-only (not committed)
- `data/` and `lib/` are local development artifacts (not committed)
- Vignette examples use `eval=FALSE` to avoid network calls during build
- The `cli` package is used for all user-facing messages (not `message()` or `cat()`)

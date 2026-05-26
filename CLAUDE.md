# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What is educabR

An R package for downloading and processing Brazilian public education data from INEP, FNDE, STN, and CAPES. NAMESPACE exports the `get_*()` dataset family plus discovery helpers (`available_years()`, `list_ideb_available()`, `list_censo_files()`, `list_censo_superior_files()`), summarizers (`enem_summary()`, `get_enem_itens()`), and cache controls. All text output (column names, CLI messages) is in Portuguese.

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
- **Censo Escolar 2025**: Split-table layout (one table per entity) — different from prior years. See `R/get-censo-escolar.R` before assuming the legacy single-table structure.

### Platform-specific code

ZIP extraction has Windows-specific paths: PowerShell `Expand-Archive` fallback for encoding issues, 7-Zip path hunting in Program Files. Check `.Platform$OS.type` when modifying extraction logic.

### Repo layout (non-obvious directories)

- `archive/` — historical audit notes (`auditoria-pos-issue1.md`, `bugs-pendentes.md`). Read-only context for past fixes; check before re-investigating closed audit threads.
- `guides/` — committed INEP guide PDFs (`guides_2007.pdf`, `guides_2025.pdf`). Distinct from the local-only `dictionaries/` folder.
- `inst/bench/` — IDEB memory benchmark utility. Use this when changing `read_ideb_excel()` to verify column-projection savings don't regress.

## Testing

- Framework: testthat edition 3, with snapshot tests in `tests/testthat/_snaps/`
- `tests/testthat/setup.R` sets `EDUCABR_SKIP_DISCOVERY=true` to prevent HTTP requests during tests
- Same env var is useful during interactive dev: `Sys.setenv(EDUCABR_SKIP_DISCOVERY="true")` skips the HEAD-request year discovery on every `available_years()` / `get_*()` call
- Tests use `withr::local_tempdir()` for isolation and `withr::local_options()` for scoped settings
- No live downloads in tests — functions are tested against structure/logic, not network calls
- CI runs on macOS, Windows, Ubuntu (R release, devel, oldrel-1)
- CI workflows under `.github/workflows/`: `R-CMD-check.yaml`, `test-coverage.yaml`, `rhub.yaml`, `pkgdown.yaml`

## Open audit findings

Before changing the read or download pipeline (`read_inep_file`,
`read_excel_safe`, `read_ideb_excel`, `download_inep_file`,
`validate_year`, `extract_zip`), run `gh issue list --label audit` —
each open audit issue carries a diagnosis with file:line evidence, a
proposed fix snippet, and tests to add. Don't redo that analysis from
scratch.

`get_ideb()` was rewritten in v1.0.0 (new signature, tidy long output,
column-projection memory savings; `get_ideb_series()` deprecated). Read
NEWS.md before touching `read_ideb_excel()` or the IDEB pipeline — the
old wide-format / positional-arg behavior is intentionally gone.

## Release artifacts

- `NEWS.md` — update for any user-visible change (new function, signature change, bug fix users would notice). One bullet under the next version heading.
- `cran-comments.md`, `CRAN-SUBMISSION` — CRAN submission metadata; touched only during a release cycle, not regular dev.
- `CITATION.cff` — citation metadata; bump version/date here when releasing.

## Important Conventions

- `get_*()` functions download **one year per call** — never merge years internally. Users compose multi-year datasets with `purrr::map_dfr()` or similar. Do not add `year` vector support or implicit multi-year concatenation. `validate_year()` in `R/utils-validation.R` is the enforcement point and rejects year vectors with a clear error.
- All `get_*()` functions return data in **long (tidy) format** with standardized lowercase/underscore column names
- Portuguese accents are preserved in data values but column names use ASCII
- Roxygen2 generates `man/` and `NAMESPACE` — never edit those by hand
- `docs/`, `data/`, `lib/`, and `dictionaries/` are local-only (not committed). `dictionaries/censo-escolar/dictionary_<year>.pdf` holds INEP's per-year column dictionaries — consult these when adding or fixing year-specific column handling.
- Vignettes use `eval=FALSE` (no network during build). Vignettes in `vignettes/*.Rmd` are the canonical end-to-end usage examples per dataset; consult them before inventing new API patterns.
- The `cli` package is used for all user-facing messages (not `message()` or `cat()`)
- Deprecations use `lifecycle::deprecate_warn()` / `deprecate_soft()`, not bare `.Deprecated()` or `warning()`. Match the existing pattern in `R/get-ideb.R`.
- `README.md` (English) and `README.pt-br.md` (Portuguese) are both user-facing — keep them in sync when changing examples or feature lists.

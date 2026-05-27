# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What is educabR

An R package for downloading and processing Brazilian public education data from INEP, FNDE, STN, and CAPES. NAMESPACE exports the `get_*()` dataset family plus discovery helpers (`available_years()`, `list_ideb_available()`, `list_censo_files()`, `list_censo_superior_files()`), summarizers (`enem_summary()`, `get_enem_itens()`), and cache controls. All text output (column names, CLI messages) is in Portuguese.

## Common Commands

```sh
# Check package (full R CMD check)
Rscript -e "devtools::check()"

# Run all tests
Rscript -e "devtools::test()"

# Run a single test file
Rscript -e "devtools::test(filter = 'utils-cache')"

# Compute test coverage (matches the test-coverage.yaml CI workflow)
Rscript -e "covr::package_coverage()"

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
- `R/utils-download.R` — HTTP downloads with retry (3 attempts; timeout default 600s, configurable via `options(educabR.download_timeout = N)`), post-download verification (size vs `Content-Length`, HTML-masquerade detection, ZIP magic bytes — corrupt files are deleted, not cached), archive extraction (ZIP/7z/RAR), URL construction, dynamic year discovery via HEAD requests
- `R/utils-validation.R` — Per-dataset validators checking column counts, expected names, non-empty results
- `R/zzz.R` — Package init, reads `educabR.cache_dir` option
- `R/educabR-package.R` — Package-level roxygen block (`@keywords internal`, `_PACKAGE` sentinel). Don't regenerate or delete this when running `devtools::document()` — it's the source of `man/educabR-package.Rd`.

### Adding a new `get_*()` dataset

When wiring up a new dataset getter, touch every layer — partial wiring causes silent test gaps and broken docs:

1. New `R/get-<dataset>.R` following the pipeline pattern above (validate → cache → download → extract → read → standardize → validate → return). Reuse `download_inep_file()` / `read_inep_file()` / `extract_zip()` from `R/utils-download.R` rather than reimplementing.
2. Add a per-dataset validator in `R/utils-validation.R` and call it before returning.
3. Roxygen `@export` on the user-facing function, then `Rscript -e "devtools::document()"` to regenerate `man/` and `NAMESPACE`.
4. New `tests/testthat/test-<dataset>.R` — structure/logic only, no live network (the `EDUCABR_SKIP_DISCOVERY=true` env var is already set in `setup.R`).
5. Add a usage example in the relevant `vignettes/*.Rmd` (`eval=FALSE`) if the dataset is user-facing.
6. Bullet under the next-version heading in `NEWS.md`, and add the function/years row to **both** `README.md` and `README.pt-br.md` tables.

### Data source variations

Not all datasets follow the same pattern:
- **CSV-in-ZIP** (most): ENEM, SAEB, Censo Escolar, Censo Superior, ENADE, ENCCEJA
- **Excel** (IDEB, `get_fundeb_distribution()`, some CAPES, CPC, IGC, IDD): Use `readxl`, multi-sheet logic; routed through `read_excel_safe()` / `read_ideb_excel()`
- **OData API** (`get_fundeb_enrollment()`): `httr2` JSON requests to FNDE API
- **ENEM 2024+**: Split into "participantes" (demographics) and "resultados" (scores) — two separate files
- **Censo Escolar 2025**: Split-table layout (one table per entity) — different from prior years. See `R/get-censo-escolar.R` before assuming the legacy single-table structure.

### Platform-specific code

ZIP extraction has Windows-specific paths: PowerShell `Expand-Archive` fallback for encoding issues, 7-Zip path hunting in Program Files. Check `.Platform$OS.type` when modifying extraction logic.

### Repo layout (non-obvious directories)

- `archive/` — historical audit notes (`auditoria-pos-issue1.md`, `bugs-pendentes.md`). Local-only (gitignored), so unavailable on a fresh clone; when present, it's read-only context for past fixes — check before re-investigating closed audit threads.
- `guides/` — local-only (gitignored) INEP guide PDFs (`guides_2007.pdf`, `guides_2025.pdf`).
- `dictionaries/censo-escolar/dictionary_<year>.pdf` — local-only INEP per-year column dictionaries; consult when adding or fixing year-specific column handling.
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
column-projection memory savings; `get_ideb_series()` is soft-deprecated
via `lifecycle::deprecate_soft()` but still exported — don't remove the
export without a `defunct` cycle). Read NEWS.md before touching
`read_ideb_excel()` or the IDEB pipeline — the old wide-format /
positional-arg behavior is intentionally gone.

## Release artifacts

- `NEWS.md` — update for any user-visible change (new function, signature change, bug fix users would notice). One bullet under the next version heading.
- `cran-comments.md`, `CRAN-SUBMISSION` — CRAN submission metadata; touched only during a release cycle, not regular dev.
- `CITATION.cff` — citation metadata; bump version/date here when releasing.

## Important Conventions

- `get_*()` functions download **one year per call** — never merge years internally. Users compose multi-year datasets with `purrr::map_dfr()` or similar. Do not add `year` vector support or implicit multi-year concatenation. `validate_year()` in `R/utils-validation.R` is the enforcement point and rejects year vectors with a clear error. **Exception:** `get_ideb()` accepts year vectors by design — a single INEP Excel file covers all editions, so filtering is in-memory rather than a multi-download. It bypasses `validate_year()` intentionally; don't "fix" it.
- All `get_*()` functions return data in **long (tidy) format** with standardized lowercase/underscore column names
- Portuguese accents are preserved in data values but column names use ASCII
- Roxygen2 generates `man/` and `NAMESPACE` — never edit those by hand
- `docs/`, `data/`, `lib/`, `dictionaries/`, `guides/`, `archive/`, and `tests/testthat/dados/` are all gitignored (local-only). The per-year INEP column dictionaries under `dictionaries/censo-escolar/dictionary_<year>.pdf` are the source of truth when adding or fixing year-specific column handling.
- Vignettes use `eval=FALSE` (no network during build). Vignettes in `vignettes/*.Rmd` are the canonical end-to-end usage examples per dataset; consult them before inventing new API patterns.
- The `cli` package is used for all user-facing messages (not `message()` or `cat()`)
- Deprecations use `lifecycle::deprecate_warn()` / `deprecate_soft()`, not bare `.Deprecated()` or `warning()`. Match the existing pattern in `R/get-ideb.R`.
- `README.md` (English) and `README.pt-br.md` (Portuguese) are both user-facing — keep them in sync when changing examples or feature lists.

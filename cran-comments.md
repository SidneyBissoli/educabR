## Release summary

This is a major release (0.9.1 -> 1.0.0).

`get_ideb()` has been redesigned around a tidy long-format output and
five geographic levels, and now performs column projection at the
`readxl` C++ layer so school-level reads no longer exhaust memory
(previously several GB; now ~37 MB for four years of school-level
indicador data). The old positional signature still works with a
deprecation warning routed through `lifecycle::deprecate_warn()`, and
`get_ideb_series()` is soft-deprecated in favor of the new
`get_ideb(level, stage, metric, year)` interface. Other changes in this
cycle: configurable download timeout via
`options(educabR.download_timeout = N)`, large-file memory warning in
`read_inep_file()`, post-download integrity verification (size,
HTML-masquerade, ZIP magic bytes), clear error on year vectors, UTF-8
NFC normalization of character columns across all four read entrypoints
so equality with literals like `"Pública"` works on Windows, and
several smaller fixes documented in `NEWS.md`.

See `NEWS.md` for the full list, grouped by Breaking changes, New
features, Bug fixes, and Internal.

## R CMD check results

0 errors | 0 warnings | 0 notes

## Test environments

* local: Windows 11, R 4.6.0
* GitHub Actions (`.github/workflows/R-CMD-check.yaml`):
  - macos-latest (R release)
  - windows-latest (R release)
  - ubuntu-latest (R devel, release, oldrel-1)
* win-builder (R devel) -- to be run before submission
* R-hub (`.github/workflows/rhub.yaml`)

## Reverse dependencies

This package has no reverse dependencies on CRAN.

## Notes

The package downloads data from INEP (Instituto Nacional de Estudos e
Pesquisas Educacionais Anisio Teixeira), Brazil's national institute of
educational studies and research. All data is publicly available.

Examples that download data are wrapped in `\dontrun{}` to avoid
timeouts during CRAN checks due to large file downloads from external
servers. Vignettes are built with `eval = FALSE` for the same reason.

URLs to the INEP open-data portal under `https://www.gov.br/inep/...`
return HTTP 403 to automated user agents (anti-bot behavior of the
Brazilian federal `gov.br` infrastructure) but resolve correctly in a
browser. These are the canonical entry points for the data sources
documented by the package and the same URLs accepted by CRAN in
v0.9.x.

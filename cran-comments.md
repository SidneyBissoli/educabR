## Release summary

This is a minor release (1.0.0 -> 1.1.0), with no breaking changes.

`get_ideb()` now supports the IDEB 2025 edition released by INEP on
2026-08-05. INEP changed the packaging for this edition: spreadsheets
now ship inside a `.zip` archive, which the pipeline downloads and
extracts transparently (the cached file remains the inner `.xlsx`, so
cache handling is unchanged). `get_ideb()` also gains
`stage = "ensino_medio_integrado"`, covering the new "Ensino médio mais
educação profissional técnica integrada" cut first published with IDEB
2025, and `list_ideb_available()` lists the new combinations. Bug
fixes: a clear error when the `year` filter matches no IDEB edition,
and dynamic year discovery no longer drops known years on transient
network failures.

See `NEWS.md` for the full list, grouped by New features and Bug fixes.

## R CMD check results

0 errors | 0 warnings | 0 notes

## Test environments

* local: Windows 11, R 4.6.1
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
v1.0.0.

`https://dadosabertos.capes.gov.br` (the canonical CAPES open-data
portal, documented in `get_capes()`) suffers intermittent outages and
may time out during automated URL checks; it recovers on the
government's side and resolves correctly in a browser when up.

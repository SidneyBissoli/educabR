## Release summary

This is a major release (1.2.0 -> 2.0.0). It comes one month after
1.2.0 because a full audit of the package, prompted by a user's
question, found several bugs that returned **wrong or incomplete data
silently** (no error, no warning). We'd rather not leave users analysing
wrong data until the usual interval has passed. Every function and every
year was compared against an independent read of INEP's source files.

The most serious problems fixed:

1. `get_enade()` returned rows that mixed different students in every
   edition (2004-2023). INEP publishes each edition as 27 to 53 files
   sorted differently, which cannot be joined by row; the package glued
   them side by side. `get_enade()` now reads one file per call (new
   `arquivo` argument, new `list_enade_files()`). This changes the
   function's output, hence the major version.

2. `get_igc()` for 2008-2016 read only the first sheet of INEP's
   spreadsheet: about 200 instead of about 2,100 institutions per year.

3. `get_fundeb_distribution()` left out the federal complementation and
   other revenue sources (3% to 13% of the total in 2007-2020); totals
   now match the National Treasury summary sheet in all 40 year x
   destination pairs.

4. CSV columns empty in their first 1,000 rows lost their later values
   (readr's type guess), latin1 files could be misdetected, and answer
   letters "T"/"F" were read as logical. This affected `get_censo_escolar()`
   and `get_saeb()`, among others.

Also: new `get_conceito_enade()`, and several functions that errored for
some years now work (`get_capes()`, `get_idd(2022)`, `get_igc(2007)`,
`get_enem(2025, type = "resultados")`).

`NEWS.md` opens with a note asking users to re-run affected analyses and
lists every fix with the numbers measured.

## R CMD check results

0 errors | 0 warnings | 1 note

The note is the CRAN incoming feasibility check flagging
`https://dadosabertos.capes.gov.br` (HTTP 503 at the time of the check);
see Notes below.

## Test environments

* local: Windows 11, R 4.6.1
* GitHub Actions (`.github/workflows/R-CMD-check.yaml`):
  - macos-latest (R release)
  - windows-latest (R release)
  - ubuntu-latest (R devel, release, oldrel-1)
* win-builder (R devel)
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
may return HTTP 403 to automated user agents (anti-bot behavior of the
Brazilian federal `gov.br` infrastructure) but resolve correctly in a
browser. These are the canonical entry points for the data sources
documented by the package and the same URLs accepted by CRAN in
previous versions.

`https://dadosabertos.capes.gov.br` (the canonical CAPES open-data
portal, documented in `get_capes()`) suffers intermittent outages and
may time out during automated URL checks; it recovers on the
government's side and resolves correctly in a browser when up.

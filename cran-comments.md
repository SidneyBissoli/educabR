## Release summary

This is a minor release (1.1.0 -> 1.2.0). It comes about six weeks after
1.1.0 because it fixes two bugs that made the package return **wrong
data silently** (no error, no warning). We'd rather not leave users
analysing the wrong population until the usual interval has passed.

1. `get_saeb(type = "aluno")` loaded the wrong school grade. Since 2013
   INEP ships one student file per grade, and the package read whichever
   came first alphabetically: the 2nd grade in 2019-2023 and the 3rd year
   of high school in 2013-2017. The 5th and 9th grades, which are the
   most used, could not be reached in any edition. A user reported this
   on GitHub (issue #21). `get_saeb()` gains a `serie` argument, and when
   an edition has several grades it now stops and lists them instead of
   picking one.

2. `get_encceja()` loaded the small file for people deprived of liberty
   (PPL) instead of the national regular exam in 2014, 2017-2020 and
   2022-2025. It now reads the regular exam by default and gains
   `type = c("regular", "ppl")`.

Also: ENCCEJA years for which INEP never published microdata (2015,
2016, 2021) are rejected up front, and ENEM 2025 / ENCCEJA 2025 are
supported.

Both fixes change what the affected calls return. This is intended, and
`NEWS.md` opens with a note asking users to re-check their results.

See `NEWS.md` for the full list, grouped by Bug fixes and New features.

## R CMD check results

0 errors | 0 warnings | 0 notes

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
return HTTP 403 to automated user agents (anti-bot behavior of the
Brazilian federal `gov.br` infrastructure) but resolve correctly in a
browser. These are the canonical entry points for the data sources
documented by the package and the same URLs accepted by CRAN in
v1.0.0.

`https://dadosabertos.capes.gov.br` (the canonical CAPES open-data
portal, documented in `get_capes()`) suffers intermittent outages and
may time out during automated URL checks; it recovers on the
government's side and resolves correctly in a browser when up.

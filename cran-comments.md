## R CMD check results

0 errors | 0 warnings | 0 notes

## Test environments

* local: Windows 11, R 4.5.x
* GitHub Actions:

  - macOS-latest (R release)
  - windows-latest (R release)
  - ubuntu-latest (R devel, release, oldrel-1)

## Resubmission

This is a resubmission. In this version I have addressed the CRAN feedback:
1. Added a reference to the data source (INEP Open Data Portal) in the DESCRIPTION file.
2. Replaced `\dontrun{}` with `\donttest{}` for all examples that download data.
3. Unwrapped the example for `list_ideb_available()` as it runs locally in < 5 sec.

## Notes

The package downloads data from INEP (Instituto Nacional de Estudos e Pesquisas Educacionais Anisio Teixeira), Brazil's national institute of educational studies and research. All data is publicly available.

Examples that download data are wrapped in `\donttest{}` to allow execution during testing while skipping during CRAN checks.

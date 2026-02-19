## R CMD check results

0 errors | 0 warnings | 0 notes

## Test environments

* local: Windows 11, R 4.5.x
* GitHub Actions:

  - macOS-latest (R release)
  - windows-latest (R release)
  - ubuntu-latest (R devel, release, oldrel-1)

## Resubmission

This is a resubmission addressing the additional issue flagged by CRAN (donttest).

The `set_cache_dir()` example previously used `~/educabR_cache`, which created a
directory in the user's home directory when `\donttest{}` examples were run.
Changed the example to use `tempdir()` instead, so no files are written outside
of session temporary directories.

## Notes

The package downloads data from INEP (Instituto Nacional de Estudos e Pesquisas Educacionais Anisio Teixeira), Brazil's national institute of educational studies and research. All data is publicly available.

Examples that download data are wrapped in `\donttest{}` to avoid timeouts during CRAN checks due to large file downloads from external servers.

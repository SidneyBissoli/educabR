# educabR 1.0.0

## Breaking changes

* **`get_ideb()` has a new signature**: `get_ideb(level, stage, metric, year, quiet)`.
  The old positional usage `get_ideb(year, level, stage)` still works with a
  deprecation warning, but the `year` parameter now filters IDEB editions
  instead of selecting which file to download.
* `get_ideb()` now returns data in tidy long format instead of wide format.
  Output columns depend on the `metric` parameter (`"indicador"`, `"aprovacao"`,
  `"nota"`, `"meta"`).
* `get_ideb()` now supports 5 geographic levels: `"escola"`, `"municipio"`,
  `"estado"`, `"regiao"`, and `"brasil"` (previously only escola and municipio).
* `get_ideb()` always downloads the most recent IDEB file available, which
  contains the full historical series. The `year` parameter filters editions.
* `get_ideb_series()` is deprecated. Use `get_ideb(level, stage, metric)` instead.
* `list_ideb_available()` now returns `level`, `stage`, and `metric` columns
  (previously returned `year`, `level`, `stage`).
* The `uf` parameter has been removed from `get_ideb()`. Filter the result
  with `dplyr::filter()` instead.

# educabR 0.9.0

## Breaking changes

* `available_years()` now dynamically discovers available years by querying
  data sources (HEAD requests for INEP, OData queries for FNDE). Results are
  cached per session. Falls back to a hardcoded list when offline.
* `available_years()` now accepts `"fundeb_enrollment"` as a separate dataset
  name. Previously, `"fundeb"` was shared between distribution and enrollment.
* Code columns (`CO_*`, `CD_*`) are now read as character instead of numeric
  across all datasets. This prevents loss of leading zeros in codes like
  municipality codes, course codes, and institution codes.

## Bug fixes

* Fixed `get_enade()` failing for 9 of 19 available years. INEP uses
  inconsistent URLs for ENADE: `_LGPD` suffix for 2012-2019, `.rar` format
  for 2022. Added hardcoded URL map (`enade_urls`) with all 19 correct URLs.
* Fixed `get_fundeb_enrollment()` accepting years with no data in the FNDE
  API. The API currently only has data for 2017-2018.
* Fixed encoding warning ("unable to translate MARCO") on Windows caused by
  Unicode cedilla in FUNDEB month name map.
* Fixed `clear_cache()` failing to delete files on Windows when they were
  memory-mapped by readr. Now deletes entire directories and warns about
  locked files.
* Fixed ZIP extraction fallback not triggering for ENADE 2017 ("Illegal byte
  sequence" error was not matched by the encoding detection pattern).

## New features

* Added `.rar` archive extraction support via 7-Zip. `find_7z()` searches
  common Windows install paths when `7z` is not in PATH.
* Added `strip_diacriticals()` internal helper for encoding-safe text matching.
* `read_inep_file()` now auto-detects code columns (`CO_*`, `CD_*`) from the
  file header and reads them as character. No user action required.
* `read_ideb_excel()` and `read_excel_safe()` (CPC/IGC) now convert code
  columns to character after reading.

# educabR 0.8.0

## New features

### FUNDEB (Fundo de Manutencao e Desenvolvimento da Educacao Basica)
* `get_fundeb_distribution()`: Download FUNDEB resource distribution data
  (years 2007-2026). Reads all sheets from STN Excel files and returns
  tidy long-format data with monthly transfer amounts by state, funding
  source, destination (states/municipalities), and table type
  (fundeb/adjustment).
* `get_fundeb_enrollment()`: Download FUNDEB enrollment data.
  Fetches from FNDE OData API with automatic pagination. Results cached as CSV.
* Filtering parameters for distribution: `uf`, `source` (FPE, FPM, ICMS, etc.),
  and `destination` ("uf" or "municipio").
* Data sources: Tesouro Transparente (`https://www.tesourotransparente.gov.br`)
  and FNDE (`https://www.fnde.gov.br`).

# educabR 0.7.0

## New features

### CAPES (Dados Abertos da Pos-Graduacao)
* `get_capes()`: Download CAPES graduate education data (years 2013-2024).
* Supports 5 data types: programs (`"programas"`), students (`"discentes"`),
  faculty (`"docentes"`), courses (`"cursos"`), and theses/dissertations catalog (`"catalogo"`).
* Uses CKAN API to dynamically discover download URLs (CAPES URLs contain UUIDs).
* Data source: CAPES Open Data Portal (`https://dadosabertos.capes.gov.br`).

# educabR 0.6.0

## New features

### CPC (Conceito Preliminar de Curso)
* `get_cpc()`: Download CPC data (years 2007-2019, 2021-2023; no 2020 edition).
* Quality indicator for undergraduate courses, part of SINAES.
* Files are in Excel format (xls/xlsx) — requires the `readxl` package.
* Hardcoded URL map due to completely inconsistent INEP naming patterns.

### IGC (Indice Geral de Cursos)
* `get_igc()`: Download IGC data (years 2007-2019, 2021-2023; no 2020 edition).
* Institutional quality indicator based on weighted CPC averages and CAPES scores.
* Files are in Excel format (xls/xlsx), except 2007 which is a 7z archive.
* Hardcoded URL map due to completely inconsistent INEP naming patterns.

### Shared utilities
* `read_excel_safe()`: Internal helper to read Excel files with error handling.

# educabR 0.5.0

## New features

### ENEM por Escola (ENEM by School)
* `get_enem_escola()`: Download ENEM results aggregated by school (2005-2015).
* Single bundled file covering all years. Discontinued after 2015.

### IDD (Indicador de Diferença entre os Desempenhos Observado e Esperado)
* `get_idd()`: Download IDD microdata (years 2014-2019, 2021-2023; no 2020 edition).
* Measures the value added by undergraduate courses to student performance.
* Handles both ZIP (2021+) and 7z (2014-2019) archive formats via new `extract_archive()` utility.
* Automatic delimiter detection and dash-to-NA cleaning.

# educabR 0.4.0

## New features

### ENCCEJA (Exame Nacional para Certificação de Competências de Jovens e Adultos)
* `get_encceja()`: Download ENCCEJA microdata (years 2014-2024).
* Automatic delimiter detection and dash-to-NA cleaning.

# educabR 0.3.0

## New features

### ENADE (Exame Nacional de Desempenho dos Estudantes)
* `get_enade()`: Download ENADE microdata.
* Automatic delimiter detection and dash-to-NA cleaning.

### Censo da Educação Superior (Higher Education Census)
* `get_censo_superior()`: Download Higher Education Census microdata (years 2009-2024).
* Supports multiple data types: institutions (`"ies"`), courses (`"cursos"`), students (`"alunos"`), and faculty (`"docentes"`).
* `list_censo_superior_files()`: List available files in a downloaded census.
* UF filtering via the `uf` parameter.

# educabR 0.2.0

## New features

### SAEB (Sistema de Avaliação da Educação Básica)
* `get_saeb()`: Download SAEB microdata (years 2011, 2013, 2015, 2017, 2019, 2021, 2023).
* Supports multiple data types: student results (`"aluno"`), school (`"escola"`), principal (`"diretor"`), and teacher (`"professor"`) questionnaires.
* Handles SAEB 2021 special case where INEP split downloads into elementary/high school and early childhood education files via the `level` parameter.

## Bug fixes

* Fixed encoding detection on Windows using `iconv()` instead of `validEnc()`.
* Fixed `"Latin-1"` encoding name to `"latin1"` for Windows codepage compatibility.
* Fixed ENEM 2024+ support: new `type` parameter for split files (`"participantes"`, `"resultados"`).
* Added SAS datetime parsing for Censo Escolar date columns (`dt_*`).
* Converted IDEB `vl_*` columns from character to numeric, handling `"-"`, `"ND"`, and comma decimals.

# educabR 0.1.2

## New features

* Added post-read data validation for all datasets. Errors on empty or corrupted files; warns when expected columns are missing (e.g., score columns for ENEM, UF columns for IDEB/Census) with actionable messages.
* Downloads now show estimated file size before starting (e.g., "downloading 2.3 GB from INEP...") via HTTP HEAD request, with graceful fallback if size is unavailable.
* `get_ideb_series()` now shows per-year progress indication (e.g., "processing IDEB 2017 (1/4)") and propagates the `quiet` parameter to inner `get_ideb()` calls.
* `get_enem_itens()` now has `keep_zip` parameter for consistency with `get_enem()` and `get_censo_escolar()`.

## Documentation

* Added English README (`README.md`) as default; Portuguese version renamed to `README.pt-br.md` with cross-links between both.
* Fixed `@param year` ranges in documentation to match `available_years()`:
  - `get_enem()` / `get_enem_itens()`: 2009-2023 -> 1998-2024
  - `get_censo_escolar()`: 2007-2024 -> 1995-2024
* Added `@family` tags to group related functions in help pages (ENEM, IDEB, School Census, cache).
* Added English vignette (`getting-started.Rmd`).
* Fixed Portuguese accents in `README.pt-br.md`.

## Tests

* Added tests for `enem_summary()`: statistics calculation, NA handling, grouping by variable, and error on missing score columns.
* Added tests for `validate_data()`: empty data, few columns, missing expected columns per dataset.

## CRAN

* Replaced `\donttest` with `\dontrun` in all examples per CRAN request.

# educabR 0.1.1

## Bug fixes

* Fixed `set_cache_dir()` example that created a directory in the user's home (`~/educabR_cache`) during CRAN checks. Now uses `tempdir()` in examples.

# educabR 0.1.0

First public release.

## New features

### IDEB
* `get_ideb()`: Download IDEB data (years 2017, 2019, 2021, 2023).
* `get_ideb_series()`: Download IDEB historical series across multiple years.
* `list_ideb_available()`: List available year/stage/level combinations.

### ENEM
* `get_enem()`: Download ENEM microdata (years 1998-2024).
* `get_enem_itens()`: Download ENEM item response data.
* `enem_summary()`: Calculate summary statistics for ENEM scores.

### School Census
* `get_censo_escolar()`: Download School Census microdata (years 1995-2024).
* `list_censo_files()`: List available files in a downloaded census.

### Cache management
* `set_cache_dir()`: Set custom cache directory.
* `get_cache_dir()`: Get current cache directory.
* `clear_cache()`: Clear cached files.
* `list_cache()`: List cached files with metadata.

### Utilities
* `available_years()`: Get available years for each dataset.

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
* `get_enade()`: Download ENADE microdata (years 2004-2024).
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

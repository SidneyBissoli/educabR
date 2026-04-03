# educabR

<!-- badges: start -->
[![CRAN status](https://www.r-pkg.org/badges/version/educabR)](https://CRAN.R-project.org/package=educabR)
[![CRAN downloads](https://cranlogs.r-pkg.org/badges/grand-total/educabR)](https://CRAN.R-project.org/package=educabR)
[![R-CMD-check](https://github.com/SidneyBissoli/educabR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/SidneyBissoli/educabR/actions/workflows/R-CMD-check.yaml)
[![codecov](https://codecov.io/gh/SidneyBissoli/educabR/branch/main/graph/badge.svg)](https://app.codecov.io/gh/SidneyBissoli/educabR)
[![Lifecycle: stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable)
<!-- badges: end -->

*[Leia em Português](https://github.com/SidneyBissoli/educabR/blob/main/README.pt-br.md)*

**educabR** provides easy access to Brazilian public education data from
INEP, FNDE, CAPES, and STN. With simple functions, you can download and
process data from 14 datasets covering basic education, higher education,
graduate programs, and education funding.

## Installation

Install from CRAN:

```r
install.packages("educabR")
```

Or install the development version from GitHub:

```r
# install.packages("remotes")
remotes::install_github("SidneyBissoli/educabR")
```

## Features

### Basic Education

| Dataset | Function | Available Years |
|---------|----------|-----------------|
| IDEB - Basic Education Development Index | `get_ideb()`, `get_ideb_series()` | 2017, 2019, 2021, 2023 |
| ENEM - National High School Exam | `get_enem()`, `get_enem_itens()` | 1998-2024 |
| School Census | `get_censo_escolar()` | 1995-2024 |
| SAEB - Basic Education Assessment System | `get_saeb()` | 2011-2023 (biennial) |
| ENCCEJA - Youth and Adult Certification Exam | `get_encceja()` | 2014-2024 |
| ENEM by School (discontinued) | `get_enem_escola()` | 2005-2015 |

### Higher Education

| Dataset | Function | Available Years |
|---------|----------|-----------------|
| Higher Education Census | `get_censo_superior()` | 2009-2024 |
| ENADE - National Student Performance Exam | `get_enade()` | 2004-2024 |
| IDD - Value-Added Indicator | `get_idd()` | 2014-2023 |
| CPC - Preliminary Course Concept | `get_cpc()` | 2007-2023 |
| IGC - General Courses Index | `get_igc()` | 2007-2023 |

### Graduate Education

| Dataset | Function | Available Years |
|---------|----------|-----------------|
| CAPES - Graduate programs, students, faculty | `get_capes()` | 2013-2024 |

### Education Funding

| Dataset | Function | Available Years |
|---------|----------|-----------------|
| FUNDEB - Resource distribution | `get_fundeb_distribution()` | 2007-2026 |
| FUNDEB - Enrollment counts | `get_fundeb_enrollment()` | 2007-2026 |

## Examples

### IDEB

```r
library(educabR)

# Download IDEB 2021 - Early elementary - Schools
ideb <- get_ideb(
  year  = 2021,
  stage = "anos_iniciais",
  level = "escola"
)

# Historical series
ideb_series <- get_ideb_series(
  years = c(2017, 2019, 2021, 2023),
  level = "municipio",
  stage = "anos_iniciais"
)
```

### ENEM

```r
# Download a sample for exploration
enem <- get_enem(year = 2023, n_max = 10000)

# Statistical summary
enem_summary(enem)

# Summary by sex
enem_summary(enem, by = "tp_sexo")
```

### School Census

```r
# Download School Census 2023 - filter by state
censo_sp <- get_censo_escolar(year = 2023, uf = "SP")
```

### Higher Education

```r
# Higher Education Census - institutions
ies <- get_censo_superior(2023, type = "ies")

# ENADE microdata
enade <- get_enade(2023, n_max = 10000)

# CAPES graduate programs
programas <- get_capes(2023, type = "programas")
```

### FUNDEB

```r
# Resource distribution by state
dist <- get_fundeb_distribution(2023, uf = "SP")

# Enrollment counts
mat <- get_fundeb_enrollment(2023, uf = "SP")
```

## Cache

The package uses local caching to avoid repeated downloads:

```r
# Set a permanent cache directory
set_cache_dir("~/educabR_data")

# List cached files
list_cache()

# Clear cache
clear_cache()
```

## Documentation

- [Package website](https://sidneybissoli.github.io/educabR/)
- [Getting started](https://sidneybissoli.github.io/educabR/articles/getting-started.html)
- [Basic education assessments](https://sidneybissoli.github.io/educabR/articles/basic-education-assessments.html)
- [Higher education](https://sidneybissoli.github.io/educabR/articles/higher-education.html)
- [Education funding](https://sidneybissoli.github.io/educabR/articles/education-funding.html)

## License

MIT

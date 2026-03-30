# educabR

*[Leia em
Português](https://sidneybissoli.github.io/educabR/README.pt-br.md)*

**educabR** provides easy access to Brazilian educational data from
INEP, including IDEB, ENEM, and School Census (Censo Escolar).

## Installation

You can install the development version of educabR from GitHub:

``` r
# install.packages("devtools")
devtools::install_github("SidneyBissoli/educabR")
```

## Features

| Dataset       | Function                                                                                        | Available Years        |
|---------------|-------------------------------------------------------------------------------------------------|------------------------|
| IDEB          | [`get_ideb()`](https://sidneybissoli.github.io/educabR/reference/get_ideb.md)                   | 2017, 2019, 2021, 2023 |
| ENEM          | [`get_enem()`](https://sidneybissoli.github.io/educabR/reference/get_enem.md)                   | 1998-2024              |
| School Census | [`get_censo_escolar()`](https://sidneybissoli.github.io/educabR/reference/get_censo_escolar.md) | 1995-2024              |

## Examples

### IDEB

``` r
library(educabR)

# Download IDEB 2021 - Early Years - Schools
ideb <- get_ideb(
  year  = 2021,
  stage = "anos_iniciais",
  level = "escola"
)
```

### ENEM

``` r
# Download ENEM 2023 microdata
enem <- get_enem(year = 2023)

# Statistical summary
enem_summary(enem)
```

### School Census

``` r
# Download School Census 2023
censo <- get_censo_escolar(year = 2023)
```

## Cache

The package uses local caching to avoid repeated downloads:

``` r
# List cached files
list_cache()

# Clear cache
clear_cache()

# Set custom cache directory
set_cache_dir("~/my_cache")
```

## Documentation

- [Package website](https://sidneybissoli.github.io/educabR/)
- [Getting started
  vignette](https://sidneybissoli.github.io/educabR/articles/introducao-educabr.html)

## License

MIT

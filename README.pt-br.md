# educabR

<!-- badges: start -->
[![R-CMD-check](https://github.com/SidneyBissoli/educabR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/SidneyBissoli/educabR/actions/workflows/R-CMD-check.yaml)
[![codecov](https://codecov.io/gh/SidneyBissoli/educabR/branch/main/graph/badge.svg)](https://app.codecov.io/gh/SidneyBissoli/educabR)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

*[Read in English](README.md)*

O **educabR** facilita o acesso a dados educacionais brasileiros do INEP, incluindo IDEB, ENEM e Censo Escolar.

## Instalação

Você pode instalar a versão de desenvolvimento do educabR pelo GitHub:

```r
# install.packages("devtools")
devtools::install_github("SidneyBissoli/educabR")
```

## Funcionalidades

| Dataset | Função | Anos disponíveis |
|---------|--------|------------------|
| IDEB | `get_ideb()` | 2017, 2019, 2021, 2023 |
| ENEM | `get_enem()` | 1998-2024 |
| Censo Escolar | `get_censo_escolar()` | 1995-2024 |

## Exemplos

### IDEB

```r
library(educabR)

# Baixar IDEB 2021 - Anos Iniciais - Escolas
ideb <- get_ideb(
  year  = 2021,
  stage = "anos_iniciais",
  level = "escola"
)
```

### ENEM

```r
# Baixar microdados do ENEM 2023
enem <- get_enem(year = 2023)

# Resumo estatístico
enem_summary(enem)
```

### Censo Escolar

```r
# Baixar Censo Escolar 2023
censo <- get_censo_escolar(year = 2023)
```

## Cache

O pacote usa cache local para evitar downloads repetidos:
```r
# Ver arquivos em cache
list_cache()

# Limpar cache
clear_cache()

# Definir diretório de cache personalizado
set_cache_dir("~/meu_cache")
```

## Documentação

- [Site do pacote](https://sidneybissoli.github.io/educabR/)
- [Vignette de introdução](https://sidneybissoli.github.io/educabR/articles/introducao-educabr.html)

## Licença

MIT

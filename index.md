# educabR

O **educabR** facilita o acesso a dados educacionais brasileiros do
INEP, incluindo IDEB, ENEM e Censo Escolar.

## Instalacao

Voce pode instalar a versao de desenvolvimento do educabR pelo GitHub:

``` r
# install.packages("devtools")
devtools::install_github("SidneyBissoli/educabR")
```

## Funcionalidades

| Dataset       | Funcao                                                                                          | Anos disponiveis       |
|---------------|-------------------------------------------------------------------------------------------------|------------------------|
| IDEB          | [`get_ideb()`](https://sidneybissoli.github.io/educabR/reference/get_ideb.md)                   | 2017, 2019, 2021, 2023 |
| ENEM          | [`get_enem()`](https://sidneybissoli.github.io/educabR/reference/get_enem.md)                   | 1998-2024              |
| Censo Escolar | [`get_censo_escolar()`](https://sidneybissoli.github.io/educabR/reference/get_censo_escolar.md) | 1995-2024              |

## Exemplos

### IDEB

``` r
library(educabR)

# Baixar IDEB 2021 - Anos Iniciais - Escolas
ideb <- get_ideb(
  year = 2021,
  stage = "anos_iniciais",
  level = "escola"
)
```

### ENEM

``` r
# Baixar microdados do ENEM 2023
enem <- get_enem(year = 2023)

# Resumo estatistico
enem_summary(enem)
```

### Censo Escolar

``` r
# Baixar Censo Escolar 2023
censo <- get_censo_escolar(year = 2023)
```

## Cache

O pacote usa cache local para evitar downloads repetidos:

``` r
# Ver arquivos em cache
list_cache()

# Limpar cache
clear_cache()

# Definir diretorio de cache personalizado
set_cache_dir("~/meu_cache")
```

## Documentacao

- [Site do pacote](https://sidneybissoli.github.io/educabR/)
- [Vignette de
  introducao](https://sidneybissoli.github.io/educabR/articles/introducao-educabr.html)

## Licenca

MIT

# Changelog

## educabR 0.1.0

Primeira versao publica do pacote.

### Novas funcionalidades

#### IDEB

- [`get_ideb()`](https://sidneybissoli.github.io/educabR/reference/get_ideb.md):
  Baixa dados do IDEB (anos 2017, 2019, 2021, 2023)
- [`get_ideb_series()`](https://sidneybissoli.github.io/educabR/reference/get_ideb_series.md):
  Baixa serie historica do IDEB
- [`list_ideb_available()`](https://sidneybissoli.github.io/educabR/reference/list_ideb_available.md):
  Lista combinacoes disponiveis de ano/etapa/nivel

#### ENEM

- [`get_enem()`](https://sidneybissoli.github.io/educabR/reference/get_enem.md):
  Baixa microdados do ENEM (anos 1998-2024)
- [`get_enem_itens()`](https://sidneybissoli.github.io/educabR/reference/get_enem_itens.md):
  Baixa dados dos itens das provas
- [`enem_summary()`](https://sidneybissoli.github.io/educabR/reference/enem_summary.md):
  Gera resumo estatistico dos dados do ENEM

#### Censo Escolar

- [`get_censo_escolar()`](https://sidneybissoli.github.io/educabR/reference/get_censo_escolar.md):
  Baixa microdados do Censo Escolar (anos 1995-2024)
- [`list_censo_files()`](https://sidneybissoli.github.io/educabR/reference/list_censo_files.md):
  Lista arquivos disponiveis no Censo

#### Gerenciamento de cache

- [`set_cache_dir()`](https://sidneybissoli.github.io/educabR/reference/set_cache_dir.md):
  Define diretorio de cache personalizado
- [`get_cache_dir()`](https://sidneybissoli.github.io/educabR/reference/get_cache_dir.md):
  Retorna diretorio de cache atual
- [`clear_cache()`](https://sidneybissoli.github.io/educabR/reference/clear_cache.md):
  Limpa arquivos em cache
- [`list_cache()`](https://sidneybissoli.github.io/educabR/reference/list_cache.md):
  Lista arquivos em cache

#### Utilitarios

- [`available_years()`](https://sidneybissoli.github.io/educabR/reference/available_years.md):
  Retorna anos disponiveis para cada dataset

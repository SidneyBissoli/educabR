# educabR 0.1.1

## Correcoes

* Corrigido exemplo de `set_cache_dir()` que criava diretorio no home do usuario (`~/educabR_cache`) durante verificacoes do CRAN. Agora usa `tempdir()` nos exemplos.

# educabR 0.1.0

Primeira versao publica do pacote.

## Novas funcionalidades

### IDEB
* `get_ideb()`: Baixa dados do IDEB (anos 2017, 2019, 2021, 2023)
* `get_ideb_series()`: Baixa serie historica do IDEB
* `list_ideb_available()`: Lista combinacoes disponiveis de ano/etapa/nivel

### ENEM
* `get_enem()`: Baixa microdados do ENEM (anos 1998-2024)
* `get_enem_itens()`: Baixa dados dos itens das provas
* `enem_summary()`: Gera resumo estatistico dos dados do ENEM

### Censo Escolar
* `get_censo_escolar()`: Baixa microdados do Censo Escolar (anos 1995-2024)
* `list_censo_files()`: Lista arquivos disponiveis no Censo

### Gerenciamento de cache
* `set_cache_dir()`: Define diretorio de cache personalizado
* `get_cache_dir()`: Retorna diretorio de cache atual
* `clear_cache()`: Limpa arquivos em cache
* `list_cache()`: Lista arquivos em cache

### Utilitarios
* `available_years()`: Retorna anos disponiveis para cada dataset

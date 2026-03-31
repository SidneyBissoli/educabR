# Plano de Expansão do educabR

## Contexto

O pacote educabR atualmente suporta 3 datasets do INEP: Censo Escolar,
ENEM e IDEB. O objetivo é expandir para cobrir mais fontes de dados
educacionais brasileiros, mantendo compatibilidade com o CRAN e seguindo
os padrões já estabelecidos no pacote.

A arquitetura atual é bem modular: cada dataset tem seu próprio
`R/get-{dataset}.R`, e as utilidades compartilhadas (`utils-download.R`,
`utils-cache.R`, `utils-validation.R`) são reutilizáveis. Não serão
necessárias novas dependências.

------------------------------------------------------------------------

## Fases de Implementação

### Fase 1: SAEB — Versão 0.2.0

**Por quê primeiro**: O SAEB é o componente de aprendizagem do IDEB
(complementa diretamente os dados já existentes). Alta demanda da
comunidade acadêmica.

**Criar:** - `R/get-saeb.R` -
`get_saeb(year, type = c("aluno", "escola", "diretor", "professor"), n_max, keep_zip, quiet)` -
`find_saeb_file(exdir, year, type)` — internal - Anos:
`c(2011, 2013, 2015, 2017, 2019, 2021, 2023)` (biennial) - URL:
`{base}/microdados/microdados_saeb_{year}.zip` (verificar antes) -
`tests/testthat/test-saeb.R` — validação de anos, URLs, dados sintéticos

**Modificar:** - `R/utils-download.R` — adicionar `"saeb"` em
[`build_inep_url()`](https://sidneybissoli.github.io/educabR/reference/build_inep_url.md)
e
[`available_years()`](https://sidneybissoli.github.io/educabR/reference/available_years.md) -
`R/utils-validation.R` — adicionar `validate_saeb()` e registrar no
`switch` de
[`validate_data()`](https://sidneybissoli.github.io/educabR/reference/validate_data.md) -
`DESCRIPTION` — bump para 0.2.0 - `NEWS.md` — documentar SAEB -
`R/educabR-package.R` — mencionar SAEB na documentação do pacote

------------------------------------------------------------------------

### Fase 2: Censo da Educação Superior — Versão 0.3.0

**Por quê**: Expande o pacote para educação superior. Dataset anual com
múltiplas tabelas.

**Criar:** - `R/get-censo-superior.R` -
`get_censo_superior(year, type = c("ies", "cursos", "alunos", "docentes"), uf, n_max, keep_zip, quiet)` -
`find_censo_superior_file(exdir, year, type)` — internal -
`list_censo_superior_files(year)` — exported - Anos: 2009–2024 - URL:
`{base}/microdados/microdados_censo_da_educacao_superior_{year}.zip`
(verificar) - `tests/testthat/test-censo-superior.R`

**Modificar:** mesmos arquivos utilitários + DESCRIPTION + NEWS.md

------------------------------------------------------------------------

### Fase 3: ENADE — Versão 0.3.0 (bundled com Fase 2)

**Por quê**: Completa o ecossistema de educação superior. Estrutura
simples (ZIP+CSV único), implementação rápida. Submeter junto com Fase 2
para evitar submissões frequentes ao CRAN.

**Criar:** - `R/get-enade.R` -
`get_enade(year, n_max, keep_zip, quiet)` -
`find_enade_file(exdir, year)` — internal - `enade_summary(data, by)` —
opcional, análogo a
[`enem_summary()`](https://sidneybissoli.github.io/educabR/reference/enem_summary.md) -
Anos: 2004–2024 - URL: `{base}/microdados/microdados_enade_{year}.zip`
(verificar) - `tests/testthat/test-enade.R`

**Modificar:** mesmos arquivos utilitários + DESCRIPTION + NEWS.md

------------------------------------------------------------------------

### Fase 4: ENCCEJA — Versão 0.4.0

**Por quê**: Cobre educação de jovens e adultos, público distinto.

**Criar:** - `R/get-encceja.R` -
`get_encceja(year, n_max, keep_zip, quiet)` -
`find_encceja_file(exdir, year)` — internal - Anos: 2014–2024 - URL:
`{base}/microdados/microdados_encceja_{year}.zip` (verificar) -
`tests/testthat/test-encceja.R`

**Modificar:** mesmos arquivos utilitários + DESCRIPTION + NEWS.md

------------------------------------------------------------------------

## Padrão para cada novo dataset

Para cada dataset, os passos são idênticos:

1.  Verificar URL real no navegador (HEAD request ou download manual)
2.  Baixar ZIP de 1 ano e inspecionar estrutura interna (nomes dos CSVs)
3.  Criar `R/get-{dataset}.R` seguindo o template de
    [`get_enem()`](https://sidneybissoli.github.io/educabR/reference/get_enem.md)
4.  Adicionar ao
    [`build_inep_url()`](https://sidneybissoli.github.io/educabR/reference/build_inep_url.md)
    e
    [`available_years()`](https://sidneybissoli.github.io/educabR/reference/available_years.md)
    em `utils-download.R`
5.  Adicionar validação em `utils-validation.R`
6.  Criar testes (sem downloads reais — dados sintéticos)
7.  Rodar `devtools::document()` para gerar man pages
8.  Rodar `devtools::check()` localmente
9.  Atualizar NEWS.md, DESCRIPTION, vignettes
10. Commit, push, verificar CI

------------------------------------------------------------------------

## Estratégia de submissão ao CRAN

| Versão | Conteúdo                         | Timing                      |
|--------|----------------------------------|-----------------------------|
| 0.2.0  | SAEB                             | Após implementação e testes |
| 0.3.0  | Censo Superior + ENADE (bundled) | Mín. 1-2 meses após 0.2.0   |
| 0.4.0  | ENCCEJA                          | Mín. 1-2 meses após 0.3.0   |

**Checklist CRAN por submissão:** - Exemplos com `\dontrun{}` - Cache em
[`tempdir()`](https://rdrr.io/r/base/tempfile.html) por padrão -
`R CMD check`: 0 errors, 0 warnings, 0 notes - `cran-comments.md`
atualizado - Nenhuma dependência nova

------------------------------------------------------------------------

## Verificação

Para cada dataset implementado: 1. `devtools::load_all()` +
`get_dataset(year, n_max = 100)` com cache limpo 2. Verificar encoding
(acentos corretos) 3. Verificar tipos de colunas (numéricas como
`<dbl>`, não `<chr>`) 4. Testar com pelo menos 2 anos diferentes (mais
antigo e mais recente) 5. `devtools::check()` sem erros/warnings 6. CI
verde no GitHub Actions

------------------------------------------------------------------------

## Arquivos críticos

- `R/utils-download.R` (linhas ~197-244) —
  [`build_inep_url()`](https://sidneybissoli.github.io/educabR/reference/build_inep_url.md)
  e
  [`available_years()`](https://sidneybissoli.github.io/educabR/reference/available_years.md)
- `R/utils-validation.R` —
  [`validate_data()`](https://sidneybissoli.github.io/educabR/reference/validate_data.md)
  switch
- `R/get-enem.R` — template principal para novos datasets
- `DESCRIPTION` — versão e descrição
- `NEWS.md` — changelog

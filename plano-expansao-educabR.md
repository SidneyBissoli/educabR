# Plano de Expansão do educabR

## Contexto

O pacote educabR atualmente suporta 7 datasets do INEP: Censo Escolar,
ENEM, IDEB, SAEB, Censo da Educação Superior, ENADE e ENCCEJA. O
objetivo é expandir para cobrir mais fontes de dados educacionais
brasileiros, mantendo compatibilidade com o CRAN e seguindo os padrões
já estabelecidos no pacote.

A arquitetura atual é bem modular: cada dataset tem seu próprio
`R/get-{dataset}.R`, e as utilidades compartilhadas (`utils-download.R`,
`utils-cache.R`, `utils-validation.R`) são reutilizáveis. Não serão
necessárias novas dependências.

------------------------------------------------------------------------

## Fases concluídas

### Fase 1: SAEB — Versão 0.2.0 ✓

- `get_saeb(year, type, level, n_max, keep_zip, quiet)`
- Tipos: aluno, escola, diretor, professor
- Anos: 2011, 2013, 2015, 2017, 2019, 2021, 2023

### Fase 2: Censo da Educação Superior — Versão 0.3.0 ✓

- `get_censo_superior(year, type, uf, n_max, keep_zip, quiet)`
- `list_censo_superior_files(year)`
- Tipos: ies, cursos, alunos, docentes
- Anos: 2009–2024

### Fase 3: ENADE — Versão 0.3.0 ✓

- `get_enade(year, n_max, keep_zip, quiet)`
- Anos: 2004–2024

### Fase 4: ENCCEJA — Versão 0.4.0 ✓

- `get_encceja(year, n_max, keep_zip, quiet)`
- Anos: 2014–2024

------------------------------------------------------------------------

## Fases futuras — INEP

### Fase 5: IDD — Versão 0.5.0

**Prioridade:** Alta  
**Por quê**: Complementa diretamente o ENADE — mede o valor agregado
pelo curso de graduação (diferença entre desempenho no ENADE e nota de
entrada via ENEM). Mesmo padrão ZIP+CSV do INEP.

**Criar:**  
- `R/get-idd.R`  
- `get_idd(year, n_max, keep_zip, quiet)`  
- `find_idd_file(exdir, year)` — internal  
- Anos: 2014–2023  
- URL: `{base}/microdados/microdados_idd_{year}.zip` (verificar)  
- `tests/testthat/test-idd.R`

**Modificar:** `utils-download.R`, `utils-validation.R`, `_pkgdown.yml`,
`DESCRIPTION`, `NEWS.md`, `educabR-package.R`

------------------------------------------------------------------------

### Fase 6: ENEM por Escola — Versão 0.5.0 (bundled com Fase 5)

**Prioridade:** Alta  
**Por quê**: Dados de desempenho no ENEM agregados por escola. Altíssima
demanda de pesquisadores, jornalistas e gestores educacionais.

**Criar:**  
- `R/get-enem-escola.R`  
- `get_enem_escola(n_max, keep_zip, quiet)` — pacote único 2005-2015  
- `find_enem_escola_file(exdir)` — internal  
- Anos: 2005–2015 (arquivo único)  
- URL:
`{base}/microdados/enem_por_escola/2005_a_2015/microdados_enem_por_escola.zip`
(verificar)  
- `tests/testthat/test-enem-escola.R`

**Modificar:** mesmos arquivos utilitários + DESCRIPTION + NEWS.md

------------------------------------------------------------------------

### Fase 7: CPC/IGC (Indicadores de Qualidade da Educação Superior) — Versão 0.5.0 (bundled com Fases 5-6)

**Prioridade:** Alta  
**Por quê**: Conceito Preliminar de Curso (CPC) e Índice Geral de Cursos
(IGC) são os indicadores oficiais de qualidade do ensino superior.
Completa o ecossistema ENADE + IDD + CPC/IGC.

**Criar:**  
- `R/get-cpc.R`  
- `get_cpc(year, n_max, keep_zip, quiet)`  
- Anos: 2014–2023  
- `R/get-igc.R`  
- `get_igc(year, n_max, keep_zip, quiet)`  
- Anos: 2014–2023  
- Testes correspondentes

**Modificar:** mesmos arquivos utilitários + DESCRIPTION + NEWS.md

------------------------------------------------------------------------

## Fases futuras — Outras fontes

### Fase 8: CAPES (Dados Abertos da Pós-Graduação) — Versão 0.6.0

**Prioridade:** Alta  
**Por quê**: Expande o pacote para pós-graduação stricto sensu. Dados
anuais em CSV via portal CKAN da CAPES.

**Criar:**  
- `R/get-capes.R`  
-
`get_capes(year, type = c("programas", "discentes", "docentes", "producao"), n_max, quiet)`  
- Anos: 2017–2024  
- URL: `https://dadosabertos.capes.gov.br/dataset/` (verificar
estrutura)  
- `tests/testthat/test-capes.R`

**Nota:** Requer adaptação da infraestrutura de download (CAPES usa
portal CKAN, não o padrão INEP). Pode necessitar funções de download
específicas.

------------------------------------------------------------------------

### Fase 9: FUNDEB — Versão 0.6.0 (bundled com Fase 8)

**Prioridade:** Alta  
**Por quê**: Principal mecanismo de financiamento da educação básica.
Dados de distribuição de recursos por município/estado.

**Criar:**  
- `R/get-fundeb.R`  
- `get_fundeb(year, n_max, quiet)`  
- Anos: 2010–2024  
- URL: via dados.gov.br/FNDE (verificar)  
- `tests/testthat/test-fundeb.R`

------------------------------------------------------------------------

### Fase 10: FIES — Versão 0.6.0 (bundled com Fases 8-9)

**Prioridade:** Alta  
**Por quê**: Complementa o Censo Superior com dados de financiamento
estudantil.

**Criar:**  
- `R/get-fies.R`  
- `get_fies(year, n_max, quiet)`  
- Anos: 2010–2024  
- URL: via dados.gov.br/FNDE (verificar)  
- `tests/testthat/test-fies.R`

------------------------------------------------------------------------

## Outras fontes mapeadas (para avaliação futura)

### Fontes do INEP (prioridade média/baixa)

| Dataset                  | Conteúdo                                         |    Anos    | Prioridade |
|--------------------------|--------------------------------------------------|:----------:|:----------:|
| ENAMED                   | Avaliação de cursos de Medicina                  |    2025    |   Média    |
| TALIS                    | Pesquisa OCDE sobre professores                  | 2018, 2024 |   Média    |
| Indicadores Educacionais | Taxas de rendimento, distorção, INSE, etc.       |   Vários   |   Média    |
| ANA                      | Avaliação da Alfabetização (absorvida pelo SAEB) | 2014, 2016 |   Baixa    |
| ENC-Provão               | Predecessor do ENADE                             | 1997-2003  |   Baixa    |
| Sinopses Estatísticas    | Tabelas agregadas                                |   Vários   |   Baixa    |

### Outras fontes governamentais

| Fonte | Dataset                       | Conteúdo                         |   Anos    | Prioridade | Viabilidade                       |
|:-----:|-------------------------------|----------------------------------|:---------:|:----------:|-----------------------------------|
|  MEC  | Plataforma Nilo Peçanha       | Rede Federal (IFs/CEFETs)        | 2017-2024 |   Média    | Média — CSV/JSON                  |
|  MEC  | e-MEC                         | Cadastro de IES e cursos         | Contínuo  |   Média    | Média — CSV                       |
| IBGE  | PNAD Contínua (Educação)      | Escolaridade por domicílio       | 2012-2024 |   Média    | Média — pacote `PNADcIBGE` existe |
| IBGE  | Censo Demográfico             | Escolaridade da população        | 1991-2022 |   Média    | Média — formato complexo          |
| IBGE  | SIDRA                         | Tabelas agregadas educacionais   |  Décadas  |   Baixa    | Média — pacote `sidrar` existe    |
| CNPq  | Bolsas e Auxílios             | Bolsas por área/instituição      | 2001-2024 |   Média    | Média — formato XML               |
| IPEA  | Ipeadata                      | Séries históricas educacionais   |  Décadas  |   Baixa    | Baixa — pacote `ipeadatar` existe |
| IPEA  | Atlas Brasil (IDH-M Educação) | IDH municipal educação           | 1991-2010 |   Baixa    | Média — CSV                       |
|  MTE  | RAIS                          | Emprego formal com escolaridade  | 1985-2023 |   Baixa    | Média — FTP, arquivos grandes     |
| FNDE  | PNAE (Alimentação Escolar)    | Alunos atendidos, transferências | 2010-2024 |   Média    | Alta — CSV                        |
| FNDE  | PDDE (Dinheiro na Escola)     | Execução financeira              | 2010-2024 |   Média    | Alta — CSV                        |
| FNDE  | PNLD (Livro Didático)         | Distribuição de livros           | 2010-2024 |   Baixa    | Alta — CSV                        |
| FNDE  | PNATE (Transporte Escolar)    | Repasses para transporte         | 2010-2024 |   Baixa    | Alta — CSV                        |
|  CGU  | Portal da Transparência       | Orçamento federal em Educação    | 2013-2024 |   Baixa    | Alta — CSV                        |

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
9.  Atualizar NEWS.md, DESCRIPTION, `_pkgdown.yml`, vignettes
10. Commit, push, verificar CI

------------------------------------------------------------------------

## Estratégia de submissão ao CRAN

| Versão | Conteúdo                                  | Timing                    |
|:------:|-------------------------------------------|---------------------------|
| 0.4.0  | ENCCEJA                                   | Próxima submissão         |
| 0.5.0  | IDD + ENEM por Escola + CPC/IGC (bundled) | Mín. 1-2 meses após 0.4.0 |
| 0.6.0  | CAPES + FUNDEB + FIES (bundled)           | Mín. 1-2 meses após 0.5.0 |

**Checklist CRAN por submissão:**  
- Exemplos com `\dontrun{}`  
- Cache em [`tempdir()`](https://rdrr.io/r/base/tempfile.html) por
padrão  
- `R CMD check`: 0 errors, 0 warnings, 0 notes  
- `cran-comments.md` atualizado  
- Nenhuma dependência nova

------------------------------------------------------------------------

## Verificação

Para cada dataset implementado:  
1. `devtools::load_all()` + `get_dataset(year, n_max = 100)` com cache
limpo  
2. Verificar encoding (acentos corretos)  
3. Verificar tipos de colunas (numéricas como `<dbl>`, não `<chr>`)  
4. Testar com pelo menos 2 anos diferentes (mais antigo e mais
recente)  
5. `devtools::check()` sem erros/warnings  
6. CI verde no GitHub Actions

------------------------------------------------------------------------

## Arquivos críticos

- `R/utils-download.R` (linhas ~197-270) —
  [`build_inep_url()`](https://sidneybissoli.github.io/educabR/reference/build_inep_url.md)
  e
  [`available_years()`](https://sidneybissoli.github.io/educabR/reference/available_years.md)
- `R/utils-validation.R` —
  [`validate_data()`](https://sidneybissoli.github.io/educabR/reference/validate_data.md)
  switch
- `R/get-enem.R` — template principal para novos datasets
- `DESCRIPTION` — versão e descrição
- `NEWS.md` — changelog
- `_pkgdown.yml` — índice de referência do site

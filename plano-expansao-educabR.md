# Plano de Expansão do educabR

## Contexto

O pacote educabR atualmente suporta 12 datasets: Censo Escolar, ENEM, IDEB, SAEB, Censo da Educação Superior, ENADE, ENCCEJA, IDD, ENEM por Escola, CPC, IGC (todos do INEP) e CAPES (dados abertos da pós-graduação). O objetivo é expandir para cobrir mais fontes de dados educacionais brasileiros, mantendo compatibilidade com o CRAN e seguindo os padrões já estabelecidos no pacote.

A arquitetura atual é bem modular: cada dataset tem seu próprio `R/get-{dataset}.R`, e as utilidades compartilhadas (`utils-download.R`, `utils-cache.R`, `utils-validation.R`) são reutilizáveis. CPC e IGC usam `readxl` (em Suggests) para ler arquivos Excel.

---

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

### Fase 5: IDD — Versão 0.5.0 ✓

- `get_idd(year, n_max, keep_zip, quiet)`
- Anos: 2014–2019, 2021–2023 (sem edição 2020)
- URL com capitalização: `microdados_IDD_{year}.{zip|7z}`
- Anos 2014–2019 usam formato 7z (via `extract_archive()`)

### Fase 6: ENEM por Escola — Versão 0.5.0 ✓

- `get_enem_escola(n_max, keep_zip, quiet)`
- Anos: 2005–2015 (arquivo único, descontinuado)
- URL: `{base}/microdados/enem_por_escola/2005_a_2015/microdados_enem_por_escola.zip`

### Fase 7: CPC/IGC — Versão 0.6.0 ✓

- `get_cpc(year, n_max, keep_file, quiet)`
- `get_igc(year, n_max, keep_file, quiet)`
- Anos: 2007–2019, 2021–2023 (sem edição 2020)
- Arquivos Excel (xls/xlsx) — requer `readxl` (em Suggests)
- URLs completamente irregulares — lookup table hardcoded por ano
- IGC 2007 é arquivo 7z contendo Excel
- `read_excel_safe()`: helper para leitura de Excel com tratamento de erros
- `convert_faixa_columns()`: converte colunas `_faixa` de character para numeric
- `standardize_names()` corrigido para transliterar acentos via `iconv()`

---

### Fase 8: CAPES (Dados Abertos da Pós-Graduação) — Versão 0.7.0 ✓

- `get_capes(year, type, n_max, keep_file, quiet)`
- Tipos: programas, discentes, docentes, cursos, catalogo
- Anos: 2013–2024
- Fonte: Portal de Dados Abertos da CAPES (CKAN), não INEP
- `discover_capes_url()`: descobre URLs via API CKAN (URLs contêm UUIDs)
- `parse_sas_dates()` ampliado para capturar colunas `dh_*` além de `dt_*`

---

## Fases futuras — Outras fontes

### Fase 9: FUNDEB — Versão 0.8.0

**Prioridade:** Alta  
**Por quê**: Principal mecanismo de financiamento da educação básica. Dados de distribuição de recursos por município/estado.

**Criar:**  
- `R/get-fundeb.R`  
  - `get_fundeb(year, n_max, quiet)`  
  - Anos: 2010–2024  
  - URL: via dados.gov.br/FNDE (verificar)  
- `tests/testthat/test-fundeb.R`  

---

### Fase 10: FIES — Versão 0.8.0 (bundled com Fase 9)

**Prioridade:** Alta  
**Por quê**: Complementa o Censo Superior com dados de financiamento estudantil.

**Criar:**  
- `R/get-fies.R`  
  - `get_fies(year, n_max, quiet)`  
  - Anos: 2010–2024  
  - URL: via dados.gov.br/FNDE (verificar)  
- `tests/testthat/test-fies.R`  

---

## Outras fontes mapeadas (para avaliação futura)

### Fontes do INEP (prioridade média/baixa)

| Dataset | Conteúdo | Anos | Prioridade |
|---------|----------|:----:|:----------:|
| ENAMED | Avaliação de cursos de Medicina | 2025 | Média |
| TALIS | Pesquisa OCDE sobre professores | 2018, 2024 | Média |
| Indicadores Educacionais | Taxas de rendimento, distorção, INSE, etc. | Vários | Média |
| ANA | Avaliação da Alfabetização (absorvida pelo SAEB) | 2014, 2016 | Baixa |
| ENC-Provão | Predecessor do ENADE | 1997-2003 | Baixa |
| Sinopses Estatísticas | Tabelas agregadas | Vários | Baixa |

### Outras fontes governamentais

| Fonte | Dataset | Conteúdo | Anos | Prioridade | Viabilidade |
|:-----:|---------|----------|:----:|:----------:|-------------|
| MEC | Plataforma Nilo Peçanha | Rede Federal (IFs/CEFETs) | 2017-2024 | Média | Média — CSV/JSON |
| MEC | e-MEC | Cadastro de IES e cursos | Contínuo | Média | Média — CSV |
| IBGE | PNAD Contínua (Educação) | Escolaridade por domicílio | 2012-2024 | Média | Média — pacote `PNADcIBGE` existe |
| IBGE | Censo Demográfico | Escolaridade da população | 1991-2022 | Média | Média — formato complexo |
| IBGE | SIDRA | Tabelas agregadas educacionais | Décadas | Baixa | Média — pacote `sidrar` existe |
| CNPq | Bolsas e Auxílios | Bolsas por área/instituição | 2001-2024 | Média | Média — formato XML |
| IPEA | Ipeadata | Séries históricas educacionais | Décadas | Baixa | Baixa — pacote `ipeadatar` existe |
| IPEA | Atlas Brasil (IDH-M Educação) | IDH municipal educação | 1991-2010 | Baixa | Média — CSV |
| MTE | RAIS | Emprego formal com escolaridade | 1985-2023 | Baixa | Média — FTP, arquivos grandes |
| FNDE | PNAE (Alimentação Escolar) | Alunos atendidos, transferências | 2010-2024 | Média | Alta — CSV |
| FNDE | PDDE (Dinheiro na Escola) | Execução financeira | 2010-2024 | Média | Alta — CSV |
| FNDE | PNLD (Livro Didático) | Distribuição de livros | 2010-2024 | Baixa | Alta — CSV |
| FNDE | PNATE (Transporte Escolar) | Repasses para transporte | 2010-2024 | Baixa | Alta — CSV |
| CGU | Portal da Transparência | Orçamento federal em Educação | 2013-2024 | Baixa | Alta — CSV |

---

## Padrão para cada novo dataset

Para cada dataset, os passos são idênticos:

1. Verificar URL real no navegador (HEAD request ou download manual)
2. Baixar ZIP de 1 ano e inspecionar estrutura interna (nomes dos CSVs)
3. Criar `R/get-{dataset}.R` seguindo o template de `get_enem()`
4. Adicionar ao `build_inep_url()` e `available_years()` em `utils-download.R`
5. Adicionar validação em `utils-validation.R`
6. Criar testes (sem downloads reais — dados sintéticos)
7. Rodar `devtools::document()` para gerar man pages
8. Rodar `devtools::check()` localmente
9. Atualizar NEWS.md, DESCRIPTION, `_pkgdown.yml`, vignettes
10. Commit, push, verificar CI

---

## Estratégia de submissão ao CRAN

| Versão | Conteúdo | Timing |
|:------:|----------|--------|
| 0.4.0 | ENCCEJA | Concluída |
| 0.5.0 | IDD + ENEM por Escola | Concluída |
| 0.6.0 | CPC + IGC | Concluída |
| 0.7.0 | CAPES | Concluída |
| 0.8.0 | FUNDEB + FIES (bundled) | Mín. 1-2 meses após 0.7.0 |

**Checklist CRAN por submissão:**  
- Exemplos com `\dontrun{}`  
- Cache em `tempdir()` por padrão  
- `R CMD check`: 0 errors, 0 warnings, 0 notes  
- `cran-comments.md` atualizado  
- Nenhuma dependência nova obrigatória (readxl em Suggests para CPC/IGC)  

---

## Verificação

Para cada dataset implementado:  
1. `devtools::load_all()` + `get_dataset(year, n_max = 100)` com cache limpo  
2. Verificar encoding (acentos corretos)  
3. Verificar tipos de colunas (numéricas como `<dbl>`, não `<chr>`)  
4. Testar com pelo menos 2 anos diferentes (mais antigo e mais recente)  
5. `devtools::check()` sem erros/warnings  
6. CI verde no GitHub Actions  

---

## Arquivos críticos

- `R/utils-download.R` (linhas ~197-270) — `build_inep_url()` e `available_years()`
- `R/utils-validation.R` — `validate_data()` switch
- `R/get-enem.R` — template principal para novos datasets
- `DESCRIPTION` — versão e descrição
- `NEWS.md` — changelog
- `_pkgdown.yml` — índice de referência do site

# Introducao ao educabR

O pacote **educabR** facilita o acesso aos dados educacionais públicos
brasileiros disponibilizados pelo INEP (Instituto Nacional de Estudos e
Pesquisas Educacionais Anísio Teixeira). Com funções simples, você pode
baixar e processar dados do: - **IDEB** - Índice de Desenvolvimento da
Educação Básica - **ENEM** - Exame Nacional do Ensino Médio - **Censo
Escolar** - Censo da Educação Básica

## Instalação

``` r
# Instalar do GitHub (versão de desenvolvimento)
# install.packages("remotes")
remotes::install_github("SidneyBissoli/educabR")
```

``` r
library(educabR)
library(dplyr)
library(ggplot2)
```

## Configurando o Cache

O educabR faz cache dos arquivos baixados para evitar downloads
repetidos. Por padrão, usa um diretório temporário. Para persistir os
dados entre sessões:

``` r
# Ver diretório de cache atual
get_cache_dir()

# Configurar um diretório permanente
set_cache_dir("~/educabR_data")

# Listar arquivos em cache
list_cache()

# Limpar cache (quando necessário)
clear_cache()
```

## IDEB - Índice de Desenvolvimento da Educação Básica

O IDEB é o principal indicador de qualidade da educação básica no
Brasil, combinando desempenho em provas (SAEB) com taxas de aprovação.

### Anos e níveis disponíveis

``` r
# Ver combinações disponíveis
list_ideb_available()
#> # A tibble: 24 x 3
#>     year level     stage
#>    <int> <chr>     <chr>
#>  1  2017 escola    anos_iniciais
#>  2  2017 escola    anos_finais
#>  3  2017 escola    ensino_medio
#>  4  2017 municipio anos_iniciais
#>  ...
```

### Baixando dados do IDEB

``` r
# IDEB por escola - Anos Iniciais (1º ao 5º ano)
ideb_escolas <- get_ideb(
  year = 2021,
  level = "escola",
  stage = "anos_iniciais"
)

# IDEB por município - Ensino Médio
ideb_municipios <- get_ideb(
  year = 2023,
  level = "municipio",
  stage = "ensino_medio"
)

# Filtrar por estado (mais rápido)
ideb_sp <- get_ideb(
  year = 2021,
  level = "escola",
  stage = "anos_iniciais",
  uf = "SP"
)
```

### Estrutura dos dados

``` r
# Visualizar estrutura
glimpse(ideb_escolas)
#> Rows: 63,529
#> Columns: 17
#> $ sg_uf                   <chr> "RO", "RO", "RO", ...
#> $ co_municipio            <dbl> 1100015, 1100015, ...
#> $ no_municipio            <chr> "Alta Floresta D'Oeste", ...
#> $ id_escola               <dbl> 11000023, 11000040, ...
#> $ no_escola               <chr> "EEEE ABNAEL MACHADO DE LIMA", ...
#> $ rede                    <chr> "Estadual", "Municipal", ...
#> $ vl_aprovacao_2021_si_4  <dbl> 93.3, 98.5, 100, ...
#> $ vl_indicador_rend_2021  <dbl> 0.92, 0.98, 1.00, ...
#> $ vl_nota_matematica_2021 <dbl> 5.2, 5.8, 6.1, ...
#> $ vl_nota_portugues_2021  <dbl> 5.4, 5.9, 6.0, ...
#> $ vl_nota_media_2021      <dbl> 5.3, 5.85, 6.05, ...
#> $ vl_observado_2021       <dbl> 4.9, 5.7, 6.1, ...
```

### Exemplo de análise: IDEB médio por estado

``` r
# Calcular IDEB médio por UF
ideb_por_uf <- ideb_escolas |>
  filter(!is.na(vl_observado_2021)) |>
  group_by(sg_uf) |>
  summarise(
    n_escolas = n(),
    ideb_medio = mean(vl_observado_2021, na.rm = TRUE),
    ideb_mediano = median(vl_observado_2021, na.rm = TRUE)
  ) |>
  arrange(desc(ideb_medio))

# Visualizar
ggplot(ideb_por_uf, aes(x = reorder(sg_uf, ideb_medio), y = ideb_medio)) +
  geom_col(fill = "steelblue") +
  coord_flip() +
  labs(
    title = "IDEB Médio por Estado - Anos Iniciais (2021)",
    x = "Estado",
    y = "IDEB Médio"
  ) +
  theme_minimal()
```

### Série histórica do IDEB

``` r
# Baixar série histórica
ideb_historico <- get_ideb_series(
  years = c(2017, 2019, 2021, 2023),
  level = "municipio",
  stage = "anos_iniciais"
)

# Evolução nacional
evolucao <- ideb_historico |>
  group_by(ano_ideb) |>
  summarise(ideb_medio = mean(vl_observado, na.rm = TRUE))

ggplot(evolucao, aes(x = ano_ideb, y = ideb_medio)) +
  geom_line(color = "darkgreen", size = 1.2) +
  geom_point(color = "darkgreen", size = 3) +
  labs(
    title = "Evolução do IDEB - Anos Iniciais",
    x = "Ano",
    y = "IDEB Médio Nacional"
  ) +
  theme_minimal()
```

## ENEM - Exame Nacional do Ensino Médio

O ENEM é o maior exame do Brasil, com milhões de participantes
anualmente. Os microdados incluem informações demográficas,
socioeconômicas e notas.

### Baixando dados do ENEM

``` r
# ATENÇÃO: Arquivos grandes (1-3 GB)!
# Use n_max para exploração inicial

# Amostra para exploração
enem_amostra <- get_enem(2023, n_max = 10000)

# Dados completos (demora!)
# enem_completo <- get_enem(2023)
```

### Estrutura dos dados

``` r
glimpse(enem_amostra)
#> Rows: 10,000
#> Columns: 76
#> $ nu_inscricao      <dbl> 230001234567, ...
#> $ nu_ano            <dbl> 2023, 2023, ...
#> $ tp_faixa_etaria   <dbl> 3, 4, 2, ...
#> $ tp_sexo           <chr> "F", "M", "F", ...
#> $ tp_cor_raca       <dbl> 1, 3, 2, ...
#> $ nu_nota_cn        <dbl> 512.3, 489.1, ...
#> $ nu_nota_ch        <dbl> 598.2, 567.4, ...
#> $ nu_nota_lc        <dbl> 534.8, 502.1, ...
#> $ nu_nota_mt        <dbl> 478.9, 521.3, ...
#> $ nu_nota_redacao   <dbl> 720, 640, ...
```

### Análise de desempenho por características

``` r
# Resumo estatístico das notas
enem_summary(enem_amostra)

# Resumo por sexo
enem_summary(enem_amostra, by = "tp_sexo")

# Médias por cor/raça
notas_por_raca <- enem_amostra |>
  filter(!is.na(nu_nota_mt)) |>
  mutate(
    cor_raca = case_when(
      tp_cor_raca == 0 ~ "Não declarado",
      tp_cor_raca == 1 ~ "Branca",
      tp_cor_raca == 2 ~ "Preta",
      tp_cor_raca == 3 ~ "Parda",
      tp_cor_raca == 4 ~ "Amarela",
      tp_cor_raca == 5 ~ "Indígena"
    )
  ) |>
  group_by(cor_raca) |>
  summarise(
    n = n(),
    media_mt = mean(nu_nota_mt, na.rm = TRUE),
    media_redacao = mean(nu_nota_redacao, na.rm = TRUE)
  )
```

### Dados de itens (gabarito)

``` r
# Dados sobre as questões da prova
itens <- get_enem_itens(2023)

glimpse(itens)
#> $ co_item        <dbl> 1, 2, 3, ...
#> $ co_prova       <dbl> 1001, 1001, ...
#> $ tp_lingua      <dbl> 0, 0, ...
#> $ sg_area        <chr> "CN", "CN", ...
#> $ co_habilidade  <dbl> 1, 2, ...
```

## Censo Escolar

O Censo Escolar é a principal pesquisa estatística sobre educação básica
no Brasil, cobrindo todas as escolas públicas e privadas.

### Baixando dados do Censo

``` r
# Dados de escolas
escolas_2023 <- get_censo_escolar(2023)

# Filtrar por estado (mais rápido)
escolas_sp <- get_censo_escolar(2023, uf = "SP")

# Amostra para exploração
escolas_amostra <- get_censo_escolar(2023, n_max = 1000)
```

### Estrutura dos dados

``` r
# O censo contém mais de 400 variáveis por escola!
glimpse(escolas_2023)
#> Rows: 217,625
#> Columns: 408
#> $ nu_ano_censo     <dbl> 2023, 2023, ...
#> $ sg_uf            <chr> "RO", "RO", ...
#> $ co_uf            <dbl> 11, 11, ...
#> $ no_municipio     <chr> "Porto Velho", ...
#> $ co_municipio     <dbl> 1100205, ...
#> $ no_entidade      <chr> "EEEE ABNAEL MACHADO DE LIMA", ...
#> $ co_entidade      <dbl> 11000023, ...
#> $ tp_dependencia   <dbl> 2, 3, 4, ...
#> $ tp_localizacao   <dbl> 1, 1, 1, ...
```

### Análise: Escolas por dependência administrativa

``` r
# Contagem por tipo de dependência
escolas_por_dep <- escolas_2023 |>
  mutate(
    dependencia = case_when(
      tp_dependencia == 1 ~ "Federal",
      tp_dependencia == 2 ~ "Estadual",
      tp_dependencia == 3 ~ "Municipal",
      tp_dependencia == 4 ~ "Privada"
    )
  ) |>
  count(dependencia) |>
  mutate(pct = n / sum(n) * 100)

ggplot(escolas_por_dep, aes(x = reorder(dependencia, n), y = n, fill = dependencia)) +
  geom_col() +
  geom_text(aes(label = sprintf("%.1f%%", pct)), hjust = -0.1) +
  coord_flip() +
  scale_fill_brewer(palette = "Set2") +
  labs(
    title = "Número de Escolas por Dependência Administrativa (2023)",
    x = NULL,
    y = "Número de Escolas"
  ) +
  theme_minimal() +
  theme(legend.position = "none")
```

### Análise: Infraestrutura escolar

``` r
# Verificar disponibilidade de infraestrutura
infra <- escolas_2023 |>
  filter(tp_dependencia %in% c(2, 3)) |>  # Públicas
  summarise(
    pct_internet = mean(in_internet == 1, na.rm = TRUE) * 100,
    pct_biblioteca = mean(in_biblioteca == 1, na.rm = TRUE) * 100,
    pct_lab_info = mean(in_laboratorio_informatica == 1, na.rm = TRUE) * 100,
    pct_quadra = mean(in_quadra_esportes == 1, na.rm = TRUE) * 100,
    pct_acessibilidade = mean(in_acessibilidade == 1, na.rm = TRUE) * 100
  )

print(infra)
#> # A tibble: 1 x 5
#>   pct_internet pct_biblioteca pct_lab_info pct_quadra pct_acessibilidade
#>          <dbl>          <dbl>        <dbl>      <dbl>              <dbl>
#> 1         78.3           42.1         35.2       48.7               32.1
```

## Boas práticas

### 1. Configure um cache permanente

``` r
# No início de cada projeto
set_cache_dir("~/educabR_data")
```

### 2. Use amostras para exploração

``` r
# Primeiro explore com amostra pequena
dados_teste <- get_enem(2023, n_max = 1000)

# Depois baixe os dados completos
# dados_completos <- get_enem(2023)
```

### 3. Filtre por UF quando possível

``` r
# Mais rápido que baixar tudo e filtrar depois
dados_sp <- get_ideb(2021, level = "escola", stage = "anos_iniciais", uf = "SP")
```

### 4. Monitore o uso de memória

``` r
# Arquivos grandes podem consumir muita RAM
# Use n_max ou filtre os dados após carregar
dados <- get_censo_escolar(2023)
dados_filtrado <- dados |>
  select(co_entidade, no_entidade, sg_uf, tp_dependencia)
rm(dados)  # Liberar memória
gc()
```

## Dicionário de dados

Para informações detalhadas sobre as variáveis, consulte a documentação
oficial:

- **IDEB**:
  <https://www.gov.br/inep/pt-br/areas-de-atuacao/pesquisas-estatisticas-e-indicadores/ideb>
- **ENEM**:
  <https://www.gov.br/inep/pt-br/acesso-a-informacao/dados-abertos/microdados/enem>
- **Censo Escolar**:
  <https://www.gov.br/inep/pt-br/acesso-a-informacao/dados-abertos/microdados/censo-escolar>

## Problemas conhecidos

1.  **Downloads lentos**: Os servidores do INEP podem ser lentos. O
    pacote tenta 3 vezes automaticamente.

2.  **Arquivos grandes**: ENEM e Censo Escolar podem ter vários GB. Use
    `n_max` para testar.

3.  **Encoding**: Alguns arquivos têm problemas de encoding. O pacote
    tenta corrigir automaticamente.

## Contribuindo

Encontrou um bug ou quer sugerir melhorias? Abra uma issue no GitHub:
<https://github.com/SidneyBissoli/educabR/issues>

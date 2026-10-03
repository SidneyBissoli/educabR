# Basic Education Assessments: SAEB, ENCCEJA, and ENEM by School

This vignette covers three basic education assessment datasets available
in educabR. For IDEB, ENEM, and the School Census, see
[`vignette("getting-started")`](https://sidneybissoli.github.io/educabR/articles/getting-started.md).

``` r

library(educabR)
library(dplyr)
library(ggplot2)
```

## SAEB - Basic Education Assessment System

SAEB (Sistema de Avaliacao da Educacao Basica) is a biennial assessment
that measures student performance in Portuguese and Mathematics across
Brazilian basic education. It is one of the components used to calculate
IDEB.

### Available data types

SAEB microdata includes four perspectives:

| Type          | Description                               |
|---------------|-------------------------------------------|
| `"aluno"`     | Student-level results (scores, responses) |
| `"escola"`    | School questionnaire data                 |
| `"diretor"`   | Principal questionnaire data              |
| `"professor"` | Teacher questionnaire data                |

### Downloading SAEB data

Since 2013, INEP publishes one student file per grade, so
`type = "aluno"` needs a `serie`: `"5ef"` and `"9ef"` (5th and 9th
grades of elementary school), `"2ef"` (2nd grade, 2019 onwards),
`"34em"` (3rd/4th grades of high school, 2019 onwards), `"3em"` (2013,
2015) or `"3em_ag"`/`"3em_esc"` (2017). The numbers 2, 5 and 9 work as
shortcuts. Without `serie`,
[`get_saeb()`](https://sidneybissoli.github.io/educabR/reference/get_saeb.md)
stops and lists the grades available for that year.

``` r

# Student performance data, 5th grade
saeb_5ef <- get_saeb(year = 2023, type = "aluno", serie = "5ef")

# School questionnaire
saeb_schools <- get_saeb(year = 2023, type = "escola")

# Use n_max for exploration
saeb_sample <- get_saeb(year = 2023, serie = 9, n_max = 5000)

# Several grades: one call per grade (columns differ between grades;
# the 5th and 9th grade files are about 1 GB of CSV each)
saeb_ef <- purrr::map(c("5ef", "9ef"), function(s) {
  get_saeb(year = 2023, serie = s)
})
```

### Available years

SAEB is conducted every two years: 2011, 2013, 2015, 2017, 2019, 2021,
2023.

``` r

# 2021 data is split by education level
saeb_fund <- get_saeb(
  year  = 2021,
  type  = "aluno",
  level = "fundamental_medio",
  serie = "9ef"
)

saeb_infantil <- get_saeb(
  year  = 2021,
  type  = "aluno",
  level = "educacao_infantil"
)
```

### Example analysis: Score distribution

``` r

# Explore student scores (2nd grade of elementary school)
saeb_sample <- get_saeb(2023, type = "aluno", serie = "2ef", n_max = 10000)

# Score distribution by subject
saeb_sample |>
  filter(!is.na(proficiencia_mt)) |>
  ggplot(aes(x = proficiencia_mt)) +
  geom_histogram(bins = 50, fill = "steelblue", alpha = 0.7) +
  labs(
    title = "SAEB 2023 - Mathematics Proficiency Distribution (2nd grade)",
    x     = "Mathematics Score",
    y     = "Count"
  ) +
  theme_minimal()
```

![](../reference/figures/vignette-basic-saeb-math.png)

------------------------------------------------------------------------

## ENCCEJA - Youth and Adult Education Certification

ENCCEJA (Exame Nacional para Certificacao de Competencias de Jovens e
Adultos) provides certification for elementary and high school
equivalency. It covers four knowledge areas: Natural Sciences,
Mathematics, Portuguese, and Social Sciences.

### Downloading ENCCEJA data

``` r

# Download ENCCEJA microdata
encceja_2023 <- get_encceja(year = 2023)

# Sample for exploration
encceja_sample <- get_encceja(year = 2023, n_max = 5000)
```

### Available years

ENCCEJA data is available from 2014 to 2024.

``` r

# Explore the data structure
glimpse(encceja_sample)
```

### Example analysis: Participation by state

``` r

encceja_2023 <- get_encceja(2023, n_max = 50000)

# Count participants by state
participants_by_state <- 
  encceja_2023 |>
  count(sg_uf_prova, sort = TRUE) |>
  head(10)

ggplot(participants_by_state, aes(
  x = reorder(sg_uf_prova, n),
  y = n
)) +
  geom_col(fill = "darkorange") +
  coord_flip() +
  labs(
    title = "ENCCEJA 2023 - Top 10 States by Participation",
    x     = "State",
    y     = "Number of Participants"
  ) +
  theme_minimal() +
  scale_y_continuous(label = scales::number_format(big.mark = ".", decimal.mark = ","))
```

![](../reference/figures/vignette-basic-encceja-states.png)

------------------------------------------------------------------------

## ENEM by School (2005-2015)

ENEM by School (ENEM por Escola) provides ENEM results aggregated at the
school level. This dataset covers 2005 to 2015 in a single bundled file
and was **discontinued after 2015**.

### Downloading the data

Unlike other datasets, this function has no `year` parameter — it
downloads the entire 2005-2015 dataset at once.

``` r

# Download all ENEM by School data (2005-2015)
enem_escola <- get_enem_escola()

# Sample for exploration
enem_escola_sample <- get_enem_escola(n_max = 5000)
```

### Data structure

``` r

glimpse(enem_escola_sample)
```

### Example analysis: School performance trends

``` r

enem_escola <- get_enem_escola()

# Average scores over time (public vs private)
trend <-
  enem_escola |>
  mutate(
    media_geral = rowMeans(
      across(c(nu_media_cn, nu_media_ch, nu_media_lp, nu_media_mt, nu_media_red)),
      na.rm = FALSE
    )
  ) |>
  filter(!is.na(media_geral)) |>
  group_by(nu_ano, tp_dependencia_adm_escola) |>
  summarise(
    mean_score = mean(media_geral, na.rm = TRUE),
    .groups    = "drop"
  ) |>
  mutate(
    admin_type = case_when(
      tp_dependencia_adm_escola == 1 ~ "Federal",
      tp_dependencia_adm_escola == 2 ~ "State",
      tp_dependencia_adm_escola == 3 ~ "Municipal",
      tp_dependencia_adm_escola == 4 ~ "Private"
    )
  )

ggplot(trend, aes(x = nu_ano, y = mean_score, color = admin_type)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  labs(
    title = "ENEM Average Score by School Type (2009-2015)",
    x     = "Year",
    y     = "Average Total Score",
    color = "School Type"
  ) +
  theme_minimal()
```

![](../reference/figures/vignette-basic-enem-escola.png)

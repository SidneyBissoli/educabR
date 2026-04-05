# Which municipalities improved the most in IDEB?

This vignette shows how to use educabR to identify which municipalities
had the largest IDEB improvement over time, using the historical series
available via
[`get_ideb()`](https://sidneybissoli.github.io/educabR/reference/get_ideb.md).

``` r
library(educabR)
library(dplyr)
library(tidyr)
library(ggplot2)
```

## Downloading IDEB data

[`get_ideb()`](https://sidneybissoli.github.io/educabR/reference/get_ideb.md)
returns data in long format with all available editions. A single call
with `year = c(2005, 2023)` gives us the two endpoints we need for
comparison.

``` r
ideb <- get_ideb(
  level  = "municipio",
  stage  = "anos_iniciais",
  metric = "indicador",
  year   = c(2005, 2023)
)
glimpse(ideb)
```

## Calculating IDEB improvement

We filter to the IDEB indicator, pivot to wide format to get one column
per year, then compute the change.

``` r
ideb_change <-
  ideb |>
  filter(indicador == "IDEB") |>
  select(uf_sigla, municipio_codigo, municipio_nome, rede, ano, valor) |>
  pivot_wider(names_from = ano, values_from = valor, names_prefix = "ideb_") |>
  filter(!is.na(ideb_2005), !is.na(ideb_2023)) |>
  mutate(
    change     = ideb_2023 - ideb_2005,
    pct_change = change / ideb_2005 * 100
  )
```

## Top 20 municipalities by absolute improvement

``` r
ideb_change |>
  slice_max(change, n = 20) |>
  ggplot(aes(
    x = reorder(paste(municipio_nome, uf_sigla, sep = " - "), change),
    y = change
  )) +
  geom_col(fill = "#2a9d8f") +
  coord_flip() +
  labs(
    title = "Top 20 Municipalities by IDEB Improvement (2005-2023)",
    subtitle = "Early elementary (1st-5th grade)",
    x = NULL,
    y = "IDEB change (2023 - 2005)"
  ) +
  theme_minimal()
```

## Distribution of improvement by state

``` r
ideb_change |>
  ggplot(aes(x = reorder(uf_sigla, change, FUN = median), y = change)) +
  geom_boxplot(fill = "#2a9d8f", alpha = 0.6, outlier.size = 0.5) +
  coord_flip() +
  labs(
    title = "IDEB Improvement Distribution by State (2005-2023)",
    subtitle = "Early elementary (1st-5th grade)",
    x = NULL,
    y = "IDEB change"
  ) +
  theme_minimal()
```

## IDEB trajectory for selected municipalities

``` r
# Pick the top 5 improvers
top5 <-
  ideb_change |>
  slice_max(change, n = 5) |>
  pull(municipio_codigo)

# Get full history for these municipalities
ideb_full <- get_ideb(
  level  = "municipio",
  stage  = "anos_iniciais",
  metric = "indicador"
)

ideb_full |>
  filter(municipio_codigo %in% top5, indicador == "IDEB") |>
  mutate(label = paste(municipio_nome, uf_sigla, sep = " - ")) |>
  ggplot(aes(x = factor(ano), y = valor, color = label, group = label)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  labs(
    title = "IDEB Trajectory - Top 5 Improvers",
    x     = "Year",
    y     = "IDEB",
    color = NULL
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")
```

## Municipalities that declined

``` r
ideb_change |>
  filter(change < 0) |>
  slice_min(change, n = 15) |>
  ggplot(aes(
    x = reorder(paste(municipio_nome, uf_sigla, sep = " - "), change),
    y = change
  )) +
  geom_col(fill = "#e76f51") +
  coord_flip() +
  labs(
    title = "Municipalities with Largest IDEB Decline (2005-2023)",
    subtitle = "Early elementary (1st-5th grade)",
    x = NULL,
    y = "IDEB change (2023 - 2005)"
  ) +
  theme_minimal()
```

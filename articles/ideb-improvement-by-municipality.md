# Which municipalities improved the most in IDEB?

This vignette shows how to use educabR to identify which municipalities
had the largest IDEB improvement over time, using the historical series
available in the IDEB spreadsheets.

``` r
library(educabR)
library(dplyr)
library(ggplot2)
```

## Downloading IDEB data

Each IDEB file already contains the full historical series (all editions
from 2005 to the current year), so a single download is enough.

``` r
ideb <- get_ideb(year = 2023, stage = "anos_iniciais", level = "municipio")
glimpse(ideb)
```

## Calculating IDEB improvement

The columns `vl_observado_YYYY` contain the observed IDEB for each
edition. We compare the earliest and latest available values.

``` r
ideb_change <- ideb |>
  filter(!is.na(vl_observado_2005), !is.na(vl_observado_2023)) |>
  mutate(
    change     = vl_observado_2023 - vl_observado_2005,
    pct_change = change / vl_observado_2005 * 100
  )
```

## Top 20 municipalities by absolute improvement

``` r
ideb_change |>
  slice_max(change, n = 20) |>
  ggplot(aes(
    x = reorder(paste(no_municipio, sg_uf, sep = " - "), change),
    y = change
  )) +
  geom_col(fill = "#2a9d8f") +
  coord_flip() +
  labs(
    title = "Top 20 Municipalities by IDEB Improvement (2005-2023)",
    subtitle = "Early elementary (anos iniciais)",
    x = NULL,
    y = "IDEB change (2023 - 2005)"
  ) +
  theme_minimal()
```

## Distribution of improvement by state

``` r
ideb_change |>
  ggplot(aes(x = reorder(sg_uf, change, FUN = median), y = change)) +
  geom_boxplot(fill = "#2a9d8f", alpha = 0.6, outlier.size = 0.5) +
  coord_flip() +
  labs(
    title = "IDEB Improvement Distribution by State (2005-2023)",
    subtitle = "Early elementary (anos iniciais)",
    x = NULL,
    y = "IDEB change"
  ) +
  theme_minimal()
```

## IDEB trajectory for selected municipalities

``` r
# Pick the top 5 improvers
top5 <- ideb_change |>
  slice_max(change, n = 5) |>
  pull(co_municipio)

# Reshape to long format for plotting
library(tidyr)

ideb |>
  filter(co_municipio %in% top5) |>
  select(co_municipio, no_municipio, sg_uf, starts_with("vl_observado_")) |>
  pivot_longer(
    cols      = starts_with("vl_observado_"),
    names_to  = "year",
    values_to = "ideb_score"
  ) |>
  mutate(
    year  = as.integer(gsub("vl_observado_", "", year)),
    label = paste(no_municipio, sg_uf, sep = " - ")
  ) |>
  filter(!is.na(ideb_score)) |>
  ggplot(aes(x = year, y = ideb_score, color = label)) +
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
    x = reorder(paste(no_municipio, sg_uf, sep = " - "), change),
    y = change
  )) +
  geom_col(fill = "#e76f51") +
  coord_flip() +
  labs(
    title = "Municipalities with Largest IDEB Decline (2005-2023)",
    subtitle = "Early elementary (anos iniciais)",
    x = NULL,
    y = "IDEB change (2023 - 2005)"
  ) +
  theme_minimal()
```

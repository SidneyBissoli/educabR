## ad-hoc memory benchmark for issue #1
## not part of the test suite — invoke manually with Rscript
##   Rscript inst/bench/ideb-memory.R

devtools::load_all(quiet = TRUE)
Sys.setenv(EDUCABR_SKIP_DISCOVERY = "true")

xlsx_path <- cache_path("ideb", "divulgacao_anos_iniciais_escolas_2023.xlsx")
if (!file.exists(xlsx_path)) {
  url <- educabR:::build_ideb_url("escola", "anos_iniciais", 2023)
  cat("downloading IDEB file to cache for benchmarking...\n")
  educabR:::download_inep_file(url, xlsx_path, quiet = TRUE)
}

bench_one <- function(label, expr) {
  gc(reset = TRUE, full = TRUE)
  t0 <- Sys.time()
  val <- eval(expr)
  dt <- as.numeric(Sys.time() - t0, units = "secs")
  g <- gc(reset = FALSE, full = TRUE)
  peak_mb <- sum(g[, 6])  # "max used" in Mb (col name has trailing "(Mb)" header quirk)
  obj_mb  <- as.numeric(object.size(val)) / 1024^2
  cat(sprintf("%-50s rows=%-8d cols=%-3d time=%6.2fs peak=%6.0fMB result=%5.0fMB\n",
              label, nrow(val), ncol(val), dt, peak_mb, obj_mb))
  invisible(val)
}

cat("--- baseline (read full sheet, no projection) ---\n")
bench_one("legacy read_ideb_excel", quote({
  read_ideb_excel(xlsx_path, sheet = NULL)
}))

cat("--- projected: metric only ---\n")
bench_one("metric=indicador", quote({
  read_ideb_excel(xlsx_path, sheet = NULL, metric = "indicador")
}))

cat("--- projected: metric + year subset ---\n")
bench_one("metric=indicador, year=c(2023)", quote({
  read_ideb_excel(xlsx_path, sheet = NULL, metric = "indicador", year = 2023)
}))

bench_one("metric=indicador, year=c(2017,2019,2021,2023)", quote({
  read_ideb_excel(xlsx_path, sheet = NULL, metric = "indicador",
                  year = c(2017, 2019, 2021, 2023))
}))

cat("--- end-to-end get_ideb (full pipeline) ---\n")
bench_one("get_ideb escola/anos_iniciais/indicador, 4 anos", quote({
  get_ideb("escola", "anos_iniciais", "indicador",
           year = c(2017, 2019, 2021, 2023), quiet = TRUE)
}))

# R/corpus_stats.R — descriptivos del corpus (puros; usan R/stats_utils.R)

# Descriptivos de un vector numérico. Devuelve siempre 1 fila.
.describe_vec <- function(x) {
  x <- suppressWarnings(as.numeric(x)); x <- x[!is.na(x)]
  n <- length(x)
  if (n == 0) {
    return(data.frame(n = 0, media = NA, sd = NA, min = NA, p25 = NA,
                      mediana = NA, p75 = NA, max = NA,
                      asimetria = NA, curtosis = NA))
  }
  data.frame(
    n = n, media = mean(x), sd = stats::sd(x), min = min(x),
    p25 = stats::quantile(x, .25, names = FALSE), mediana = stats::median(x),
    p75 = stats::quantile(x, .75, names = FALSE), max = max(x),
    asimetria = stat_skewness(x), curtosis = stat_kurtosis(x)
  )
}

# Descriptivos de una variable numérica, opcionalmente por hasta N grupos.
describe_numeric <- function(df, num_col, group_cols = character(0)) {
  stopifnot(num_col %in% names(df))
  group_cols <- group_cols[group_cols %in% names(df)]
  if (length(group_cols) == 0) {
    return(cbind(data.frame(grupo = "TOTAL", stringsAsFactors = FALSE),
                 .describe_vec(df[[num_col]])))
  }
  key <- do.call(paste, c(lapply(group_cols, function(g) as.character(df[[g]])),
                          sep = " | "))
  sp <- split(df[[num_col]], key, drop = TRUE)
  rows <- lapply(names(sp), function(k)
    cbind(data.frame(grupo = k, stringsAsFactors = FALSE), .describe_vec(sp[[k]])))
  out <- do.call(rbind, rows)
  out[order(out$grupo), , drop = FALSE]
}

# Resumen de conteos del corpus consolidado.
corpus_file_summary <- function(df) {
  has_fn <- "filename" %in% names(df)
  per_file <- NULL
  if (has_fn) {
    tb <- table(df$filename)
    per_file <- data.frame(filename = names(tb),
                           n_filas = as.integer(tb),
                           stringsAsFactors = FALSE)
  }
  list(n_files = if (has_fn) length(unique(df$filename)) else NA_integer_,
       n_rows = nrow(df), n_vars = ncol(df), per_file = per_file)
}

# R/contexto.R — utilidades de contexto (puras, base R + tools)

format_cita <- function(corpus, start, end) {
  s <- sprintf("%.2f", suppressWarnings(as.numeric(start)))
  e <- sprintf("%.2f", suppressWarnings(as.numeric(end)))
  sprintf("(%s, %s-%s)", corpus, s, e)
}

recompute_contexto <- function(df, window = 5) {
  if (!"contexto" %in% names(df)) df$contexto <- NA_character_
  n_rows <- nrow(df)
  for (i in seq_len(n_rows)) {
    filas_ctx <- max(1, i - window):min(n_rows, i + window)
    ctx <- mapply(function(sp, lb) {
      sp <- trimws(ifelse(is.na(sp), "", sp))
      lb <- trimws(ifelse(is.na(lb), "", lb))
      if (!nzchar(lb)) return("")
      if (nzchar(sp)) paste0(sp, ": ", lb) else lb
    }, df$speaker[filas_ctx], df$label[filas_ctx])
    df$contexto[i] <- paste(ctx[nzchar(ctx)], collapse = " | ")
  }
  df
}

corpus_base_name <- function(filename) {
  if (is.null(filename) || !nzchar(filename)) return("corpus")
  b <- tools::file_path_sans_ext(basename(filename))
  sub("^analisis_", "", b)
}

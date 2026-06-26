# R/prefs.R — preferencias persistentes (puras, base R)

PREFS_DEFAULTS <- list(animo_enabled = FALSE, animo_custom = "", plot_font_scale = 1)

load_prefs <- function(path) {
  prefs <- PREFS_DEFAULTS
  if (!file.exists(path)) return(prefs)
  lines <- tryCatch(readLines(path, warn = FALSE, encoding = "UTF-8"),
                    error = function(e) character(0))
  for (ln in lines) {
    if (!grepl("\t", ln, fixed = TRUE)) next
    kv <- strsplit(ln, "\t", fixed = TRUE)[[1]]
    if (length(kv) < 2) next
    key <- trimws(kv[1]); val <- paste(kv[-1], collapse = "\t")
    if (!key %in% names(PREFS_DEFAULTS)) next
    prefs[[key]] <- switch(key,
      animo_enabled   = isTRUE(as.logical(val)),
      plot_font_scale = { n <- suppressWarnings(as.numeric(val)); if (is.na(n)) 1 else n },
      val)
  }
  prefs
}

save_prefs <- function(prefs, path) {
  lines <- vapply(names(PREFS_DEFAULTS), function(k) {
    v <- if (is.null(prefs[[k]])) PREFS_DEFAULTS[[k]] else prefs[[k]]
    v <- gsub("[\r\n]+", " ", as.character(v))
    paste0(k, "\t", v)
  }, character(1))
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  writeLines(lines, path, useBytes = TRUE)
  invisible(path)
}

choose_message <- function(custom, presets) {
  custom <- if (is.null(custom)) "" else trimws(custom)
  if (nzchar(custom)) return(custom)
  if (length(presets) == 0) return("")
  sample(presets, 1)
}

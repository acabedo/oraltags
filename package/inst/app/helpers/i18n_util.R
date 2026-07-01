# R/i18n_util.R — utilidades de i18n (puras, base R + jsonlite)

load_i18n_dict <- function(json_path) {
  empty <- list(es = character(0), en = character(0))
  if (!file.exists(json_path)) return(empty)
  j <- tryCatch(jsonlite::fromJSON(json_path, simplifyVector = TRUE),
                error = function(e) NULL)
  if (is.null(j) || is.null(j$translation)) return(empty)
  tr_df <- j$translation
  list(es = as.character(tr_df$es), en = as.character(tr_df$en))
}

tr <- function(key, lang, dict) {
  if (is.null(lang) || lang != "en") return(key)
  i <- match(key, dict$es)
  if (is.na(i)) return(key)
  en <- dict$en[i]
  if (is.na(en) || !nzchar(en)) key else en
}

# Traducción SOLO visual de un valor de anotación almacenado (canónico en es)
# al idioma activo. Soporta selección múltiple separada por "; " y el formato
# de anot27 ("Etiqueta - N"). El almacenamiento nunca cambia: esto solo se usa
# para mostrar en tablas y para la exportación CSV.
tr_anot_value <- function(v, lang, dict) {
  if (is.null(v) || length(v) != 1L || is.na(v) || !nzchar(v)) return(v)
  parts <- strsplit(v, ";\\s*")[[1]]
  out <- vapply(parts, function(p) {
    m <- regmatches(p, regexec("^(.*?)(\\s-\\s[0-9]+)\\s*$", p))[[1]]
    if (length(m) == 3L) paste0(tr(m[2], lang, dict), m[3]) else tr(p, lang, dict)
  }, character(1), USE.NAMES = FALSE)
  paste(out, collapse = "; ")
}

# Copia de df con las columnas de anotación (anot1, anot2, …) traducidas al
# idioma activo. Con lang == "es" es un no-op (tr() devuelve la clave).
tr_df_categories <- function(df, lang, dict) {
  if (is.null(df) || !nrow(df)) return(df)
  cols <- grep("^anot[0-9]+$", names(df), value = TRUE)
  for (cn in cols)
    df[[cn]] <- vapply(as.character(df[[cn]]), tr_anot_value, character(1),
                       lang = lang, dict = dict, USE.NAMES = FALSE)
  df
}

i18n_used_keys <- function(code_path) {
  code <- paste(readLines(code_path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  pat <- '(?:i18n\\$t|\\btr)\\(\\s*"((?:[^"\\\\]|\\\\.)*)"'  # \btr evita casar attr(, substr(…
  m <- gregexpr(pat, code, perl = TRUE)
  keys <- regmatches(code, m)[[1]]
  if (length(keys) == 0) return(character(0))
  vals <- sub(pat, "\\1", keys, perl = TRUE)
  vals <- gsub('\\\\"', '"', vals)   # des-escapar comillas
  unique(vals)
}

i18n_missing_translations <- function(code_path, json_path) {
  used <- i18n_used_keys(code_path)
  dict <- load_i18n_dict(json_path)
  has_en <- function(k) {
    i <- match(k, dict$es)
    !is.na(i) && !is.na(dict$en[i]) && nzchar(dict$en[i])
  }
  used[!vapply(used, has_en, logical(1))]
}

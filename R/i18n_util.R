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

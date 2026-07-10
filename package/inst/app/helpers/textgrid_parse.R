# ============================================================
# PARSEO DE TEXTGRID (helpers puros, compartidos por app y tests)
# ============================================================

# Praat guarda los TextGrid en UTF-16 cuando el texto contiene caracteres
# fuera de ASCII; encoding = "auto" detecta el BOM y lee ambos formatos.
read_textgrid <- function(path) {
  rPraat::tg.read(path, encoding = "auto")
}

# Detecta si el TextGrid es de MFA (tiers "words" y "phones", con o sin
# prefijo de hablante: "words", "e_words", "i - words", …)
is_mfa_textgrid <- function(tg) {
  tier_names <- sapply(seq_len(tg.getNumberOfTiers(tg)), function(i) {
    tryCatch(tg.getTierName(tg, i), error = function(e) "")
  })
  any(grepl("words", tier_names, ignore.case = TRUE)) &&
    any(grepl("phones", tier_names, ignore.case = TRUE))
}

# Construye intonational phrases desde tier de palabras
build_ips_from_words_tier <- function(tg, words_tier_idx,
                                       pause_min = 0.15,
                                       speaker_label = "speaker-unique") {
  n <- tg.getNumberOfIntervals(tg, words_tier_idx)
  ips <- list()
  ip_start <- NULL; ip_end <- NULL; ip_words <- character(0)

  flush_ip <- function() {
    if (!is.null(ip_start) && length(ip_words) > 0) {
      ips[[length(ips) + 1]] <<- list(
        start = ip_start, end = ip_end,
        label = paste(ip_words, collapse = " ")
      )
    }
  }

  for (j in seq_len(n)) {
    lbl <- trimws(tg.getLabel(tg, words_tier_idx, j))
    ts  <- tg.getIntervalStartTime(tg, words_tier_idx, j)
    te  <- tg.getIntervalEndTime(tg, words_tier_idx, j)
    dur <- te - ts

    if (!nzchar(lbl) || lbl %in% c("sp","<eps>","SIL","sil","<SIL>")) {
      # pausa: terminar IP si es suficientemente larga
      if (dur >= pause_min) {
        flush_ip()
        ip_start <- NULL; ip_end <- NULL; ip_words <- character(0)
      } else {
        # pausa corta: no cortar
      }
    } else {
      if (is.null(ip_start)) ip_start <- ts
      ip_end  <- te
      ip_words <- c(ip_words, lbl)
    }
  }
  flush_ip()

  if (length(ips) == 0) return(NULL)

  data.frame(
    speaker = rep(speaker_label, length(ips)),
    start   = sapply(ips, `[[`, "start"),
    end     = sapply(ips, `[[`, "end"),
    label   = sapply(ips, `[[`, "label"),
    stringsAsFactors = FALSE
  )
}

# Parsear TextGrid genérico → data.frame
#   - Modo MFA: los tiers de words se agrupan en GEs por pausas; el hablante
#     se extrae del prefijo del tier ("e_words"/"e - words" → "e"); si el
#     tier se llama solo "words" no hay prefijo → "speaker-unique".
#   - Modo genérico (sin words/phones): cada tier es un hablante y cada
#     intervalo con texto se toma directamente como unidad de anotación (GE).
parse_textgrid <- function(tg, mfa_mode = FALSE, pause_min = 0.15) {
  nTiers <- tg.getNumberOfTiers(tg)
  tier_names <- sapply(seq_len(nTiers), function(i) {
    nm <- tryCatch(tg.getTierName(tg, i), error = function(e) paste0("Tier_", i))
    if (is.null(nm) || !nzchar(nm)) paste0("Tier_", i) else as.character(nm)
  })

  if (mfa_mode && is_mfa_textgrid(tg)) {
    # Agrupar tiers por hablante y extraer tier de words
    words_idx <- which(grepl("words", tier_names, ignore.case = TRUE))
    all_ip_dfs <- lapply(words_idx, function(wi) {
      spk <- trimws(sub("[[:space:]_-]*words$", "", tier_names[wi],
                        ignore.case = TRUE))
      if (!tg.isIntervalTier(tg, wi)) return(NULL)
      build_ips_from_words_tier(tg, wi, pause_min = pause_min,
                                speaker_label = if (nzchar(spk)) spk else "speaker-unique")
    })
    all_ip_dfs <- Filter(Negate(is.null), all_ip_dfs)
    if (length(all_ip_dfs) == 0) return(NULL)
    return(do.call(rbind, all_ip_dfs))
  }

  # Modo por hablante: cada tier = un hablante
  all_tiers <- lapply(seq_len(nTiers), function(ti) {
    if (!tg.isIntervalTier(tg, ti)) return(NULL)
    n <- tg.getNumberOfIntervals(tg, ti)
    data.frame(
      speaker = rep(tier_names[ti], n),
      start   = sapply(seq_len(n), function(i) tg.getIntervalStartTime(tg, ti, i)),
      end     = sapply(seq_len(n), function(i) tg.getIntervalEndTime(tg, ti, i)),
      label   = sapply(seq_len(n), function(i) tg.getLabel(tg, ti, i)),
      stringsAsFactors = FALSE
    )
  })
  all_tiers <- Filter(Negate(is.null), all_tiers)
  if (length(all_tiers) == 0) return(NULL)
  do.call(rbind, all_tiers)
}

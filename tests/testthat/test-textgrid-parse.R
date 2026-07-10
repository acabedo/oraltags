# Tests del parseo de TextGrid (R/textgrid_parse.R)

skip_if_not_installed("rPraat")
library(rPraat)

# ── fixtures ─────────────────────────────────────────────────
make_tg_mfa_sin_prefijo <- function() {
  tg <- tg.createNewTextGrid(0, 5)
  tg <- tg.insertNewIntervalTier(tg, 1, "words")
  tg <- tg.insertInterval(tg, "words", 0.5, 1.2, "hola")
  tg <- tg.insertInterval(tg, "words", 1.2, 1.8, "mundo")
  tg <- tg.insertInterval(tg, "words", 2.5, 3.0, "adios")
  tg <- tg.insertNewIntervalTier(tg, 2, "phones")
  tg <- tg.insertInterval(tg, "phones", 0.5, 0.8, "o")
  tg
}

make_tg_mfa_con_prefijo <- function(words_name, phones_name) {
  tg <- tg.createNewTextGrid(0, 5)
  tg <- tg.insertNewIntervalTier(tg, 1, words_name)
  tg <- tg.insertInterval(tg, words_name, 0.5, 1.8, "hola mundo")
  tg <- tg.insertNewIntervalTier(tg, 2, phones_name)
  tg <- tg.insertInterval(tg, phones_name, 0.5, 0.8, "o")
  tg
}

make_tg_generico <- function() {
  tg <- tg.createNewTextGrid(0, 5)
  tg <- tg.insertNewIntervalTier(tg, 1, "e")
  tg <- tg.insertInterval(tg, "e", 0.5, 1.8, "hola mundo")
  tg <- tg.insertNewIntervalTier(tg, 2, "anotacion")
  tg <- tg.insertInterval(tg, "anotacion", 2.0, 3.0, "grupo dos")
  tg
}

# ── is_mfa_textgrid ──────────────────────────────────────────
test_that("is_mfa_textgrid detecta tiers words/phones con y sin prefijo", {
  expect_true(is_mfa_textgrid(make_tg_mfa_sin_prefijo()))
  expect_true(is_mfa_textgrid(make_tg_mfa_con_prefijo("e_words", "e_phones")))
  expect_false(is_mfa_textgrid(make_tg_generico()))
})

# ── modo MFA: speaker derivado del nombre del tier ───────────
test_that("tier 'words' sin prefijo de hablante produce speaker-unique", {
  df <- parse_textgrid(make_tg_mfa_sin_prefijo(), mfa_mode = TRUE, pause_min = 0.3)
  expect_false(is.null(df))
  expect_equal(unique(df$speaker), "speaker-unique")
  # la pausa de 0.7 s entre "mundo" y "adios" corta el grupo entonativo
  expect_equal(df$label, c("hola mundo", "adios"))
})

test_that("prefijos de hablante se extraen de e_words, e - words y e words", {
  for (nm in c("e_words", "e - words", "e words", "E_WORDS")) {
    df <- parse_textgrid(make_tg_mfa_con_prefijo(nm, "e_phones"),
                         mfa_mode = TRUE, pause_min = 0.3)
    expect_equal(unique(df$speaker), sub("[[:space:]_-]*words$", "", nm,
                                         ignore.case = TRUE),
                 label = nm)
  }
})

# ── modo genérico: cualquier tier es unidad de anotación ─────
test_that("sin tiers words/phones cada intervalo es un grupo entonativo", {
  tg <- make_tg_generico()
  expect_false(is_mfa_textgrid(tg))
  df <- parse_textgrid(tg, mfa_mode = is_mfa_textgrid(tg))
  con_texto <- df[nzchar(trimws(df$label)), ]
  expect_setequal(con_texto$speaker, c("e", "anotacion"))
  expect_setequal(con_texto$label, c("hola mundo", "grupo dos"))
})

test_that("mfa_mode = TRUE sobre TextGrid no-MFA cae al modo genérico", {
  df <- parse_textgrid(make_tg_generico(), mfa_mode = TRUE)
  expect_true("e" %in% df$speaker)
})

# ── lectura con encoding automático (Praat guarda UTF-16) ────
test_that("read_textgrid lee TextGrids UTF-8 y UTF-16", {
  tg <- make_tg_mfa_sin_prefijo()
  f_utf8 <- tempfile(fileext = ".TextGrid")
  tg.write(tg, f_utf8)

  tg8 <- read_textgrid(f_utf8)
  expect_equal(tg.getNumberOfTiers(tg8), 2)

  # versión UTF-16 BE con BOM, como la escribe Praat
  txt <- readLines(f_utf8, encoding = "UTF-8", warn = FALSE)
  f_utf16 <- tempfile(fileext = ".TextGrid")
  con <- file(f_utf16, open = "w", encoding = "UTF-16")
  writeLines(txt, con)
  close(con)

  tg16 <- read_textgrid(f_utf16)
  expect_equal(tg.getNumberOfTiers(tg16), 2)
  df <- parse_textgrid(tg16, mfa_mode = TRUE, pause_min = 0.3)
  expect_equal(unique(df$speaker), "speaker-unique")
})

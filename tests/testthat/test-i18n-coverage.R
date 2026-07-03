test_that("toda clave envuelta en las apps tiene traducción", {
  json <- testthat::test_path("..", "..", "i18n", "translation.json")
  apps <- c(testthat::test_path("..", "..", "etiquetador_oral.R"),
            testthat::test_path("..", "..", "package", "inst", "app", "app.R"))
  for (app in apps) {
    expect_true(file.exists(app))
    expect_equal(i18n_missing_translations(app, json), character(0))
  }
})

test_that("ninguna clave del diccionario es huérfana (aparece en alguna fuente)", {
  # Las etiquetas y categorías del esquema se traducen SOLO visualmente
  # (tr_anot_value / tr_df_categories): en el código aparecen como literales
  # sin envolver y el almacenamiento queda en español canónico. Por eso la
  # completitud no exige tr(...)/i18n$t(...), solo que cada clave del
  # diccionario exista como texto en alguna fuente del proyecto.
  json <- testthat::test_path("..", "..", "i18n", "translation.json")
  d <- load_i18n_dict(json)
  srcs <- c(testthat::test_path("..", "..", "etiquetador_oral.R"),
            testthat::test_path("..", "..", "package", "inst", "app", "app.R"),
            list.files(testthat::test_path("..", "..", "R"),
                       full.names = TRUE, pattern = "[.]R$"))
  code <- paste(unlist(lapply(srcs, readLines, warn = FALSE, encoding = "UTF-8")),
                collapse = "\n")
  in_code <- function(k) {
    grepl(k, code, fixed = TRUE) ||
      grepl(gsub('"', '\\\\"', k), code, fixed = TRUE)  # comillas escapadas en el fuente
  }
  huerfanas <- d$es[!vapply(d$es, in_code, logical(1))]
  expect_equal(unname(huerfanas), character(0))
})

test_that("los diccionarios de la raíz y del paquete están sincronizados", {
  raiz <- testthat::test_path("..", "..", "i18n", "translation.json")
  pkg  <- testthat::test_path("..", "..", "package", "inst", "i18n", "translation.json")
  expect_identical(readLines(raiz, warn = FALSE, encoding = "UTF-8"),
                   readLines(pkg, warn = FALSE, encoding = "UTF-8"))
})

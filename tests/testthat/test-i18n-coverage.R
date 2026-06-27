test_that("toda clave del diccionario está envuelta en el código y toda envuelta tiene traducción", {
  code <- testthat::test_path("..", "..", "etiquetador_oral.R")
  json <- testthat::test_path("..", "..", "i18n", "translation.json")
  d <- load_i18n_dict(json)
  used <- i18n_used_keys(code)
  # forward: nada usado sin traducir
  expect_equal(i18n_missing_translations(code, json), character(0))
  # completitud: ninguna clave del diccionario queda sin envolver
  expect_equal(setdiff(d$es, used), character(0))
})

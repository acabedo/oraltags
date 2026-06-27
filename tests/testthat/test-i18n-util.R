test_that("load_i18n_dict lee es/en y tr traduce o cae a la clave", {
  f <- tempfile(fileext = ".json")
  writeLines('{"languages":["es","en"],"translation":[{"es":"Guardar","en":"Save"},{"es":"Solo","en":""}]}', f)
  d <- load_i18n_dict(f)
  expect_equal(tr("Guardar", "en", d), "Save")
  expect_equal(tr("Guardar", "es", d), "Guardar")
  expect_equal(tr("Solo", "en", d), "Solo")        # en vacío => cae a la clave
  expect_equal(tr("Inexistente", "en", d), "Inexistente")
})

test_that("load_i18n_dict sin archivo devuelve vacío", {
  d <- load_i18n_dict(tempfile())
  expect_equal(length(d$es), 0)
})

test_that("i18n_used_keys extrae claves de i18n$t y tr", {
  f <- tempfile(fileext = ".R")
  writeLines(c('x <- i18n$t("Anotaciones")',
               'showNotification(tr("Fila guardada", session_lang()))',
               'y <- i18n$t("Contexto")'), f)
  k <- i18n_used_keys(f)
  expect_setequal(k, c("Anotaciones", "Fila guardada", "Contexto"))
})

test_that("i18n_missing_translations detecta claves sin traducción", {
  jf <- tempfile(fileext = ".json")
  writeLines('{"languages":["es","en"],"translation":[{"es":"Anotaciones","en":"Annotations"}]}', jf)
  cf <- tempfile(fileext = ".R")
  writeLines(c('i18n$t("Anotaciones")', 'i18n$t("SinTraducir")'), cf)
  expect_equal(i18n_missing_translations(cf, jf), "SinTraducir")
})

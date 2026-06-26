test_that("load_prefs devuelve defaults sin archivo", {
  p <- load_prefs(tempfile())
  expect_false(p$animo_enabled)
  expect_equal(p$animo_custom, "")
  expect_equal(p$plot_font_scale, 1)
})

test_that("save_prefs/load_prefs hacen round-trip", {
  f <- tempfile()
  save_prefs(list(animo_enabled = TRUE, animo_custom = "¡Ánimo!", plot_font_scale = 1.5), f)
  p <- load_prefs(f)
  expect_true(p$animo_enabled)
  expect_equal(p$animo_custom, "¡Ánimo!")
  expect_equal(p$plot_font_scale, 1.5)
})

test_that("load_prefs ignora líneas mal formadas y claves desconocidas", {
  f <- tempfile()
  writeLines(c("basura", "desconocida\tx", "animo_enabled\tTRUE"), f)
  p <- load_prefs(f)
  expect_true(p$animo_enabled)
  expect_equal(p$plot_font_scale, 1)
})

test_that("choose_message: propio si lo hay, si no una predefinida", {
  expect_equal(choose_message("  hola  ", c("a", "b")), "hola")
  set.seed(1); expect_true(choose_message("", c("a", "b")) %in% c("a", "b"))
  expect_equal(choose_message("", character(0)), "")
  expect_equal(choose_message(NULL, character(0)), "")
})

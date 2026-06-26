test_that("format_cita formatea a 2 decimales", {
  expect_equal(format_cita("muestra_1", 0.3, 3.180005), "(muestra_1, 0.30-3.18)")
  expect_equal(format_cita("c", 1, 2), "(c, 1.00-2.00)")
})

test_that("recompute_contexto arma 'speaker: label' en ventana", {
  df <- data.frame(speaker = c("A","B","A"), label = c("uno","dos","tres"),
                   stringsAsFactors = FALSE)
  out <- recompute_contexto(df, window = 1)
  expect_equal(out$contexto[1], "A: uno | B: dos")
  expect_equal(out$contexto[2], "A: uno | B: dos | A: tres")
  expect_equal(out$contexto[3], "B: dos | A: tres")
})

test_that("recompute_contexto omite labels vacíos y respeta speaker vacío", {
  df <- data.frame(speaker = c("", "B"), label = c("hola", ""),
                   stringsAsFactors = FALSE)
  out <- recompute_contexto(df, window = 5)
  expect_equal(out$contexto[1], "hola")
})

test_that("corpus_base_name limpia ruta, extensión y prefijo", {
  expect_equal(corpus_base_name("/x/muestra_1.TextGrid"), "muestra_1")
  expect_equal(corpus_base_name("analisis_muestra_1.txt"), "muestra_1")
  expect_equal(corpus_base_name(NULL), "corpus")
  expect_equal(corpus_base_name(""), "corpus")
})

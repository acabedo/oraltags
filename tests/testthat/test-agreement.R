test_that("agreement_percent cuenta filas con acuerdo total", {
  mat <- rbind(c("a","a"), c("a","b"), c("c","c"), c("d","e"))
  expect_equal(agreement_percent(mat), 50)
})

test_that("cohen_kappa: perfecto=1, azar=0", {
  expect_equal(cohen_kappa(c("x","y","x","y"), c("x","y","x","y")), 1)
  a <- c("yes","yes","no","no"); b <- c("yes","no","yes","no")
  expect_equal(cohen_kappa(a, b), 0)
})

test_that("cohen_kappa_weighted: ordinal de 2 niveles en total desacuerdo = -1", {
  expect_equal(cohen_kappa_weighted(c("1","2"), c("2","1")), -1)
  expect_equal(cohen_kappa_weighted(c("1","2","3"), c("1","2","3")), 1)
})

test_that("fleiss_kappa: perfecto=1 y caso conocido", {
  expect_equal(fleiss_kappa(rbind(c("a","a","a"), c("b","b","b"))), 1)
  mat <- rbind(c("a","b","a"), c("b","a","b"))
  expect_equal(fleiss_kappa(mat), -1/3, tolerance = 1e-6)
})

test_that("mean_pairwise_kappa promedia parejas", {
  mat <- rbind(c("a","a","a"), c("b","b","b"), c("c","c","c"))
  expect_equal(mean_pairwise_kappa(mat), 1)
})

test_that("interpret_kappa usa la escala Landis & Koch", {
  expect_equal(interpret_kappa(NA), "N/D")
  expect_equal(interpret_kappa(-0.1), "Pobre")
  expect_equal(interpret_kappa(0.5), "Moderado")
  expect_equal(interpret_kappa(0.9), "Casi perfecto")
})

test_that("seg_key empareja por start/end/label y build_rater_matrix usa intersección", {
  d1 <- data.frame(start = c(0, 1, 2), end = c(1, 2, 3),
                   label = c("A", "B", "C"), anot1 = c("x", "y", "z"),
                   stringsAsFactors = FALSE)
  d2 <- data.frame(start = c(0, 1, 9), end = c(1, 2, 9),
                   label = c("A", "B", "Z"), anot1 = c("x", "w", "q"),
                   stringsAsFactors = FALSE)
  mat <- build_rater_matrix(list(j1 = d1, j2 = d2), "anot1")
  expect_equal(nrow(mat), 2)            # solo A y B son comunes
  expect_equal(ncol(mat), 2)
  expect_setequal(mat[, "j1"], c("x", "y"))
})

test_that("build_rater_matrix devuelve NULL sin segmentos comunes", {
  d1 <- data.frame(start = 0, end = 1, label = "A", anot1 = "x",
                   stringsAsFactors = FALSE)
  d2 <- data.frame(start = 5, end = 6, label = "Z", anot1 = "q",
                   stringsAsFactors = FALSE)
  expect_null(build_rater_matrix(list(d1, d2), "anot1"))
})

test_that("compute_agreement_for_var: 2 jueces usa Cohen; 3 usa Fleiss", {
  mat2 <- matrix(c("a","a","b","a","a","b"), ncol = 2)  # 3 filas, 2 jueces
  r2 <- compute_agreement_for_var(mat2)
  expect_equal(r2$n, 3)
  expect_false(is.na(r2$cohen))
  expect_true(is.na(r2$fleiss))

  mat3 <- matrix(c("a","a","a", "a","a","a", "a","a","a"), ncol = 3)
  r3 <- compute_agreement_for_var(mat3)
  expect_equal(r3$fleiss, 1)
  expect_equal(r3$interpretation, "Casi perfecto")
})

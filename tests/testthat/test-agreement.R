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

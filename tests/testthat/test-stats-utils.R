test_that("stat_skewness y stat_kurtosis: casos básicos", {
  expect_equal(stat_skewness(c(1, 2, 3, 4, 5)), 0)        # simétrico
  expect_true(is.na(stat_skewness(c(1, 2))))              # n<3
  expect_true(is.na(stat_skewness(rep(5, 10))))           # sd=0
  expect_true(is.na(stat_kurtosis(c(1, 2, 3))))           # n<4
  # curtosis de exceso de una uniforme discreta es negativa
  expect_true(stat_kurtosis(1:9) < 0)
})

test_that("freq_table separa multivalor, limpia y ordena desc", {
  f <- freq_table(c("a", "b; c", "a", NA, "", "c"))
  expect_equal(as.integer(f[["a"]]), 2)
  expect_equal(as.integer(f[["c"]]), 2)
  expect_equal(as.integer(f[["b"]]), 1)
  expect_equal(sum(f), 5)
  expect_equal(length(freq_table(c(NA, "", "  "))), 0L)
})

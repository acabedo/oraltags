test_that("stat_skewness y stat_kurtosis: casos básicos", {
  expect_equal(stat_skewness(c(1, 2, 3, 4, 5)), 0)        # simétrico
  expect_true(is.na(stat_skewness(c(1, 2))))              # n<3
  expect_true(is.na(stat_skewness(rep(5, 10))))           # sd=0
  expect_true(is.na(stat_kurtosis(c(1, 2, 3))))           # n<4
  # curtosis de exceso de una uniforme discreta es negativa
  expect_true(stat_kurtosis(1:9) < 0)
})

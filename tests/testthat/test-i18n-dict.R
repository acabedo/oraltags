test_that("translation.json es válido y toda entrada tiene es y en no vacíos", {
  jp <- testthat::test_path("..", "..", "i18n", "translation.json")
  expect_true(file.exists(jp))
  d <- load_i18n_dict(jp)
  expect_gt(length(d$es), 50)
  expect_equal(length(d$es), length(d$en))
  expect_true(all(nzchar(d$es)))
  expect_true(all(nzchar(d$en)))
  expect_equal(anyDuplicated(d$es), 0)   # sin claves duplicadas
})

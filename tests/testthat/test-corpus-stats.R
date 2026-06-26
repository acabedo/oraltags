test_that("describe_numeric sin grupos", {
  df <- data.frame(x = c(1, 2, 3, 4))
  d <- describe_numeric(df, "x")
  expect_equal(d$grupo, "TOTAL")
  expect_equal(d$n, 4)
  expect_equal(d$media, 2.5)
  expect_equal(d$mediana, 2.5)
  expect_equal(d$min, 1)
  expect_equal(d$max, 4)
})

test_that("describe_numeric con 1 grupo", {
  df <- data.frame(g = c("A","A","B","B"), x = c(1, 3, 10, 20),
                   stringsAsFactors = FALSE)
  d <- describe_numeric(df, "x", "g")
  expect_equal(nrow(d), 2)
  expect_equal(d$media[d$grupo == "A"], 2)
  expect_equal(d$media[d$grupo == "B"], 15)
})

test_that("describe_numeric con 2 grupos genera la combinación", {
  df <- data.frame(g1 = c("A","A","B"), g2 = c("x","y","x"),
                   v = c(1, 2, 3), stringsAsFactors = FALSE)
  d <- describe_numeric(df, "v", c("g1", "g2"))
  expect_equal(nrow(d), 3)
  expect_true(all(grepl(" \\| ", d$grupo)))
})

test_that("corpus_file_summary cuenta archivos y filas", {
  df <- data.frame(filename = c("f1","f1","f2"), x = 1:3,
                   stringsAsFactors = FALSE)
  s <- corpus_file_summary(df)
  expect_equal(s$n_files, 2)
  expect_equal(s$n_rows, 3)
  expect_equal(s$per_file$n_filas[s$per_file$filename == "f1"], 2)
})

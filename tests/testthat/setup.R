# Sourcea los helpers puros del proyecto para que estén disponibles en los tests.
for (f in c("stats_utils.R", "agreement.R", "corpus_stats.R")) {
  p <- testthat::test_path("..", "..", "R", f)
  if (file.exists(p)) source(p)
}

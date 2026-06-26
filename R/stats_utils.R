# R/stats_utils.R — utilidades estadísticas puras (sin dependencias de Shiny)

# Asimetría (sesgo). NA si n<3 o desviación típica 0.
stat_skewness <- function(x) {
  x <- x[!is.na(x)]; n <- length(x)
  if (n < 3) return(NA_real_)
  m <- mean(x); s <- stats::sd(x)
  if (is.na(s) || s == 0) return(NA_real_)
  (sum((x - m)^3) / n) / s^3
}

# Curtosis de exceso. NA si n<4 o desviación típica 0.
stat_kurtosis <- function(x) {
  x <- x[!is.na(x)]; n <- length(x)
  if (n < 4) return(NA_real_)
  m <- mean(x); s <- stats::sd(x)
  if (is.na(s) || s == 0) return(NA_real_)
  (sum((x - m)^4) / n) / s^4 - 3
}

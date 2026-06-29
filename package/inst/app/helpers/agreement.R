# R/agreement.R — medidas de acuerdo entre jueces (puras, base R; irr opcional)

# % de filas (casos completos) en las que TODOS los jueces coinciden.
agreement_percent <- function(mat) {
  mat <- mat[stats::complete.cases(mat), , drop = FALSE]
  if (nrow(mat) == 0) return(NA_real_)
  agree <- apply(mat, 1, function(r) length(unique(r)) == 1)
  mean(agree) * 100
}

# Kappa de Cohen (2 jueces, nominal).
cohen_kappa <- function(a, b) {
  ok <- !is.na(a) & !is.na(b); a <- a[ok]; b <- b[ok]
  n <- length(a); if (n == 0) return(NA_real_)
  lev <- union(unique(a), unique(b))
  if (length(lev) <= 1) return(1)  # un único nivel y todos coinciden
  a <- factor(a, levels = lev); b <- factor(b, levels = lev)
  tab <- table(a, b)
  po <- sum(diag(tab)) / n
  pe <- sum(rowSums(tab) * colSums(tab)) / n^2
  if (pe == 1) return(if (po == 1) 1 else NA_real_)
  (po - pe) / (1 - pe)
}

# Kappa de Cohen ponderado (2 jueces, ordinal). Niveles ordenados numéricamente
# si parsean a número; si no, orden alfabético.
cohen_kappa_weighted <- function(a, b, weights = c("linear", "quadratic")) {
  weights <- match.arg(weights)
  ok <- !is.na(a) & !is.na(b); a <- a[ok]; b <- b[ok]
  n <- length(a); if (n == 0) return(NA_real_)
  lev <- sort(union(unique(a), unique(b)))
  num <- suppressWarnings(as.numeric(lev))
  if (!any(is.na(num))) lev <- lev[order(num)]
  k <- length(lev); if (k <= 1) return(1)
  a <- factor(a, levels = lev); b <- factor(b, levels = lev)
  O <- table(a, b) / n
  r <- rowSums(O); cc <- colSums(O)
  E <- outer(r, cc)
  idx <- seq_len(k)
  W <- switch(weights,
    linear    = abs(outer(idx, idx, "-")) / (k - 1),
    quadratic = (outer(idx, idx, "-"))^2 / (k - 1)^2)
  denom <- sum(W * E)
  if (denom == 0) return(NA_real_)
  1 - sum(W * O) / denom
}

# Kappa de Fleiss (m>=2 jueces, mismo nº de valoraciones por sujeto).
fleiss_kappa <- function(mat) {
  mat <- mat[stats::complete.cases(mat), , drop = FALSE]
  N <- nrow(mat); m <- ncol(mat)
  if (N == 0 || m < 2) return(NA_real_)
  cats <- sort(unique(as.vector(mat)))
  if (length(cats) <= 1) return(1)
  nij <- t(apply(mat, 1, function(r) table(factor(r, levels = cats))))
  Pi <- (rowSums(nij^2) - m) / (m * (m - 1))
  Pbar <- mean(Pi)
  pj <- colSums(nij) / (N * m)
  Pe <- sum(pj^2)
  if (Pe == 1) return(if (Pbar == 1) 1 else NA_real_)
  (Pbar - Pe) / (1 - Pe)
}

# Media de Cohen sobre todas las parejas de jueces.
mean_pairwise_kappa <- function(mat, weighted = FALSE, weights = "linear") {
  m <- ncol(mat); if (m < 2) return(NA_real_)
  ks <- c()
  for (i in 1:(m - 1)) for (j in (i + 1):m) {
    k <- if (weighted) cohen_kappa_weighted(mat[, i], mat[, j], weights)
         else          cohen_kappa(mat[, i], mat[, j])
    ks <- c(ks, k)
  }
  mean(ks, na.rm = TRUE)
}

# Interpretación verbal (Landis & Koch, 1977).
interpret_kappa <- function(k) {
  if (length(k) != 1 || is.na(k)) return("N/D")
  if (k < 0)    return("Pobre")
  if (k < 0.20) return("Leve")
  if (k < 0.40) return("Aceptable")
  if (k < 0.60) return("Moderado")
  if (k < 0.80) return("Considerable")
  "Casi perfecto"
}

# Krippendorff's alpha vía irr (opcional). NA si irr no está instalado.
krippendorff_alpha <- function(mat, method = "nominal") {
  if (!requireNamespace("irr", quietly = TRUE)) return(NA_real_)
  res <- try(suppressWarnings(irr::kripp.alpha(t(mat), method = method)), silent = TRUE)
  if (inherits(res, "try-error")) return(NA_real_)
  as.numeric(res$value)
}

# ── Capa de datos ──────────────────────────────────────────────

# Lee un archivo de análisis (TSV por defecto; autodetecta coma).
read_analysis_file <- function(path) {
  first <- readLines(path, n = 1, warn = FALSE, encoding = "UTF-8")
  sep <- if (grepl("\t", first)) "\t" else ","
  read.table(path, sep = sep, header = TRUE, stringsAsFactors = FALSE,
             quote = "", na.strings = "", fileEncoding = "UTF-8",
             check.names = FALSE)
}

# Clave de segmento: start/end redondeados + label normalizado.
seg_key <- function(df) {
  paste(round(as.numeric(df$start), 3),
        round(as.numeric(df$end), 3),
        trimws(tolower(as.character(df$label))), sep = "|")
}

# Matriz filas-comunes × jueces para una variable. NULL si no hay intersección.
build_rater_matrix <- function(dfs, var) {
  keys_list <- lapply(dfs, seg_key)
  common <- Reduce(intersect, keys_list)
  if (length(common) == 0) return(NULL)
  common <- sort(common)
  cols <- lapply(dfs, function(df) {
    if (!var %in% names(df)) return(rep(NA_character_, length(common)))
    k <- seg_key(df)
    v <- as.character(df[[var]])[match(common, k)]
    v[!nzchar(trimws(ifelse(is.na(v), "", v)))] <- NA
    v
  })
  mat <- do.call(cbind, cols)
  dimnames(mat) <- list(common, names(dfs))
  mat
}

# Calcula todas las medidas para una variable (matriz filas × jueces).
compute_agreement_for_var <- function(mat, ordinal = FALSE) {
  m <- ncol(mat)
  cmat <- mat[stats::complete.cases(mat), , drop = FALSE]
  n <- nrow(cmat)
  out <- list(n = n, pct = agreement_percent(mat),
              cohen = NA_real_, fleiss = NA_real_,
              mean_pairwise = NA_real_, krippendorff = NA_real_,
              weighted = ordinal, interpretation = "N/D")
  if (n == 0) return(out)
  if (m == 2) {
    out$cohen <- if (ordinal) cohen_kappa_weighted(cmat[, 1], cmat[, 2])
                 else          cohen_kappa(cmat[, 1], cmat[, 2])
    out$interpretation <- interpret_kappa(out$cohen)
  } else {
    out$fleiss <- fleiss_kappa(cmat)
    out$mean_pairwise <- mean_pairwise_kappa(cmat, weighted = ordinal)
    out$interpretation <- interpret_kappa(out$fleiss)
  }
  out$krippendorff <- krippendorff_alpha(cmat,
                        method = if (ordinal) "ordinal" else "nominal")
  out
}

# Pestañas «Coincidencia» y «Corpus» — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Añadir a Oraltags dos pestañas nuevas: «Coincidencia» (acuerdo entre 2–10 jueces con Cohen/Fleiss/Krippendorff) y «Corpus» (visión global de `analisis_todos.txt` con descriptivos y agrupación hasta 4 variables).

**Architecture:** Las funciones de cálculo (acuerdo y descriptivos) se extraen a archivos puros en `R/` sin dependencias de Shiny ni de las librerías acústicas pesadas, de modo que se testean con `testthat`. `etiquetador_oral.R` los `source()`-a tras fijar `APP_DIR` y añade dos `tabPanel` con su lógica de servidor que solo orquesta esas funciones puras.

**Tech Stack:** R 4.5+, Shiny, DT, base R + paquete `stats`. `irr` opcional (Krippendorff α), detectado con `requireNamespace` igual que `praatpicture`. Tests con `testthat`.

## Global Constraints

- App de un solo archivo `etiquetador_oral.R` que termina en `shinyApp(ui, server)`; NO sourcear el archivo entero en tests (lanzaría la app).
- Sin dependencias nuevas OBLIGATORIAS. `irr` es opcional: detectar con `requireNamespace("irr", quietly = TRUE)` y degradar a `NA` si no está.
- `n_anot <- 33`; las variables de anotación son `anot1..anot33`. Etiquetas legibles vía `rv$anot_defs[[cn]]$label` (quitar `:` final).
- Columnas numéricas analizables: `stat_num_cols` (ya definido en server). Etiquetas vía `stat_col_label(cn)` (ya definido en server).
- Estilo gráfico base R coherente: barras `#3b82f6`; boxplots relleno `#93c5fd`, borde `#1d4ed8`.
- `APP_DIR` se fija en `etiquetador_oral.R` (~línea 47) y se hace `setwd(APP_DIR)`. Los `source()` de helpers usan `file.path(APP_DIR, "R", "<archivo>.R")`.
- Lectura de TSV de análisis: `sep="\t"`, `header=TRUE`, `quote=""`, `na.strings=""`, `fileEncoding="UTF-8"`, `stringsAsFactors=FALSE`.
- Helper de nulos `%||%` ya existe en server (`function(a,b) if (!is.null(a)) a else b`).
- Emparejado de segmentos por clave `paste(round(start,3), round(end,3), trimws(tolower(label)), sep="|")`; se usa la INTERSECCIÓN entre todos los jueces.
- Backup del código v2.0 ya existe en `backup_codigo/etiquetador_oral_v2.0_20260626.R`. No tocar.

---

### Task 1: Scaffolding de helpers + utilidades estadísticas compartidas

Extrae `stat_skewness`/`stat_kurtosis` (hoy definidas dentro de `server`) a un archivo puro reutilizable, crea la infraestructura de tests y conecta el `source()` desde la app.

**Files:**
- Create: `R/stats_utils.R`
- Create: `tests/testthat/setup.R`
- Create: `tests/testthat/test-stats-utils.R`
- Modify: `etiquetador_oral.R` (añadir `source()` tras `setwd(APP_DIR)`, ~línea 51; eliminar definiciones duplicadas de `stat_skewness`/`stat_kurtosis` en server, ~líneas 2339-2352)

**Interfaces:**
- Produces:
  - `stat_skewness(x) -> double` (asimetría; `NA` si n<3 o sd==0)
  - `stat_kurtosis(x) -> double` (curtosis de exceso; `NA` si n<4 o sd==0)

- [ ] **Step 1: Crear `R/stats_utils.R` con las funciones puras**

```r
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
```

- [ ] **Step 2: Crear `tests/testthat/setup.R` (sourcea los helpers antes de los tests)**

```r
# Sourcea los helpers puros del proyecto para que estén disponibles en los tests.
for (f in c("stats_utils.R", "agreement.R", "corpus_stats.R")) {
  p <- testthat::test_path("..", "..", "R", f)
  if (file.exists(p)) source(p)
}
```

- [ ] **Step 3: Crear `tests/testthat/test-stats-utils.R` (test que falla)**

```r
test_that("stat_skewness y stat_kurtosis: casos básicos", {
  expect_equal(stat_skewness(c(1, 2, 3, 4, 5)), 0)        # simétrico
  expect_true(is.na(stat_skewness(c(1, 2))))              # n<3
  expect_true(is.na(stat_skewness(rep(5, 10))))           # sd=0
  expect_true(is.na(stat_kurtosis(c(1, 2, 3))))           # n<4
  # curtosis de exceso de una uniforme discreta es negativa
  expect_true(stat_kurtosis(1:9) < 0)
})
```

- [ ] **Step 4: Ejecutar el test y verificar que FALLA**

Run: `Rscript -e 'testthat::test_dir("tests/testthat", stop_on_failure = TRUE)'`
Expected: FAIL — `could not find function "stat_skewness"` (aún no se sourcea porque `R/agreement.R` y `R/corpus_stats.R` no existen y `setup.R` los salta, pero `stats_utils.R` sí debería cargar). Si `stats_utils.R` ya existe, el test pasa directamente; en ese caso continúa.

- [ ] **Step 5: Conectar el `source()` en `etiquetador_oral.R`**

Tras el bloque que hace `setwd(APP_DIR)` (~línea 51), añade:

```r
# ── Helpers puros (acuerdo entre jueces y descriptivos de corpus) ──
for (.f in c("stats_utils.R", "agreement.R", "corpus_stats.R")) {
  .p <- file.path(APP_DIR, "R", .f)
  if (file.exists(.p)) source(.p)
}
```

- [ ] **Step 6: Eliminar las definiciones duplicadas en `server`**

Borra el bloque de `etiquetador_oral.R` (~líneas 2338-2352) que define `stat_skewness` y `stat_kurtosis` dentro de `server` (incluido el comentario `# Kurtosis y asimetría (sin paquetes extra)`). Ahora se resuelven desde el global vía `source()`.

- [ ] **Step 7: Verificar que el test pasa y que el archivo parsea**

Run: `Rscript -e 'testthat::test_dir("tests/testthat", stop_on_failure = TRUE)'`
Expected: PASS

Run: `Rscript -e 'invisible(parse("etiquetador_oral.R")); cat("OK\n")'`
Expected: `OK`

- [ ] **Step 8: Commit**

```bash
git add R/stats_utils.R tests/testthat/setup.R tests/testthat/test-stats-utils.R etiquetador_oral.R
git commit -m "refactor: extraer stat_skewness/stat_kurtosis a R/stats_utils.R + tests"
```

---

### Task 2: Métricas de acuerdo (funciones puras)

**Files:**
- Create: `R/agreement.R`
- Create: `tests/testthat/test-agreement.R`

**Interfaces:**
- Produces:
  - `agreement_percent(mat) -> double` (% filas con acuerdo total; sobre casos completos)
  - `cohen_kappa(a, b) -> double`
  - `cohen_kappa_weighted(a, b, weights = c("linear","quadratic")) -> double`
  - `fleiss_kappa(mat) -> double`
  - `mean_pairwise_kappa(mat, weighted = FALSE, weights = "linear") -> double`
  - `interpret_kappa(k) -> character` (escala Landis & Koch en español)
  - `krippendorff_alpha(mat, method = "nominal") -> double` (NA si `irr` no instalado)
  - `mat`: matriz `filas × jueces` de caracteres, con `NA` para celdas vacías.

- [ ] **Step 1: Escribir los tests (fallan)**

```r
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
```

- [ ] **Step 2: Ejecutar y verificar FALLO**

Run: `Rscript -e 'testthat::test_dir("tests/testthat", stop_on_failure = TRUE)'`
Expected: FAIL — `could not find function "cohen_kappa"`

- [ ] **Step 3: Implementar `R/agreement.R`**

```r
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
  res <- try(irr::kripp.alpha(t(mat), method = method), silent = TRUE)
  if (inherits(res, "try-error")) return(NA_real_)
  as.numeric(res$value)
}
```

- [ ] **Step 4: Ejecutar y verificar PASA**

Run: `Rscript -e 'testthat::test_dir("tests/testthat", stop_on_failure = TRUE)'`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add R/agreement.R tests/testthat/test-agreement.R
git commit -m "feat: funciones puras de acuerdo entre jueces (Cohen, Fleiss, etc.)"
```

---

### Task 3: Capa de datos del acuerdo (lectura + emparejado + orquestación)

**Files:**
- Modify: `R/agreement.R` (añadir funciones de datos al final)
- Modify: `tests/testthat/test-agreement.R` (añadir tests)

**Interfaces:**
- Consumes: `agreement_percent`, `cohen_kappa`, `cohen_kappa_weighted`, `fleiss_kappa`, `mean_pairwise_kappa`, `interpret_kappa`, `krippendorff_alpha` (Task 2).
- Produces:
  - `read_analysis_file(path) -> data.frame` (autodetecta tab vs coma)
  - `seg_key(df) -> character` (clave de segmento por fila)
  - `build_rater_matrix(dfs, var) -> matrix|NULL` (filas comunes × jueces; `NULL` si no hay intersección)
  - `compute_agreement_for_var(mat, ordinal = FALSE) -> list` con campos `n, pct, cohen, fleiss, mean_pairwise, krippendorff, weighted, interpretation`.

- [ ] **Step 1: Añadir tests (fallan)**

```r
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
```

- [ ] **Step 2: Ejecutar y verificar FALLO**

Run: `Rscript -e 'testthat::test_dir("tests/testthat", stop_on_failure = TRUE)'`
Expected: FAIL — `could not find function "build_rater_matrix"`

- [ ] **Step 3: Añadir las funciones de datos al final de `R/agreement.R`**

```r
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
```

- [ ] **Step 4: Ejecutar y verificar PASA**

Run: `Rscript -e 'testthat::test_dir("tests/testthat", stop_on_failure = TRUE)'`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add R/agreement.R tests/testthat/test-agreement.R
git commit -m "feat: lectura, emparejado por segmento y orquestación del acuerdo"
```

---

### Task 4: Descriptivos de corpus (funciones puras)

**Files:**
- Create: `R/corpus_stats.R`
- Create: `tests/testthat/test-corpus-stats.R`

**Interfaces:**
- Consumes: `stat_skewness`, `stat_kurtosis` (Task 1).
- Produces:
  - `describe_numeric(df, num_col, group_cols = character(0)) -> data.frame`
    con columnas `grupo, n, media, sd, min, p25, mediana, p75, max, asimetria, curtosis`.
  - `corpus_file_summary(df) -> list(n_files, n_rows, n_vars, per_file)`.

- [ ] **Step 1: Escribir tests (fallan)**

```r
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
```

- [ ] **Step 2: Ejecutar y verificar FALLO**

Run: `Rscript -e 'testthat::test_dir("tests/testthat", stop_on_failure = TRUE)'`
Expected: FAIL — `could not find function "describe_numeric"`

- [ ] **Step 3: Implementar `R/corpus_stats.R`**

```r
# R/corpus_stats.R — descriptivos del corpus (puros; usan R/stats_utils.R)

# Descriptivos de un vector numérico. Devuelve siempre 1 fila.
.describe_vec <- function(x) {
  x <- suppressWarnings(as.numeric(x)); x <- x[!is.na(x)]
  n <- length(x)
  if (n == 0) {
    return(data.frame(n = 0, media = NA, sd = NA, min = NA, p25 = NA,
                      mediana = NA, p75 = NA, max = NA,
                      asimetria = NA, curtosis = NA))
  }
  data.frame(
    n = n, media = mean(x), sd = stats::sd(x), min = min(x),
    p25 = stats::quantile(x, .25, names = FALSE), mediana = stats::median(x),
    p75 = stats::quantile(x, .75, names = FALSE), max = max(x),
    asimetria = stat_skewness(x), curtosis = stat_kurtosis(x)
  )
}

# Descriptivos de una variable numérica, opcionalmente por hasta N grupos.
describe_numeric <- function(df, num_col, group_cols = character(0)) {
  stopifnot(num_col %in% names(df))
  group_cols <- group_cols[group_cols %in% names(df)]
  if (length(group_cols) == 0) {
    return(cbind(data.frame(grupo = "TOTAL", stringsAsFactors = FALSE),
                 .describe_vec(df[[num_col]])))
  }
  key <- do.call(paste, c(lapply(group_cols, function(g) as.character(df[[g]])),
                          sep = " | "))
  sp <- split(df[[num_col]], key, drop = TRUE)
  rows <- lapply(names(sp), function(k)
    cbind(data.frame(grupo = k, stringsAsFactors = FALSE), .describe_vec(sp[[k]])))
  out <- do.call(rbind, rows)
  out[order(out$grupo), , drop = FALSE]
}

# Resumen de conteos del corpus consolidado.
corpus_file_summary <- function(df) {
  has_fn <- "filename" %in% names(df)
  per_file <- NULL
  if (has_fn) {
    tb <- table(df$filename)
    per_file <- data.frame(filename = names(tb),
                           n_filas = as.integer(tb),
                           stringsAsFactors = FALSE)
  }
  list(n_files = if (has_fn) length(unique(df$filename)) else NA_integer_,
       n_rows = nrow(df), n_vars = ncol(df), per_file = per_file)
}
```

- [ ] **Step 4: Ejecutar y verificar PASA**

Run: `Rscript -e 'testthat::test_dir("tests/testthat", stop_on_failure = TRUE)'`
Expected: PASS (toda la suite: stats-utils, agreement, corpus-stats)

- [ ] **Step 5: Commit**

```bash
git add R/corpus_stats.R tests/testthat/test-corpus-stats.R
git commit -m "feat: descriptivos de corpus y resumen de archivos (puros) + tests"
```

---

### Task 5: Pestaña «Coincidencia» (UI + servidor)

**Files:**
- Modify: `etiquetador_oral.R` (UI: añadir `tabPanel("Coincidencia", ...)` tras «Estadísticas», ~línea 608; server: añadir bloque antes del cierre `}` de `server`, ~línea 2387)

**Interfaces:**
- Consumes: `read_analysis_file`, `build_rater_matrix`, `compute_agreement_for_var`, `interpret_kappa` (Tasks 2-3); `rv$anot_defs`, `n_anot`, `%||%` (existentes).

- [ ] **Step 1: Añadir el `tabPanel` de UI**

Insertar tras el `tabPanel("Estadísticas", ...)` (cierre en ~línea 608), antes de `tabPanel("Configuración", ...)`:

```r
            tabPanel("Coincidencia", br(),
              h5("Acuerdo entre anotadores (jueces)"),
              div(class = "small-helper-text",
                  "Sube de 2 a 10 archivos de análisis (analisis_*.txt) del MISMO ",
                  "corpus anotado por distintas personas. Se comparan los segmentos ",
                  "comunes (mismo start/end/label)."),
              fileInput("coinc_files", "Archivos de análisis (2–10):",
                        multiple = TRUE, accept = c(".txt", ".tsv", ".csv"),
                        width = "100%"),
              DTOutput("coinc_files_info"),
              hr(),
              fluidRow(
                column(6, selectInput("coinc_vars", "Variables a comparar:",
                                      choices = NULL, multiple = TRUE, width = "100%")),
                column(6, selectInput("coinc_ord_vars",
                                      "Variables ordinales (kappa ponderado):",
                                      choices = NULL, multiple = TRUE, width = "100%"))
              ),
              actionButton("coinc_run", "Calcular acuerdo",
                           class = "btn-primary btn-sm"),
              hr(),
              verbatimTextOutput("coinc_summary"),
              DTOutput("coinc_table"),
              br(),
              plotOutput("coinc_barplot", height = 420),
              br(),
              fluidRow(
                column(6, selectInput("coinc_confusion_var",
                                      "Matriz de confusión (solo 2 jueces):",
                                      choices = NULL, width = "100%"))
              ),
              verbatimTextOutput("coinc_confusion")
            ),
```

- [ ] **Step 2: Añadir la lógica de servidor**

Insertar antes del cierre `}` de `server` (~línea 2387, tras el bloque `output$stat_summary`):

```r
  # ====================== COINCIDENCIA (acuerdo entre jueces) ======================
  coinc_raw <- reactive({
    req(input$coinc_files)
    fi <- input$coinc_files
    if (nrow(fi) > 10) {
      showNotification("Más de 10 archivos: se usan los 10 primeros.", type = "warning")
      fi <- fi[1:10, ]
    }
    dfs <- lapply(seq_len(nrow(fi)), function(i)
      tryCatch(read_analysis_file(fi$datapath[i]), error = function(e) NULL))
    names(dfs) <- tools::file_path_sans_ext(fi$name)
    dfs[!vapply(dfs, is.null, logical(1))]
  })

  output$coinc_files_info <- renderDT({
    dfs <- coinc_raw()
    req(length(dfs) >= 1)
    data.frame(Archivo = names(dfs),
               Filas = vapply(dfs, nrow, integer(1)),
               check.names = FALSE)
  }, options = list(dom = "t"), rownames = FALSE)

  coinc_var_label <- function(cn) {
    if (!is.null(rv$anot_defs[[cn]])) sub(":$", "", trimws(rv$anot_defs[[cn]]$label)) else cn
  }

  observeEvent(coinc_raw(), {
    dfs <- coinc_raw()
    if (length(dfs) < 2) return()
    anot_cols <- paste0("anot", seq_len(n_anot))
    avail <- Filter(function(cn) {
      all(vapply(dfs, function(d) cn %in% names(d), logical(1))) &&
        sum(vapply(dfs, function(d)
          sum(nzchar(trimws(ifelse(is.na(d[[cn]]), "", as.character(d[[cn]]))))),
          integer(1))) >= 2
    }, anot_cols)
    choices <- setNames(avail, vapply(avail, coinc_var_label, character(1)))
    updateSelectInput(session, "coinc_vars", choices = choices, selected = avail)
    updateSelectInput(session, "coinc_ord_vars", choices = choices)
  })

  coinc_results <- eventReactive(input$coinc_run, {
    dfs <- coinc_raw()
    validate(need(length(dfs) >= 2, "Sube al menos 2 archivos."))
    vars <- input$coinc_vars
    validate(need(length(vars) >= 1, "Selecciona al menos una variable."))
    ord <- input$coinc_ord_vars %||% character(0)
    rows <- lapply(vars, function(v) {
      mat <- build_rater_matrix(dfs, v)
      if (is.null(mat)) return(NULL)
      r <- compute_agreement_for_var(mat, ordinal = v %in% ord)
      data.frame(
        Variable = coinc_var_label(v), n = r$n,
        `% acuerdo` = round(r$pct, 1),
        `Cohen kappa` = round(r$cohen, 3),
        `Fleiss kappa` = round(r$fleiss, 3),
        `kappa parejas` = round(r$mean_pairwise, 3),
        `Krippendorff alpha` = round(r$krippendorff, 3),
        Interpretacion = r$interpretation,
        Ponderado = ifelse(isTRUE(r$weighted), "sí", ""),
        check.names = FALSE, stringsAsFactors = FALSE)
    })
    rows <- rows[!vapply(rows, is.null, logical(1))]
    n_match <- {
      m1 <- if (length(vars)) build_rater_matrix(dfs, vars[1]) else NULL
      if (is.null(m1)) 0L else nrow(m1)
    }
    list(table = if (length(rows)) do.call(rbind, rows) else NULL,
         n_raters = length(dfs), n_match = n_match)
  })

  output$coinc_summary <- renderPrint({
    res <- coinc_results()
    cat(sprintf("Jueces: %d\n", res$n_raters))
    cat(sprintf("Filas (segmentos) comunes emparejados: %d\n", res$n_match))
    if (!is.null(res$table)) {
      kcol <- if (res$n_raters == 2) res$table[["Cohen kappa"]] else res$table[["Fleiss kappa"]]
      cat(sprintf("Variables comparadas: %d | kappa medio: %.3f\n",
                  nrow(res$table), mean(kcol, na.rm = TRUE)))
    }
  })

  output$coinc_table <- renderDT({
    res <- coinc_results()
    validate(need(!is.null(res$table), "Sin segmentos comunes entre los archivos."))
    res$table
  }, options = list(pageLength = 25, dom = "tip"), rownames = FALSE)

  output$coinc_barplot <- renderPlot({
    res <- coinc_results()
    req(!is.null(res$table))
    kcol <- if (res$n_raters == 2) "Cohen kappa" else "Fleiss kappa"
    vals <- res$table[[kcol]]; names(vals) <- res$table$Variable
    vals <- vals[!is.na(vals)]
    if (length(vals) == 0) { plot.new(); text(.5, .5, "Sin datos"); return() }
    vals <- sort(vals, decreasing = TRUE)
    par(mar = c(10, 5, 3, 1))
    barplot(vals, col = "#3b82f6", border = "white", las = 2,
            ylim = c(min(0, min(vals)) * 1.1, 1),
            main = sprintf("%s por variable", kcol), ylab = "kappa",
            cex.names = 0.8)
    abline(h = c(0.4, 0.6, 0.8), col = "#9ca3af", lty = 3)
  })

  observeEvent(coinc_results(), {
    res <- coinc_results()
    if (res$n_raters == 2 && !is.null(res$table)) {
      vars <- input$coinc_vars
      ch <- setNames(vars, vapply(vars, coinc_var_label, character(1)))
      updateSelectInput(session, "coinc_confusion_var", choices = ch)
    } else {
      updateSelectInput(session, "coinc_confusion_var",
                        choices = c("(solo con 2 jueces)" = ""))
    }
  })

  output$coinc_confusion <- renderPrint({
    res <- coinc_results()
    req(res$n_raters == 2, nzchar(input$coinc_confusion_var %||% ""))
    mat <- build_rater_matrix(coinc_raw(), input$coinc_confusion_var)
    req(!is.null(mat))
    cmat <- mat[stats::complete.cases(mat), , drop = FALSE]
    cat("Matriz de confusión (juez 1 filas × juez 2 columnas):\n\n")
    print(table(juez1 = cmat[, 1], juez2 = cmat[, 2]))
  })
```

- [ ] **Step 3: Verificar que el archivo parsea**

Run: `Rscript -e 'invisible(parse("etiquetador_oral.R")); cat("OK\n")'`
Expected: `OK`

- [ ] **Step 4: Verificación manual — lanzar la app**

Run (en background o ventana aparte): `Rscript -e 'shiny::runApp("etiquetador_oral.R", port = 7788, launch.browser = FALSE)'`
Comprobar en `http://127.0.0.1:7788`:
1. La pestaña «Coincidencia» aparece.
2. Subir 2 archivos `analisis/analisis_*.txt` (excluyendo `analisis_todos.txt`) → la tabla de archivos muestra sus filas.
3. Los selectores de variables se rellenan con las anotaciones disponibles.
4. Pulsar «Calcular acuerdo» → resumen (nº jueces, filas comunes), tabla con Cohen/% acuerdo/interpretación, y barplot.

Detener con Ctrl-C cuando termine.

- [ ] **Step 5: Commit**

```bash
git add etiquetador_oral.R
git commit -m "feat: pestaña Coincidencia (acuerdo entre 2-10 jueces)"
```

---

### Task 6: Pestaña «Corpus» (UI + servidor)

**Files:**
- Modify: `etiquetador_oral.R` (UI: añadir `tabPanel("Corpus", ...)` tras «Coincidencia»; server: añadir bloque antes del cierre `}` de `server`)

**Interfaces:**
- Consumes: `describe_numeric`, `corpus_file_summary` (Task 4); `stat_num_cols`, `stat_col_label`, `ANALISIS_DIR`, `n_anot`, `rv$anot_defs`, `%||%` (existentes).

- [ ] **Step 1: Añadir el `tabPanel` de UI**

Insertar tras el `tabPanel("Coincidencia", ...)`:

```r
            tabPanel("Corpus", br(),
              fluidRow(
                column(8, div(class = "small-helper-text",
                  "Visión global del corpus consolidado (analisis/analisis_todos.txt).")),
                column(4, actionButton("corpus_refresh", "Refrescar desde disco",
                                       class = "btn-info btn-sm", style = "width:100%;"))
              ),
              fileInput("corpus_file", "(Opcional) Cargar otro consolidado:",
                        accept = c(".txt", ".tsv", ".csv"), width = "100%"),
              hr(),
              verbatimTextOutput("corpus_summary"),
              DTOutput("corpus_perfile"),
              hr(),
              h6("Descriptivos generales (variables numéricas)"),
              DTOutput("corpus_desc"),
              hr(),
              h6("Gráfico"),
              fluidRow(
                column(4, selectInput("corpus_num_var", "Variable numérica:",
                                      choices = NULL, width = "100%")),
                column(4, radioButtons("corpus_plot_type", "Tipo:",
                                       c("Boxplot" = "box", "Barras (medias)" = "bar"),
                                       inline = TRUE)),
                column(4, selectInput("corpus_group1", "Agrupar gráfico por:",
                                      choices = NULL, width = "100%"))
              ),
              plotOutput("corpus_plot", height = 420),
              hr(),
              h6("Agrupar por hasta 4 variables (tabla cruzada de descriptivos)"),
              fluidRow(
                column(3, selectInput("corpus_g1", "Grupo 1:", choices = NULL, width = "100%")),
                column(3, selectInput("corpus_g2", "Grupo 2:", choices = NULL, width = "100%")),
                column(3, selectInput("corpus_g3", "Grupo 3:", choices = NULL, width = "100%")),
                column(3, selectInput("corpus_g4", "Grupo 4:", choices = NULL, width = "100%"))
              ),
              DTOutput("corpus_cross")
            ),
```

- [ ] **Step 2: Añadir la lógica de servidor**

Insertar antes del cierre `}` de `server`:

```r
  # ====================== CORPUS (visión global) ======================
  corpus_df <- reactive({
    input$corpus_refresh
    if (!is.null(input$corpus_file)) {
      return(tryCatch(read_analysis_file(input$corpus_file$datapath),
                      error = function(e) NULL))
    }
    cf <- file.path(ANALISIS_DIR, "analisis_todos.txt")
    if (!file.exists(cf)) return(NULL)
    tryCatch(read_analysis_file(cf), error = function(e) NULL)
  })

  corpus_num_avail <- reactive({
    df <- corpus_df(); req(df)
    stat_num_cols[vapply(stat_num_cols, function(cn)
      cn %in% names(df) && sum(!is.na(suppressWarnings(as.numeric(df[[cn]])))) >= 1,
      logical(1))]
  })

  corpus_group_choices <- reactive({
    df <- corpus_df(); req(df)
    ch <- c("(ninguno)" = "")
    if ("filename" %in% names(df)) ch <- c(ch, c("Archivo" = "filename"))
    if ("speaker" %in% names(df))  ch <- c(ch, c("Hablante" = "speaker"))
    for (j in seq_len(n_anot)) {
      cn <- paste0("anot", j)
      if (!cn %in% names(df)) next
      vals <- df[[cn]]; vals <- vals[!is.na(vals) & nzchar(vals)]
      n_lev <- length(unique(vals))
      if (n_lev >= 2 && n_lev <= 30) {
        lbl <- if (!is.null(rv$anot_defs[[cn]])) sub(":$", "", trimws(rv$anot_defs[[cn]]$label)) else cn
        ch <- c(ch, setNames(cn, lbl))
      }
    }
    ch
  })

  observeEvent(corpus_df(), {
    nums <- corpus_num_avail()
    num_ch <- setNames(nums, vapply(nums, stat_col_label, character(1)))
    if (length(num_ch) == 0) num_ch <- c("(sin datos)" = "")
    updateSelectInput(session, "corpus_num_var", choices = num_ch)
    gch <- corpus_group_choices()
    for (id in c("corpus_group1", "corpus_g1", "corpus_g2", "corpus_g3", "corpus_g4"))
      updateSelectInput(session, id, choices = gch)
  })

  output$corpus_summary <- renderPrint({
    df <- corpus_df()
    validate(need(!is.null(df), "No se encontró analisis_todos.txt. Genera análisis o sube un archivo."))
    s <- corpus_file_summary(df)
    cat(sprintf("Archivos (corpus): %s\n",
                if (is.na(s$n_files)) "N/D (sin columna filename)" else s$n_files))
    cat(sprintf("Filas totales: %d\n", s$n_rows))
    cat(sprintf("Variables (columnas): %d\n", s$n_vars))
  })

  output$corpus_perfile <- renderDT({
    df <- corpus_df(); req(df)
    s <- corpus_file_summary(df)
    req(!is.null(s$per_file))
    s$per_file[order(-s$per_file$n_filas), ]
  }, options = list(pageLength = 10, dom = "tip"), rownames = FALSE)

  output$corpus_desc <- renderDT({
    df <- corpus_df(); req(df)
    nums <- corpus_num_avail()
    validate(need(length(nums) >= 1, "Sin variables numéricas con datos."))
    rows <- lapply(nums, function(cn) {
      d <- describe_numeric(df, cn)
      d$grupo <- stat_col_label(cn)
      names(d)[1] <- "Variable"
      d
    })
    out <- do.call(rbind, rows)
    num_cols <- setdiff(names(out), "Variable")
    out[num_cols] <- lapply(out[num_cols], function(x) round(x, 3))
    out
  }, options = list(pageLength = 15, dom = "tip"), rownames = FALSE)

  output$corpus_plot <- renderPlot({
    df <- corpus_df(); req(df, nzchar(input$corpus_num_var %||% ""))
    cn <- input$corpus_num_var
    if (!cn %in% names(df)) return(NULL)
    df[[cn]] <- suppressWarnings(as.numeric(df[[cn]]))
    grp <- input$corpus_group1
    lbl <- stat_col_label(cn)
    has_grp <- !is.null(grp) && nzchar(grp) && grp %in% names(df)
    if (input$corpus_plot_type == "box") {
      if (has_grp) {
        d2 <- df[!is.na(df[[cn]]) & !is.na(df[[grp]]) & nzchar(df[[grp]]), ]
        par(mar = c(10, 5, 3, 1))
        boxplot(d2[[cn]] ~ factor(d2[[grp]]), col = "#93c5fd", border = "#1d4ed8",
                main = lbl, ylab = lbl, xlab = "", las = 2, cex.axis = 0.8, outline = FALSE)
      } else {
        par(mar = c(3, 5, 3, 1))
        boxplot(na.omit(df[[cn]]), col = "#93c5fd", border = "#1d4ed8",
                main = lbl, ylab = lbl, outline = FALSE)
      }
    } else {
      if (has_grp) {
        d2 <- df[!is.na(df[[cn]]) & !is.na(df[[grp]]) & nzchar(df[[grp]]), ]
        ag <- tapply(d2[[cn]], factor(d2[[grp]]), mean, na.rm = TRUE)
        par(mar = c(10, 5, 3, 1))
        barplot(ag, col = "#3b82f6", border = "white", main = paste("Media de", lbl),
                ylab = lbl, las = 2, cex.names = 0.8)
      } else {
        par(mar = c(3, 5, 3, 1))
        barplot(mean(df[[cn]], na.rm = TRUE), col = "#3b82f6", border = "white",
                main = paste("Media de", lbl), ylab = lbl, names.arg = "TOTAL")
      }
    }
  })

  output$corpus_cross <- renderDT({
    df <- corpus_df(); req(df, nzchar(input$corpus_num_var %||% ""))
    cn <- input$corpus_num_var
    grps <- unique(Filter(nzchar, c(input$corpus_g1, input$corpus_g2,
                                    input$corpus_g3, input$corpus_g4)))
    out <- describe_numeric(df, cn, grps)
    num_cols <- setdiff(names(out), "grupo")
    out[num_cols] <- lapply(out[num_cols], function(x) round(x, 3))
    out
  }, options = list(pageLength = 25, dom = "tip"), rownames = FALSE)
```

- [ ] **Step 3: Verificar que el archivo parsea**

Run: `Rscript -e 'invisible(parse("etiquetador_oral.R")); cat("OK\n")'`
Expected: `OK`

- [ ] **Step 4: Verificación manual — lanzar la app**

Run: `Rscript -e 'shiny::runApp("etiquetador_oral.R", port = 7788, launch.browser = FALSE)'`
Comprobar en la pestaña «Corpus»:
1. Resumen con nº de archivos y filas (si existe `analisis/analisis_todos.txt`).
2. Tabla de filas por archivo.
3. Tabla de descriptivos generales por variable numérica.
4. Gráfico (boxplot y barras de medias) con y sin agrupación.
5. Seleccionar 2-4 grupos → la tabla cruzada muestra una fila por combinación.

Si no hay `analisis_todos.txt`, subir uno con el `fileInput` opcional. Detener con Ctrl-C.

- [ ] **Step 5: Commit**

```bash
git add etiquetador_oral.R
git commit -m "feat: pestaña Corpus (visión global de analisis_todos)"
```

---

### Task 7: Documentación y verificación final

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Actualizar el README**

En la tabla de pestañas (~línea 26-35) añadir dos filas:

```markdown
| **Coincidencia** | Acuerdo entre 2–10 jueces (archivos de análisis de otros equipos): % de acuerdo, Cohen's Kappa (ponderado para ordinales), Fleiss' Kappa y Krippendorff's α (opcional). |
| **Corpus** | Visión global de `analisis_todos.txt`: nº de archivos y filas, descriptivos de cada variable numérica, gráficos y agrupación por hasta 4 variables. |
```

En el bloque de instalación de paquetes (~línea 106) añadir nota sobre `irr` opcional:

```markdown
> `irr` es opcional: habilita Krippendorff's α en la pestaña *Coincidencia*. Sin él, esa columna aparece como N/D.
```

- [ ] **Step 2: Ejecutar toda la suite de tests**

Run: `Rscript -e 'testthat::test_dir("tests/testthat", stop_on_failure = TRUE)'`
Expected: PASS (todos los tests de las 3 secciones)

- [ ] **Step 3: Verificación final de parseo**

Run: `Rscript -e 'invisible(parse("etiquetador_oral.R")); cat("OK\n")'`
Expected: `OK`

- [ ] **Step 4: Commit**

```bash
git add README.md
git commit -m "docs: documentar pestañas Coincidencia y Corpus en README"
```

---

## Self-Review

**Spec coverage:**
- Coincidencia: subir archivos de otros equipos → Task 5 (fileInput 2-10). Cohen + otras medidas → Tasks 2-3 (Cohen, ponderado, Fleiss, % acuerdo, Krippendorff). Emparejado start/end/label → Task 3 (`seg_key`/`build_rater_matrix`). 2-10 jueces → Task 3/5.
- Corpus: usar `analisis_todos` → Task 6 (`corpus_df`). Barplot/boxplot → Task 6. Nº archivos/filas → Tasks 4/6 (`corpus_file_summary`). Medias + descriptivos por variable numérica → Tasks 4/6 (`describe_numeric`). Agrupar hasta 4 variables → Task 6 (`corpus_g1..g4` + `describe_numeric`).
- Backup previo → ya hecho (constraint global).

**Placeholder scan:** sin TBD/TODO; todo el código está completo en cada paso.

**Type consistency:** `build_rater_matrix` devuelve `matrix|NULL` y se comprueba con `is.null` en Task 3/5. `compute_agreement_for_var` devuelve lista con campos usados en Task 5 (`$n,$pct,$cohen,$fleiss,$mean_pairwise,$krippendorff,$weighted,$interpretation`). `describe_numeric` devuelve `data.frame` con columna `grupo` + descriptivos, consumido en Task 6. `corpus_file_summary` devuelve `$n_files,$n_rows,$n_vars,$per_file`, consumido en Task 6.

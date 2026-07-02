# Lote UX (descargas, tamaño de letra, mensajes de ánimo) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Añadir a Oraltags descarga en alta calidad de los 4 gráficos estadísticos (PNG 300 ppp + PDF), exportación CSV/Excel/Copiar en las 7 tablas, un deslizador global de tamaño de letra de gráficos, y un modal de bienvenida con mensaje de ánimo configurable.

**Architecture:** Las utilidades puras (nombre de archivo, opciones de botones DT, lectura/escritura de preferencias, elección de mensaje) van en `R/plot_export.R` y `R/prefs.R`, sourceados al arranque y testeados con `testthat`. La app `etiquetador_oral.R` añade un reactivo de escala `gcex()`, refactoriza los 4 gráficos estadísticos en funciones `draw_*()` compartidas por pantalla y descarga, y persiste preferencias en `config/preferencias.txt`.

**Tech Stack:** R 4.5+, Shiny, DT (extensión Buttons), grDevices (png/pdf), base R + `stats`. Sin dependencias nuevas obligatorias.

## Global Constraints

- App de un solo archivo `etiquetador_oral.R` que termina en `shinyApp(ui, server)`; NO sourcear el archivo entero en tests.
- Sin dependencias nuevas obligatorias. DT y grDevices ya están.
- Descarga de gráficos SOLO para: `stat_barplot`, `stat_boxplot`, `coinc_barplot`, `corpus_plot`. Praatpicture y acústicos NO se descargan.
- Formato de descarga: PNG a 300 ppp y PDF vectorial, ambos 9×6 pulgadas.
- Escala de letra `gcex()` se aplica a TODOS los gráficos base-R (oscilograma, espectrograma, F0, y los 4 estadísticos), NO a praatpicture.
- Tablas (7): `table`, `context_table`, `coinc_files_info`, `coinc_table`, `corpus_perfile`, `corpus_desc`, `corpus_cross`. Botones `copy/csv/excel`, exportando TODAS las filas (`page = "all"`).
- Mensajes de ánimo: checkbox `animo_enabled` DESMARCADO por defecto; modal solo si está activado al iniciar. Mensaje propio si lo hay, si no una frase predefinida al azar.
- Preferencias persistidas en `config/preferencias.txt` (formato `clave<TAB>valor`): `animo_enabled`, `animo_custom`, `plot_font_scale`.
- `APP_DIR`, `CONFIG_DIR` ya existen. El bucle de `source()` del arranque y `tests/testthat/setup.R` deben incluir los nuevos archivos `R/`.
- `%||%` existe en `server`. `gcex()` debe tolerar valores nulos/no numéricos devolviendo 1.
- Estilo gráfico base R: barras `#3b82f6`; boxplots `#93c5fd`/`#1d4ed8`.
- Tests: `Rscript -e 'testthat::test_dir("tests/testthat", stop_on_failure = TRUE)'`. Verificación de UI: `Rscript -e 'shinyApp <- function(ui, server) cat("BUILT OK\n"); suppressWarnings(source("etiquetador_oral.R"))'`.

---

### Task 1: Utilidades de exportación puras (`R/plot_export.R`)

**Files:**
- Create: `R/plot_export.R`
- Create: `tests/testthat/test-plot-export.R`
- Modify: `etiquetador_oral.R` (añadir `"plot_export.R"` al vector del bucle `source()` del arranque)
- Modify: `tests/testthat/setup.R` (añadir `"plot_export.R"` a la lista de helpers)

**Interfaces:**
- Produces:
  - `plot_filename(base, ext, date = Sys.Date()) -> character` (`"<base_saneado>_AAAA-MM-DD.<ext>"`)
  - `dt_with_buttons(options = list()) -> list` (opciones de `DT::datatable` con `dom` que incluye `B` y `buttons` copy/csv/excel exportando todas las filas)

- [ ] **Step 1: Escribir los tests (fallan)**

```r
test_that("plot_filename sanea el nombre y añade la fecha", {
  expect_equal(plot_filename("Barras", "png", as.Date("2026-06-26")), "barras_2026-06-26.png")
  expect_equal(plot_filename("Coincidencia kappa!", "pdf", as.Date("2026-01-02")),
               "coincidencia_kappa_2026-01-02.pdf")
  expect_equal(plot_filename("", "png", as.Date("2026-06-26")), "grafico_2026-06-26.png")
})

test_that("dt_with_buttons añade B al dom y los botones, conservando opciones", {
  o <- dt_with_buttons(list(dom = "tip", pageLength = 25))
  expect_equal(o$dom, "Btip")
  expect_equal(o$pageLength, 25)
  expect_equal(length(o$buttons), 3)
  expect_equal(o$buttons[[2]]$extend, "csv")
  expect_equal(o$buttons[[2]]$exportOptions$modifier$page, "all")
  expect_equal(dt_with_buttons(list())$dom, "Blfrtip")   # sin dom previo
  expect_equal(dt_with_buttons(list(dom = "Bt"))$dom, "Bt")  # no duplica B
})
```

- [ ] **Step 2: Ejecutar y verificar FALLO**

Run: `Rscript -e 'testthat::test_dir("tests/testthat", stop_on_failure = TRUE)'`
Expected: FAIL — `could not find function "plot_filename"`

- [ ] **Step 3: Crear `R/plot_export.R`**

```r
# R/plot_export.R — utilidades puras de exportación (sin Shiny)

# Nombre de archivo saneado + fecha ISO + extensión.
plot_filename <- function(base, ext, date = Sys.Date()) {
  b <- gsub("[^a-z0-9_-]+", "_", tolower(base))
  b <- gsub("^_+|_+$", "", b)
  if (!nzchar(b)) b <- "grafico"
  sprintf("%s_%s.%s", b, format(as.Date(date), "%Y-%m-%d"), ext)
}

# Inyecta botones de exportación (copy/csv/excel) en las opciones de DT::datatable,
# exportando TODAS las filas. Conserva el resto de opciones.
dt_with_buttons <- function(options = list()) {
  dom <- if (is.null(options$dom)) "lfrtip" else options$dom
  if (!grepl("B", dom, fixed = TRUE)) dom <- paste0("B", dom)
  options$dom <- dom
  exp_all <- list(modifier = list(page = "all"))
  options$buttons <- list(
    list(extend = "copy",  exportOptions = exp_all),
    list(extend = "csv",   exportOptions = exp_all),
    list(extend = "excel", exportOptions = exp_all)
  )
  options
}
```

- [ ] **Step 4: Añadir `"plot_export.R"` al bucle `source()` del arranque**

En `etiquetador_oral.R`, el bucle (tras `setwd(APP_DIR)`):

```r
  for (.f in c("stats_utils.R", "agreement.R", "corpus_stats.R")) {
```

cámbialo a:

```r
  for (.f in c("stats_utils.R", "agreement.R", "corpus_stats.R", "plot_export.R")) {
```

- [ ] **Step 5: Añadir `"plot_export.R"` a `tests/testthat/setup.R`**

Cambia la línea:

```r
for (f in c("stats_utils.R", "agreement.R", "corpus_stats.R")) {
```

a:

```r
for (f in c("stats_utils.R", "agreement.R", "corpus_stats.R", "plot_export.R", "prefs.R")) {
```

(Incluye ya `"prefs.R"` para la Task 2; `setup.R` salta los archivos que aún no existan.)

- [ ] **Step 6: Ejecutar y verificar PASA + parse**

Run: `Rscript -e 'testthat::test_dir("tests/testthat", stop_on_failure = TRUE)'`
Expected: PASS

Run: `Rscript -e 'invisible(parse("etiquetador_oral.R")); cat("PARSE OK\n")'`
Expected: `PARSE OK`

- [ ] **Step 7: Commit**

```bash
git add R/plot_export.R tests/testthat/test-plot-export.R etiquetador_oral.R tests/testthat/setup.R
git commit -m "feat: utilidades puras de exportación (plot_filename, dt_with_buttons)"
```

---

### Task 2: Utilidades de preferencias puras (`R/prefs.R`)

**Files:**
- Create: `R/prefs.R`
- Create: `tests/testthat/test-prefs.R`
- Modify: `etiquetador_oral.R` (añadir `"prefs.R"` al vector del bucle `source()`)

**Interfaces:**
- Produces:
  - `PREFS_DEFAULTS` (named list: `animo_enabled = FALSE`, `animo_custom = ""`, `plot_font_scale = 1`)
  - `load_prefs(path) -> list` (defaults si no existe; tipos convertidos)
  - `save_prefs(prefs, path) -> path` (escribe `clave<TAB>valor`)
  - `choose_message(custom, presets) -> character` (propio si no vacío; si no, una de `presets`; `""` si no hay)

- [ ] **Step 1: Escribir los tests (fallan)**

```r
test_that("load_prefs devuelve defaults sin archivo", {
  p <- load_prefs(tempfile())
  expect_false(p$animo_enabled)
  expect_equal(p$animo_custom, "")
  expect_equal(p$plot_font_scale, 1)
})

test_that("save_prefs/load_prefs hacen round-trip", {
  f <- tempfile()
  save_prefs(list(animo_enabled = TRUE, animo_custom = "¡Ánimo!", plot_font_scale = 1.5), f)
  p <- load_prefs(f)
  expect_true(p$animo_enabled)
  expect_equal(p$animo_custom, "¡Ánimo!")
  expect_equal(p$plot_font_scale, 1.5)
})

test_that("load_prefs ignora líneas mal formadas y claves desconocidas", {
  f <- tempfile()
  writeLines(c("basura", "desconocida\tx", "animo_enabled\tTRUE"), f)
  p <- load_prefs(f)
  expect_true(p$animo_enabled)
  expect_equal(p$plot_font_scale, 1)
})

test_that("choose_message: propio si lo hay, si no una predefinida", {
  expect_equal(choose_message("  hola  ", c("a", "b")), "hola")
  set.seed(1); expect_true(choose_message("", c("a", "b")) %in% c("a", "b"))
  expect_equal(choose_message("", character(0)), "")
  expect_equal(choose_message(NULL, character(0)), "")
})
```

- [ ] **Step 2: Ejecutar y verificar FALLO**

Run: `Rscript -e 'testthat::test_dir("tests/testthat", stop_on_failure = TRUE)'`
Expected: FAIL — `could not find function "load_prefs"`

- [ ] **Step 3: Crear `R/prefs.R`**

```r
# R/prefs.R — preferencias persistentes (puras, base R)

PREFS_DEFAULTS <- list(animo_enabled = FALSE, animo_custom = "", plot_font_scale = 1)

load_prefs <- function(path) {
  prefs <- PREFS_DEFAULTS
  if (!file.exists(path)) return(prefs)
  lines <- tryCatch(readLines(path, warn = FALSE, encoding = "UTF-8"),
                    error = function(e) character(0))
  for (ln in lines) {
    if (!grepl("\t", ln, fixed = TRUE)) next
    kv <- strsplit(ln, "\t", fixed = TRUE)[[1]]
    if (length(kv) < 2) next
    key <- trimws(kv[1]); val <- paste(kv[-1], collapse = "\t")
    if (!key %in% names(PREFS_DEFAULTS)) next
    prefs[[key]] <- switch(key,
      animo_enabled   = isTRUE(as.logical(val)),
      plot_font_scale = { n <- suppressWarnings(as.numeric(val)); if (is.na(n)) 1 else n },
      val)
  }
  prefs
}

save_prefs <- function(prefs, path) {
  lines <- vapply(names(PREFS_DEFAULTS), function(k) {
    v <- if (is.null(prefs[[k]])) PREFS_DEFAULTS[[k]] else prefs[[k]]
    paste0(k, "\t", as.character(v))
  }, character(1))
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  writeLines(lines, path, useBytes = TRUE)
  invisible(path)
}

choose_message <- function(custom, presets) {
  custom <- if (is.null(custom)) "" else trimws(custom)
  if (nzchar(custom)) return(custom)
  if (length(presets) == 0) return("")
  sample(presets, 1)
}
```

- [ ] **Step 4: Añadir `"prefs.R"` al bucle `source()` del arranque**

En `etiquetador_oral.R`, el bucle (ya con `plot_export.R` de la Task 1):

```r
  for (.f in c("stats_utils.R", "agreement.R", "corpus_stats.R", "plot_export.R")) {
```

cámbialo a:

```r
  for (.f in c("stats_utils.R", "agreement.R", "corpus_stats.R", "plot_export.R", "prefs.R")) {
```

- [ ] **Step 5: Ejecutar y verificar PASA + parse**

Run: `Rscript -e 'testthat::test_dir("tests/testthat", stop_on_failure = TRUE)'`
Expected: PASS

Run: `Rscript -e 'invisible(parse("etiquetador_oral.R")); cat("PARSE OK\n")'`
Expected: `PARSE OK`

- [ ] **Step 6: Commit**

```bash
git add R/prefs.R tests/testthat/test-prefs.R etiquetador_oral.R
git commit -m "feat: utilidades puras de preferencias (load/save_prefs, choose_message)"
```

---

### Task 3: Exportación CSV/Excel/Copiar en las 7 tablas

**Files:**
- Modify: `etiquetador_oral.R` (7 llamadas a `datatable`/`renderDT`)

**Interfaces:**
- Consumes: `dt_with_buttons` (Task 1).

- [ ] **Step 1: `output$table` — añadir extensión y botones**

Localiza el `datatable(rv$df, ...)` dentro de `output$table <- renderDT({...})` y cámbialo de:

```r
    datatable(rv$df, selection = "single", editable = TRUE,
              options = list(pageLength = 20, scrollX = TRUE,
                             columnDefs = col_defs),
              rownames = FALSE)
```

a:

```r
    datatable(rv$df, selection = "single", editable = TRUE,
              extensions = "Buttons",
              options = dt_with_buttons(list(pageLength = 20, scrollX = TRUE,
                                             columnDefs = col_defs)),
              rownames = FALSE)
```

- [ ] **Step 2: `output$context_table` — añadir extensión y botones**

Cambia el `datatable(ctx_df, ...)` de:

```r
    datatable(ctx_df,
      options = list(pageLength = 2 * nc + 1, scrollX = TRUE,
                     searching = FALSE, paging = FALSE,
                     columnDefs = list(list(targets = 4, visible = FALSE))),
      rownames = FALSE
    ) %>% formatStyle("es_actual", target = "row",
```

a:

```r
    datatable(ctx_df,
      extensions = "Buttons",
      options = dt_with_buttons(list(pageLength = 2 * nc + 1, scrollX = TRUE,
                     searching = FALSE, paging = FALSE,
                     columnDefs = list(list(targets = 4, visible = FALSE)))),
      rownames = FALSE
    ) %>% formatStyle("es_actual", target = "row",
```

- [ ] **Step 3: Las 5 tablas con `options` a nivel de `renderDT`**

Para cada una, añade `extensions = "Buttons"` y envuelve `options` con `dt_with_buttons(...)`:

`coinc_files_info`: de
`}, options = list(dom = "t"), rownames = FALSE)`
a
`}, extensions = "Buttons", options = dt_with_buttons(list(dom = "t")), rownames = FALSE)`

`coinc_table`: de
`}, options = list(pageLength = 25, dom = "tip"), rownames = FALSE)`
a
`}, extensions = "Buttons", options = dt_with_buttons(list(pageLength = 25, dom = "tip")), rownames = FALSE)`

`corpus_perfile`: de
`}, options = list(pageLength = 10, dom = "tip"), rownames = FALSE)`
a
`}, extensions = "Buttons", options = dt_with_buttons(list(pageLength = 10, dom = "tip")), rownames = FALSE)`

`corpus_desc`: de
`}, options = list(pageLength = 15, dom = "tip"), rownames = FALSE)`
a
`}, extensions = "Buttons", options = dt_with_buttons(list(pageLength = 15, dom = "tip")), rownames = FALSE)`

`corpus_cross`: de
`}, options = list(pageLength = 25, dom = "tip"), rownames = FALSE)`
a
`}, extensions = "Buttons", options = dt_with_buttons(list(pageLength = 25, dom = "tip")), rownames = FALSE)`

- [ ] **Step 4: Verificar parse + UI build + tests**

Run: `Rscript -e 'invisible(parse("etiquetador_oral.R")); cat("PARSE OK\n")'`
Expected: `PARSE OK`

Run: `Rscript -e 'shinyApp <- function(ui, server) cat("BUILT OK\n"); suppressWarnings(source("etiquetador_oral.R"))'`
Expected: termina en `BUILT OK`

Run: `Rscript -e 'testthat::test_dir("tests/testthat", stop_on_failure = TRUE)'`
Expected: `FAIL 0 | WARN 0`

Verificación manual (al lanzar la app por el usuario): cada tabla muestra los botones Copiar/CSV/Excel y exportan todas las filas.

- [ ] **Step 5: Commit**

```bash
git add etiquetador_oral.R
git commit -m "feat: botones CSV/Excel/Copiar en las 7 tablas (DT Buttons)"
```

---

### Task 4: Tamaño de letra — `gcex()`, deslizador y gráficos acústicos

**Files:**
- Modify: `etiquetador_oral.R` (deslizador en Configuración; `gcex()`; oscilograma/espectrograma/F0)

**Interfaces:**
- Produces: `gcex() -> double` (reactivo; escala de letra, ≥ tolerante: 1 si nulo/no numérico/≤0).
- Consumes: nada de tasks previas.

- [ ] **Step 1: Añadir el bloque "Preferencias" con el deslizador en Configuración**

Dentro de `tabPanel("Configuración", br(), ...)`, tras el `fluidRow` existente de parámetros acústicos (el que contiene `numericInput("quartile_pct", ...)` y los botones), añade:

```r
              hr(),
              h6("🎚️ Preferencias"),
              fluidRow(
                column(12,
                  sliderInput("plot_font_scale", "Tamaño de letra de gráficos:",
                              min = 0.7, max = 2, value = 1, step = 0.1, width = "100%")
                )
              ),
```

- [ ] **Step 2: Definir el reactivo `gcex()` en el servidor**

En `server`, inmediatamente antes de `output$oscillo_plot <- renderPlot({`, añade:

```r
  # Escala global del tamaño de letra de los gráficos (deslizador de Configuración).
  gcex <- reactive({
    s <- suppressWarnings(as.numeric(input$plot_font_scale %||% 1))
    if (is.na(s) || s <= 0) 1 else s
  })
```

- [ ] **Step 3: Aplicar `gcex()` al oscilograma**

Cambia el cuerpo de `output$oscillo_plot` de:

```r
    req(rv$selected_segment)
    seewave::oscillo(rv$selected_segment, f = rv$selected_segment@samp.rate,
                     k = 1, colwave = "steelblue")
    title("Oscilograma")
```

a:

```r
    req(rv$selected_segment)
    g <- gcex()
    seewave::oscillo(rv$selected_segment, f = rv$selected_segment@samp.rate,
                     k = 1, colwave = "steelblue", cexlab = g, cexaxis = g)
    title("Oscilograma", cex.main = g)
```

- [ ] **Step 4: Aplicar `gcex()` al espectrograma**

Cambia, dentro de `output$spectro_plot`, el `tryCatch` y el `title` de:

```r
    tryCatch(
      seewave::spectro(seg, f = fs, wl = wl, ovlp = 85, osc = FALSE, scale = TRUE),
      error = function(e) { plot.new(); text(0.5,0.5, paste("Error:", e$message)) }
    )
    title("Espectrograma")
```

a:

```r
    g <- gcex()
    tryCatch(
      seewave::spectro(seg, f = fs, wl = wl, ovlp = 85, osc = FALSE, scale = TRUE,
                       cexlab = g, cexaxis = g),
      error = function(e) { plot.new(); text(0.5,0.5, paste("Error:", e$message)) }
    )
    title("Espectrograma", cex.main = g)
```

- [ ] **Step 5: Aplicar `gcex()` a la curva F0**

Cambia el cuerpo de `output$pitch_plot` de:

```r
    if (is.null(rv$pitch_data) || nrow(rv$pitch_data) == 0) {
      plot.new(); title("Curva melodica (F0)")
      text(0.5, 0.5, "Sin valores de F0 detectados", cex = 1.2, col = "gray50")
      return()
    }
    plot(rv$pitch_data$time, rv$pitch_data$freq, type = "b", pch = 19,
         col = "dodgerblue3", lwd = 2, cex = 1.2,
         xlab = "Tiempo (s)", ylab = "Frecuencia (Hz)",
         main = sprintf("Curva melodica (F0) – %d puntos", nrow(rv$pitch_data)))
    grid(col = "gray80", lwd = 1)
```

a:

```r
    g <- gcex()
    if (is.null(rv$pitch_data) || nrow(rv$pitch_data) == 0) {
      plot.new(); title("Curva melodica (F0)", cex.main = g)
      text(0.5, 0.5, "Sin valores de F0 detectados", cex = 1.2 * g, col = "gray50")
      return()
    }
    plot(rv$pitch_data$time, rv$pitch_data$freq, type = "b", pch = 19,
         col = "dodgerblue3", lwd = 2, cex = 1.2,
         xlab = "Tiempo (s)", ylab = "Frecuencia (Hz)",
         cex.lab = g, cex.axis = g, cex.main = g,
         main = sprintf("Curva melodica (F0) – %d puntos", nrow(rv$pitch_data)))
    grid(col = "gray80", lwd = 1)
```

- [ ] **Step 6: Verificar parse + UI build + tests**

Run: `Rscript -e 'invisible(parse("etiquetador_oral.R")); cat("PARSE OK\n")'`  → `PARSE OK`
Run: `Rscript -e 'shinyApp <- function(ui, server) cat("BUILT OK\n"); suppressWarnings(source("etiquetador_oral.R"))'`  → `BUILT OK`
Run: `Rscript -e 'testthat::test_dir("tests/testthat", stop_on_failure = TRUE)'`  → `FAIL 0 | WARN 0`

- [ ] **Step 7: Commit**

```bash
git add etiquetador_oral.R
git commit -m "feat: deslizador global de tamaño de letra (gcex) aplicado a gráficos acústicos"
```

---

### Task 5: Descarga PNG/PDF de los 4 gráficos estadísticos (refactor `draw_*` + `gcex`)

**Files:**
- Modify: `etiquetador_oral.R` (helper `add_plot_download`; 4 gráficos → `draw_*`; botones de descarga en UI)

**Interfaces:**
- Consumes: `plot_filename` (Task 1), `gcex()` (Task 4).
- Produces: `add_plot_download(output, id, draw_fun, basename)`; funciones `draw_stat_barplot()`, `draw_stat_boxplot()`, `draw_coinc_barplot()`, `draw_corpus_plot()`.

- [ ] **Step 1: Añadir el helper `add_plot_download` en el servidor**

En `server`, junto a `gcex()` (antes de `output$oscillo_plot`), añade:

```r
  # Registra descargas PNG (300 ppp) y PDF (vectorial) para un gráfico.
  add_plot_download <- function(output, id, draw_fun, basename) {
    output[[paste0(id, "_png")]] <- downloadHandler(
      filename = function() plot_filename(basename, "png"),
      content  = function(file) {
        grDevices::png(file, width = 9, height = 6, units = "in", res = 300)
        on.exit(grDevices::dev.off()); draw_fun()
      })
    output[[paste0(id, "_pdf")]] <- downloadHandler(
      filename = function() plot_filename(basename, "pdf"),
      content  = function(file) {
        grDevices::pdf(file, width = 9, height = 6)
        on.exit(grDevices::dev.off()); draw_fun()
      })
  }
```

- [ ] **Step 2: `stat_barplot` → `draw_stat_barplot()` + render + descarga**

Sustituye TODO el bloque `output$stat_barplot <- renderPlot({ ... })` por:

```r
  draw_stat_barplot <- function() {
    g <- gcex()
    req(rv$df_full, nzchar(input$stat_cat_var %||% ""))
    cn   <- input$stat_cat_var
    df   <- rv$df_full
    if (!cn %in% names(df)) return(NULL)
    vals <- df[[cn]]
    vals <- na.omit(vals[nzchar(ifelse(is.na(vals), "", vals))])
    vals <- unlist(strsplit(as.character(vals), ";\\s*"))
    vals <- trimws(vals); vals <- vals[nzchar(vals)]
    if (length(vals) == 0) { plot.new(); text(.5,.5,"Sin datos"); return() }
    tbl <- sort(table(vals), decreasing = TRUE)
    if (input$stat_bar_type == "pct") {
      tbl <- tbl / sum(tbl) * 100; ylab <- "Porcentaje (%)"
      fmt <- function(x) sprintf("%.1f%%", x)
    } else {
      ylab <- "Frecuencia (n)"; fmt <- function(x) as.character(x)
    }
    lbl <- if (!is.null(rv$anot_defs[[cn]])) sub(":$","",rv$anot_defs[[cn]]$label)
           else if (cn %in% names(stat_extra_nominal)) stat_extra_nominal[[cn]]
           else cn
    par(mar = c(8, 5, 3, 1))
    bp <- barplot(tbl, col = "#3b82f6", border = "white",
                  main = lbl, ylab = ylab, las = 2,
                  ylim = c(0, max(tbl) * 1.1),
                  cex.names = 0.8 * g, cex.axis = 0.9 * g,
                  cex.main = 1 * g, cex.lab = g)
    text(bp, tbl + max(tbl) * 0.02, labels = fmt(tbl),
         cex = 0.75 * g, adj = c(0.5, 0))
  }
  output$stat_barplot <- renderPlot({ input$stat_bar_update; draw_stat_barplot() })
  add_plot_download(output, "stat_barplot", draw_stat_barplot, "barras")
```

- [ ] **Step 3: `stat_boxplot` → `draw_stat_boxplot()` + render + descarga**

Sustituye TODO el bloque `output$stat_boxplot <- renderPlot({ ... })` por:

```r
  draw_stat_boxplot <- function() {
    g <- gcex()
    req(rv$df_full, nzchar(input$stat_num_var %||% ""))
    cn  <- input$stat_num_var
    grp <- input$stat_group_var
    df  <- rv$df_full
    if (!cn %in% names(df)) return(NULL)
    lbl <- stat_col_label(cn)
    if (!is.null(grp) && nzchar(grp) && grp %in% names(df)) {
      df2   <- df[!is.na(df[[cn]]) & !is.na(df[[grp]]) & nzchar(df[[grp]]), ]
      grp_v <- factor(df2[[grp]])
      par(mar = c(9, 5, 3, 1))
      boxplot(df2[[cn]] ~ grp_v, col = "#93c5fd", border = "#1d4ed8",
              main = lbl, ylab = lbl, xlab = "", las = 2,
              cex.axis = 0.8 * g, cex.main = g, cex.lab = g, outline = FALSE)
      stripchart(df2[[cn]] ~ grp_v, vertical = TRUE, method = "jitter",
                 add = TRUE, pch = 20, col = "#1d4ed880", cex = 0.6 * g)
    } else {
      vals <- na.omit(df[[cn]])
      par(mar = c(3, 5, 3, 1))
      boxplot(vals, col = "#93c5fd", border = "#1d4ed8",
              main = lbl, ylab = lbl, outline = FALSE, horizontal = FALSE,
              cex.axis = 0.8 * g, cex.main = g, cex.lab = g)
      stripchart(vals, vertical = TRUE, method = "jitter",
                 add = TRUE, pch = 20, col = "#1d4ed880", cex = 0.7 * g)
    }
  }
  output$stat_boxplot <- renderPlot({ input$stat_box_update; draw_stat_boxplot() })
  add_plot_download(output, "stat_boxplot", draw_stat_boxplot, "boxplot")
```

- [ ] **Step 4: `coinc_barplot` → `draw_coinc_barplot()` + render + descarga**

Sustituye TODO el bloque `output$coinc_barplot <- renderPlot({ ... })` por:

```r
  draw_coinc_barplot <- function() {
    g <- gcex()
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
            cex.names = 0.8 * g, cex.axis = g, cex.main = g, cex.lab = g)
    abline(h = c(0.4, 0.6, 0.8), col = "#9ca3af", lty = 3)
  }
  output$coinc_barplot <- renderPlot({ draw_coinc_barplot() })
  add_plot_download(output, "coinc_barplot", draw_coinc_barplot, "coincidencia_kappa")
```

- [ ] **Step 5: `corpus_plot` → `draw_corpus_plot()` + render + descarga**

Sustituye TODO el bloque `output$corpus_plot <- renderPlot({ ... })` por:

```r
  draw_corpus_plot <- function() {
    g <- gcex()
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
                main = lbl, ylab = lbl, xlab = "", las = 2,
                cex.axis = 0.8 * g, cex.main = g, cex.lab = g, outline = FALSE)
      } else {
        par(mar = c(3, 5, 3, 1))
        boxplot(na.omit(df[[cn]]), col = "#93c5fd", border = "#1d4ed8",
                main = lbl, ylab = lbl, outline = FALSE,
                cex.axis = 0.8 * g, cex.main = g, cex.lab = g)
      }
    } else {
      if (has_grp) {
        d2 <- df[!is.na(df[[cn]]) & !is.na(df[[grp]]) & nzchar(df[[grp]]), ]
        ag <- tapply(d2[[cn]], factor(d2[[grp]]), mean, na.rm = TRUE)
        par(mar = c(10, 5, 3, 1))
        barplot(ag, col = "#3b82f6", border = "white", main = paste("Media de", lbl),
                ylab = lbl, las = 2, cex.names = 0.8 * g, cex.axis = g,
                cex.main = g, cex.lab = g)
      } else {
        par(mar = c(3, 5, 3, 1))
        barplot(mean(df[[cn]], na.rm = TRUE), col = "#3b82f6", border = "white",
                main = paste("Media de", lbl), ylab = lbl, names.arg = "TOTAL",
                cex.axis = g, cex.main = g, cex.lab = g, cex.names = g)
      }
    }
  }
  output$corpus_plot <- renderPlot({ draw_corpus_plot() })
  add_plot_download(output, "corpus_plot", draw_corpus_plot, "corpus")
```

- [ ] **Step 6: Añadir los botones de descarga bajo cada gráfico en la UI**

En la UI, justo DESPUÉS de cada `plotOutput`, añade una fila con los dos botones:

Tras `plotOutput("stat_barplot", height = 420)`:
```r
                  ,
                  fluidRow(column(12,
                    downloadButton("stat_barplot_png", "PNG", class = "btn-sm"),
                    downloadButton("stat_barplot_pdf", "PDF", class = "btn-sm")
                  ))
```

Tras `plotOutput("stat_boxplot", height = 380),` (ya hay una coma; inserta antes del `br()` siguiente):
```r
                  fluidRow(column(12,
                    downloadButton("stat_boxplot_png", "PNG", class = "btn-sm"),
                    downloadButton("stat_boxplot_pdf", "PDF", class = "btn-sm")
                  )),
```

Tras `plotOutput("coinc_barplot", height = 420),`:
```r
              fluidRow(column(12,
                downloadButton("coinc_barplot_png", "PNG", class = "btn-sm"),
                downloadButton("coinc_barplot_pdf", "PDF", class = "btn-sm")
              )),
```

Tras `plotOutput("corpus_plot", height = 420),`:
```r
              fluidRow(column(12,
                downloadButton("corpus_plot_png", "PNG", class = "btn-sm"),
                downloadButton("corpus_plot_pdf", "PDF", class = "btn-sm")
              )),
```

> Nota: respeta la sintaxis de comas del `tagList`/`column` donde insertas. Para `stat_barplot`, que está como último hijo de su `column(...)`, añade la coma antes del `fluidRow` como se muestra. Verifica con el parse del Step 7.

- [ ] **Step 7: Verificar parse + UI build + tests**

Run: `Rscript -e 'invisible(parse("etiquetador_oral.R")); cat("PARSE OK\n")'`  → `PARSE OK`
Run: `Rscript -e 'shinyApp <- function(ui, server) cat("BUILT OK\n"); suppressWarnings(source("etiquetador_oral.R"))'`  → `BUILT OK`
Run: `Rscript -e 'testthat::test_dir("tests/testthat", stop_on_failure = TRUE)'`  → `FAIL 0 | WARN 0`

Verificación manual (usuario): descargar PNG y PDF de los 4 gráficos y comprobar nitidez y que el tamaño de letra del deslizador se refleja en la descarga.

- [ ] **Step 8: Commit**

```bash
git add etiquetador_oral.R
git commit -m "feat: descarga PNG/PDF de los 4 gráficos estadísticos (draw_* compartido)"
```

---

### Task 6: Preferencias persistentes + modal de bienvenida

**Files:**
- Modify: `etiquetador_oral.R` (constante `PREFS_FILE` + `ANIMO_PRESETS`; UI de Preferencias; persistencia; modal al iniciar)

**Interfaces:**
- Consumes: `load_prefs`, `save_prefs`, `choose_message` (Task 2); `CONFIG_DIR`, `%||%` (existentes); `plot_font_scale` (Task 4).

- [ ] **Step 1: Definir `PREFS_FILE` y `ANIMO_PRESETS`**

Junto a las constantes de configuración (donde se define `CONFIG_DIR`, `ETIQ_FILE`, etc.), añade:

```r
PREFS_FILE <- file.path(CONFIG_DIR, "preferencias.txt")

ANIMO_PRESETS <- c(
  "Cada grupo entonativo que anotas acerca un poco más el corpus a la ciencia. ¡Ánimo!",
  "La paciencia de hoy es el corpus sólido de mañana.",
  "Un segmento cada vez: así se construyen los grandes análisis.",
  "Tu oído atento es el mejor instrumento de medida. ¡A por ello!",
  "Anotar es escuchar dos veces. Disfruta del proceso.",
  "Los datos que cuidas hoy sostendrán tus conclusiones de mañana.",
  "Pequeños avances, gran investigación. ¡Sigue así!",
  "Detrás de cada etiqueta hay una decisión valiosa. Confía en tu criterio."
)
```

- [ ] **Step 2: Añadir los controles de mensaje de ánimo al bloque Preferencias (UI)**

En `tabPanel("Configuración", ...)`, dentro del bloque "Preferencias" creado en la Task 4 (tras el `fluidRow` del `sliderInput("plot_font_scale", ...)`), añade:

```r
              fluidRow(
                column(12,
                  checkboxInput("animo_enabled",
                                "Mostrar mensaje de ánimo al iniciar", value = FALSE),
                  textAreaInput("animo_custom", "Tu propio mensaje (opcional):",
                                rows = 2, width = "100%",
                                placeholder = "Si lo dejas vacío, se mostrará una frase al azar."),
                  actionButton("save_prefs_btn", "Guardar preferencias",
                               class = "btn-primary btn-sm")
                )
              ),
```

- [ ] **Step 3: Guardar preferencias al pulsar el botón (servidor)**

En `server` (junto al resto de observers), añade:

```r
  observeEvent(input$save_prefs_btn, {
    save_prefs(list(animo_enabled  = isTRUE(input$animo_enabled),
                    animo_custom   = input$animo_custom %||% "",
                    plot_font_scale = as.numeric(input$plot_font_scale %||% 1)),
               PREFS_FILE)
    showNotification("Preferencias guardadas", type = "message")
  })
```

- [ ] **Step 4: Cargar preferencias al iniciar y mostrar el modal**

En `server`, como bloque de nivel superior (p. ej. al principio del cuerpo de `server`, tras la definición de `%||%`), añade:

```r
  # Cargar preferencias guardadas e inicializar controles + modal de bienvenida.
  local({
    prefs0 <- load_prefs(PREFS_FILE)
    updateCheckboxInput(session, "animo_enabled", value = isTRUE(prefs0$animo_enabled))
    updateTextAreaInput(session, "animo_custom",  value = prefs0$animo_custom %||% "")
    updateSliderInput(session, "plot_font_scale",
                      value = as.numeric(prefs0$plot_font_scale %||% 1))
    if (isTRUE(prefs0$animo_enabled)) {
      showModal(modalDialog(
        title = "Bienvenido/a a Oraltags",
        choose_message(prefs0$animo_custom, ANIMO_PRESETS),
        easyClose = TRUE, footer = modalButton("Cerrar")
      ))
    }
  })
```

> `%||%` debe estar definido antes de este bloque. Si en `server` se define más abajo, coloca este bloque justo después de esa definición.

- [ ] **Step 5: Verificar parse + UI build + tests**

Run: `Rscript -e 'invisible(parse("etiquetador_oral.R")); cat("PARSE OK\n")'`  → `PARSE OK`
Run: `Rscript -e 'shinyApp <- function(ui, server) cat("BUILT OK\n"); suppressWarnings(source("etiquetador_oral.R"))'`  → `BUILT OK`
Run: `Rscript -e 'testthat::test_dir("tests/testthat", stop_on_failure = TRUE)'`  → `FAIL 0 | WARN 0`

Verificación manual (usuario): activar el check, guardar, reiniciar la app y ver el modal; escribir un mensaje propio y comprobar que se muestra ese; mover el deslizador, guardar y ver que el tamaño persiste al reiniciar.

- [ ] **Step 6: Commit**

```bash
git add etiquetador_oral.R
git commit -m "feat: preferencias persistentes y modal de bienvenida con mensaje de ánimo"
```

---

### Task 7: Documentación y verificación final

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Actualizar el README**

En la sección de funcionalidades, añade una nota sobre las nuevas capacidades (descarga de gráficos, exportación de tablas, tamaño de letra y mensaje de ánimo). Inserta tras el bloque de *Persistencia y exportación* (o en la lista de funcionalidades) este texto:

```markdown
### Exportación y personalización (v2.1)

- **Descarga de gráficos** en alta calidad (PNG 300 ppp y PDF vectorial) en los gráficos de *Estadísticas*, *Coincidencia* y *Corpus*.
- **Exportación de tablas** a CSV, Excel y portapapeles (botones integrados en cada tabla; exportan todas las filas).
- **Tamaño de letra de los gráficos** ajustable con un deslizador global en *Configuración*.
- **Mensaje de ánimo** opcional al iniciar (frase al azar o mensaje propio), activable en *Configuración*.
```

- [ ] **Step 2: Ejecutar toda la suite + parse + build**

Run: `Rscript -e 'testthat::test_dir("tests/testthat", stop_on_failure = TRUE)'`  → `FAIL 0 | WARN 0`
Run: `Rscript -e 'invisible(parse("etiquetador_oral.R")); cat("OK\n")'`  → `OK`
Run: `Rscript -e 'shinyApp <- function(ui, server) cat("BUILT OK\n"); suppressWarnings(source("etiquetador_oral.R"))'`  → `BUILT OK`

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: documentar exportación, tamaño de letra y mensaje de ánimo"
```

---

## Self-Review

**Spec coverage:**
- Componente 1 (tamaño de letra): Task 4 (`gcex`, deslizador, acústicos) + Task 5 (los 4 estadísticos vía `draw_*`). ✓
- Componente 2 (descarga PNG/PDF de 4 gráficos): Task 5 (`add_plot_download`, `draw_*`, botones). `plot_filename` en Task 1. ✓
- Componente 3 (export tablas CSV/Excel/Copiar, todas las filas): Task 3 + `dt_with_buttons` (Task 1). ✓
- Componente 4 (mensajes de ánimo + persistencia): Task 6 (`PREFS_FILE`, `ANIMO_PRESETS`, UI, persistencia, modal); helpers en Task 2. ✓
- Pruebas puras: Tasks 1 y 2 (testthat). ✓

**Placeholder scan:** sin TBD/TODO; todo el código está completo en cada paso.

**Type consistency:** `gcex()` definido en Task 4 y usado en Tasks 4 y 5. `plot_filename` (Task 1) usado en `add_plot_download` (Task 5). `dt_with_buttons` (Task 1) usado en Task 3. `load_prefs/save_prefs/choose_message` (Task 2) usados en Task 6. `draw_stat_barplot/draw_stat_boxplot/draw_coinc_barplot/draw_corpus_plot` definidas y registradas en Task 5. Ids de descarga (`<id>_png`/`<id>_pdf`) coinciden entre `add_plot_download` y los `downloadButton` de la UI. Claves de `PREFS_DEFAULTS` (`animo_enabled`, `animo_custom`, `plot_font_scale`) coinciden con los `input$` de la UI y el guardado.

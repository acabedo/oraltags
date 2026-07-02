# Reorganización de pestañas, edición en Contexto y logo — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reorganizar el menú superior de Oraltags (quitar Tabla; anidar Métricas/Praatpicture bajo Análisis fonético y Corpus bajo Estadísticas), añadir edición de speaker/label de la fila activa en Contexto con una columna citable `ejemplo_para_paper`, y un logo hexagonal junto al título.

**Architecture:** Las funciones puras (cita y recálculo de contexto) se extraen a `R/contexto.R`, sourceado al arranque y testeado con `testthat`. El resto son cambios de UI/servidor en `etiquetador_oral.R` (reorganización de `tabPanel`s y nuevos observers en Contexto) más un asset `www/logo.svg`.

**Tech Stack:** R 4.5+, Shiny, DT, base R + `tools`. Sin dependencias nuevas.

## Global Constraints

- App de un solo archivo `etiquetador_oral.R` que termina en `shinyApp(ui, server)`; NO sourcear el archivo entero en tests.
- Sin dependencias nuevas. Helpers puros usan solo base R + `tools`.
- Menú superior resultante (en este orden): **Anotaciones · Contexto · Análisis fonético · Estadísticas · Coincidencia · Configuración**. Se eliminan del nivel superior: Tabla, Métricas, Praatpicture, Corpus.
- «Análisis fonético» contiene un `tabsetPanel(type="tabs")` con subpestañas **Imágenes**, **Métricas**, **Praatpicture** (en ese orden). El contenido de Métricas y Praatpicture se MUEVE verbatim desde sus `tabPanel` superiores actuales.
- «Estadísticas» contiene un `tabsetPanel(type="tabs")` con subpestañas **Este archivo** (el contenido actual de Estadísticas) y **Corpus completo** (el contenido actual del `tabPanel("Corpus")`).
- La pestaña «Tabla» solo se quita de la UI; su código de servidor (`output$table`, `dataTableProxy("table")`, `observeEvent(input$table_cell_edit, …)`) NO se toca.
- Contexto: editar `speaker`/`label` actúa solo sobre la fila activa (`rv$selected_row_index`) y persiste con `save_analysis_file(rv$df_full, rv$current_filename)`. Al editar, se recalcula TODA la columna `contexto`.
- `ejemplo_para_paper` por fila = `<contexto de la fila> <cita>`, con `cita = format_cita(corpus, start_activa, end_activa)` usando los tiempos de la fila activa; oculta por defecto, visible al pulsar un botón toggle.
- `format_cita`: tiempos a 2 decimales; formato `"(<corpus>, <s>-<e>)"`.
- Logo `www/logo.svg`: hexágono naranja `#e95420` con bocadillo blanco + onda; ~40 px junto al título.
- Verificación de UI: `Rscript -e 'invisible(parse("etiquetador_oral.R")); cat("PARSE OK\n")'` y `Rscript -e 'shinyApp <- function(ui, server) cat("BUILT OK\n"); suppressWarnings(source("etiquetador_oral.R"))'`. Tests: `Rscript -e 'testthat::test_dir("tests/testthat", stop_on_failure = TRUE)'`.
- Hay carpetas sin rastrear (`analisis/`, `jueces/`, `www/`, `.DS_Store`): no añadirlas con `git add` salvo el archivo concreto `www/logo.svg`.

---

### Task 1: Helpers de contexto (`R/contexto.R`) + refactor del cálculo de contexto

**Files:**
- Create: `R/contexto.R`
- Create: `tests/testthat/test-contexto.R`
- Modify: `etiquetador_oral.R` (añadir `"contexto.R"` al bucle `source()`; reemplazar el bucle inline de contexto por una llamada al helper)
- Modify: `tests/testthat/setup.R` (añadir `"contexto.R"`)

**Interfaces:**
- Produces:
  - `format_cita(corpus, start, end) -> character` → `"(<corpus>, <s>-<e>)"` con `s`/`e` a 2 decimales.
  - `recompute_contexto(df, window = 5) -> data.frame` (reconstruye la columna `contexto` con formato `speaker: label` en ventana ±window, separador `" | "`, omitiendo labels vacíos).
  - `corpus_base_name(filename) -> character` (nombre base del corpus: sin ruta, sin extensión, sin prefijo `analisis_`; `"corpus"` si nulo/vacío).

- [ ] **Step 1: Escribir los tests (fallan)**

```r
test_that("format_cita formatea a 2 decimales", {
  expect_equal(format_cita("muestra_1", 0.3, 3.180005), "(muestra_1, 0.30-3.18)")
  expect_equal(format_cita("c", 1, 2), "(c, 1.00-2.00)")
})

test_that("recompute_contexto arma 'speaker: label' en ventana", {
  df <- data.frame(speaker = c("A","B","A"), label = c("uno","dos","tres"),
                   stringsAsFactors = FALSE)
  out <- recompute_contexto(df, window = 1)
  expect_equal(out$contexto[1], "A: uno | B: dos")
  expect_equal(out$contexto[2], "A: uno | B: dos | A: tres")
  expect_equal(out$contexto[3], "B: dos | A: tres")
})

test_that("recompute_contexto omite labels vacíos y respeta speaker vacío", {
  df <- data.frame(speaker = c("", "B"), label = c("hola", ""),
                   stringsAsFactors = FALSE)
  out <- recompute_contexto(df, window = 5)
  expect_equal(out$contexto[1], "hola")
})

test_that("corpus_base_name limpia ruta, extensión y prefijo", {
  expect_equal(corpus_base_name("/x/muestra_1.TextGrid"), "muestra_1")
  expect_equal(corpus_base_name("analisis_muestra_1.txt"), "muestra_1")
  expect_equal(corpus_base_name(NULL), "corpus")
  expect_equal(corpus_base_name(""), "corpus")
})
```

- [ ] **Step 2: Ejecutar y verificar FALLO**

Run: `Rscript -e 'testthat::test_dir("tests/testthat", stop_on_failure = TRUE)'`
Expected: FAIL — `could not find function "format_cita"`

- [ ] **Step 3: Crear `R/contexto.R`**

```r
# R/contexto.R — utilidades de contexto (puras, base R + tools)

format_cita <- function(corpus, start, end) {
  s <- sprintf("%.2f", suppressWarnings(as.numeric(start)))
  e <- sprintf("%.2f", suppressWarnings(as.numeric(end)))
  sprintf("(%s, %s-%s)", corpus, s, e)
}

recompute_contexto <- function(df, window = 5) {
  if (!"contexto" %in% names(df)) df$contexto <- NA_character_
  n_rows <- nrow(df)
  for (i in seq_len(n_rows)) {
    filas_ctx <- max(1, i - window):min(n_rows, i + window)
    ctx <- mapply(function(sp, lb) {
      sp <- trimws(ifelse(is.na(sp), "", sp))
      lb <- trimws(ifelse(is.na(lb), "", lb))
      if (!nzchar(lb)) return("")
      if (nzchar(sp)) paste0(sp, ": ", lb) else lb
    }, df$speaker[filas_ctx], df$label[filas_ctx])
    df$contexto[i] <- paste(ctx[nzchar(ctx)], collapse = " | ")
  }
  df
}

corpus_base_name <- function(filename) {
  if (is.null(filename) || !nzchar(filename)) return("corpus")
  b <- tools::file_path_sans_ext(basename(filename))
  sub("^analisis_", "", b)
}
```

- [ ] **Step 4: Añadir `"contexto.R"` al bucle `source()` del arranque**

En `etiquetador_oral.R`, el bucle (tras `setwd(APP_DIR)`):

```r
  for (.f in c("stats_utils.R", "agreement.R", "corpus_stats.R", "plot_export.R", "prefs.R")) {
```

cámbialo a:

```r
  for (.f in c("stats_utils.R", "agreement.R", "corpus_stats.R", "plot_export.R", "prefs.R", "contexto.R")) {
```

- [ ] **Step 5: Añadir `"contexto.R"` a `tests/testthat/setup.R`**

En la lista de helpers de `setup.R`, añade `"contexto.R"` al vector.

- [ ] **Step 6: Reemplazar el bucle inline de contexto por el helper**

En `etiquetador_oral.R`, localiza este bloque (empieza con el comentario `# contexto ±5`):

```r
    # contexto ±5
    if (!"contexto" %in% names(df)) df$contexto <- NA_character_
    n_rows <- nrow(df)
    for (i in seq_len(n_rows)) {
      filas_ctx <- max(1, i - 5):min(n_rows, i + 5)
      ctx <- mapply(function(sp, lb) {
        sp <- trimws(ifelse(is.na(sp), "", sp))
        lb <- trimws(ifelse(is.na(lb), "", lb))
        if (!nzchar(lb)) return("")
        if (nzchar(sp)) paste0(sp, ": ", lb) else lb
      }, df$speaker[filas_ctx], df$label[filas_ctx])
      df$contexto[i] <- paste(ctx[nzchar(ctx)], collapse = " | ")
    }
```

y sustitúyelo por:

```r
    # contexto ±5 (helper en R/contexto.R)
    df <- recompute_contexto(df, window = 5)
```

(NO toques las líneas siguientes de reordenación de columnas `col_ord <- make_col_order()` …)

- [ ] **Step 7: Ejecutar y verificar PASA + parse + build**

Run: `Rscript -e 'testthat::test_dir("tests/testthat", stop_on_failure = TRUE)'`  → PASS
Run: `Rscript -e 'invisible(parse("etiquetador_oral.R")); cat("PARSE OK\n")'`  → `PARSE OK`
Run: `Rscript -e 'shinyApp <- function(ui, server) cat("BUILT OK\n"); suppressWarnings(source("etiquetador_oral.R"))'`  → `BUILT OK`

- [ ] **Step 8: Commit**

```bash
git add R/contexto.R tests/testthat/test-contexto.R etiquetador_oral.R tests/testthat/setup.R
git commit -m "feat: helpers puros de contexto (format_cita, recompute_contexto) + refactor"
```

---

### Task 2: Reorganización del menú superior

**Files:**
- Modify: `etiquetador_oral.R` (UI `tabsetPanel` principal)

**Interfaces:**
- Consumes: nada de tasks previas. Mueve `output$…` existentes sin cambiarlos.

**Contexto del cambio:** En el `tabsetPanel` principal hay, en orden, los `tabPanel` "Tabla", "Contexto", "Analisis fonetico", "Metricas", "Praatpicture", "Estadísticas", "Coincidencia", "Corpus", "Configuración". Vas a: (a) borrar "Tabla"; (b) convertir "Analisis fonetico" en contenedor de subpestañas Imágenes/Métricas/Praatpicture, moviendo dentro el contenido de "Metricas" y "Praatpicture" y borrando esos dos `tabPanel` superiores; (c) convertir "Estadísticas" en contenedor de subpestañas Este archivo/Corpus completo, moviendo dentro el contenido de "Corpus" y borrando ese `tabPanel` superior.

- [ ] **Step 1: Borrar la pestaña «Tabla»**

Elimina por completo este `tabPanel` (incluida su coma final):

```r
            tabPanel("Tabla",
              div(style = "padding: 6px 0 2px;",
                checkboxInput("show_contexto", "Mostrar columna 'contexto'", value = FALSE)
              ),
              DTOutput("table")
            ),
```

- [ ] **Step 2: Convertir «Analisis fonetico» en contenedor de subpestañas**

Reemplaza el `tabPanel("Analisis fonetico", br(), … )` ENTERO (su contenido actual: botones, `video_player`, `oscillo_plot`, `spectro_plot`, `pitch_plot`) por la siguiente estructura, MOVIENDO dentro de la subpestaña «Imágenes» ese contenido actual VERBATIM, y dentro de «Métricas» y «Praatpicture» el contenido de los `tabPanel` superiores homónimos (que borrarás en el Step 3):

```r
            tabPanel("Analisis fonetico", br(),
              tabsetPanel(type = "tabs",
                tabPanel("Imágenes", br(),
                  # ↓↓↓ PEGA AQUÍ EL CONTENIDO ACTUAL del tabPanel("Analisis fonetico"):
                  #     el fluidRow de botones (play_segment1, compute_all, helper, hr),
                  #     fluidRow(uiOutput("video_player")), br(),
                  #     fluidRow(oscillo_plot, spectro_plot), br(), plotOutput("pitch_plot")
                  fluidRow(column(12,
                    actionButton("play_segment1","Reproducir segmento",
                                 icon = icon("play"), class = "btn-success btn-sm",
                                 style = "margin-right:5px;"),
                    actionButton("compute_all","Calcular F0/Int de todos los segmentos",
                                 class = "btn-danger btn-sm"),
                    div(class = "small-helper-text",
                        "Calcula métricas acústicas para todas las filas."),
                    hr()
                  )),
                  fluidRow(column(12, uiOutput("video_player"))),
                  br(),
                  fluidRow(
                    column(6, plotOutput("oscillo_plot",  height = 250)),
                    column(6, plotOutput("spectro_plot",  height = 250))
                  ),
                  br(),
                  plotOutput("pitch_plot", height = 300)
                ),
                tabPanel("Métricas", br(),
                  h5("Análisis prosódico de la fila actual"),
                  verbatimTextOutput("metrics_display")
                ),
                tabPanel("Praatpicture", br(),
                  if (HAS_PRAATPICTURE) {
                    tagList(
                      fluidRow(
                        column(3, checkboxInput("pp_show_wave",  "Oscilograma", TRUE)),
                        column(3, checkboxInput("pp_show_spec",  "Espectrograma", TRUE)),
                        column(3, checkboxInput("pp_show_pitch", "F0", TRUE)),
                        column(3, checkboxInput("pp_show_int",   "Intensidad", FALSE))
                      ),
                      actionButton("render_praatpic", "Renderizar",
                                   class = "btn-info btn-sm", style = "margin-bottom:10px;"),
                      plotOutput("praatpicture_plot", height = 500)
                    )
                  } else {
                    div(
                      class = "small-helper-text",
                      style = "padding:20px;",
                      tags$b("El paquete 'praatpicture' no está instalado."),
                      br(),
                      "Instálalo con: ",
                      tags$code("install.packages('praatpicture')")
                    )
                  }
                )
              )
            ),
```

- [ ] **Step 3: Borrar los `tabPanel` superiores «Metricas» y «Praatpicture»**

Elimina por completo (ya están reubicados en el Step 2) estos dos `tabPanel` del nivel superior, incluidas sus comas:

```r
            tabPanel("Metricas", br(),
              h5("Análisis prosódico de la fila actual"),
              verbatimTextOutput("metrics_display")
            ),
```

y

```r
            tabPanel("Praatpicture", br(),
              if (HAS_PRAATPICTURE) {
                ... (todo el bloque) ...
              }
            ),
```

- [ ] **Step 4: Convertir «Estadísticas» en contenedor de subpestañas**

Transforma el `tabPanel("Estadísticas", br(), tabsetPanel(...))` actual envolviéndolo en un nuevo `tabsetPanel` de dos subpestañas. La subpestaña «Este archivo» contiene EL `tabsetPanel` actual de Estadísticas (Barras/Boxplots) verbatim; la subpestaña «Corpus completo» contiene el cuerpo del `tabPanel("Corpus", …)` (que borrarás en el Step 5). Estructura resultante:

```r
            tabPanel("Estadísticas", br(),
              tabsetPanel(type = "tabs",
                tabPanel("Este archivo", br(),
                  # ↓↓↓ PEGA AQUÍ el tabsetPanel actual de Estadísticas (Barras + Boxplots) VERBATIM
                  tabsetPanel(type = "tabs",
                    tabPanel("Barras", br(),
                      # ... contenido actual de Barras (stat_cat_var, stat_bar_type,
                      #     stat_bar_update, stat_barplot, botones PNG/PDF) ...
                    ),
                    tabPanel("Boxplots", br(),
                      # ... contenido actual de Boxplots (stat_num_var, stat_group_var,
                      #     stat_box_update, stat_boxplot, botones PNG/PDF, stat_summary) ...
                    )
                  )
                ),
                tabPanel("Corpus completo", br(),
                  # ↓↓↓ PEGA AQUÍ el cuerpo del tabPanel("Corpus", …) VERBATIM:
                  #     fluidRow(helper + corpus_refresh), fileInput(corpus_file), hr(),
                  #     corpus_summary, corpus_perfile, hr(), corpus_desc, hr(),
                  #     "Gráfico" + selects + corpus_plot + botones PNG/PDF, hr(),
                  #     "Agrupar por hasta 4 variables" + corpus_g1..g4 + corpus_cross
                )
              )
            ),
```

> Mueve los bloques internos CORTANDO Y PEGANDO los existentes (no los reescribas) para evitar deriva. Mantén intactos todos los `output$…`/`input$…` ids.

- [ ] **Step 5: Borrar el `tabPanel` superior «Corpus»**

Elimina por completo el `tabPanel("Corpus", br(), …)` del nivel superior (ya reubicado en el Step 4), incluida su coma.

- [ ] **Step 6: Verificar parse + build + tests**

Run: `Rscript -e 'invisible(parse("etiquetador_oral.R")); cat("PARSE OK\n")'`  → `PARSE OK`
Run: `Rscript -e 'shinyApp <- function(ui, server) cat("BUILT OK\n"); suppressWarnings(source("etiquetador_oral.R"))'`  → `BUILT OK`
Run: `Rscript -e 'testthat::test_dir("tests/testthat", stop_on_failure = TRUE)'`  → `FAIL 0 | WARN 0`

Verificación manual (usuario): el menú superior muestra exactamente Anotaciones · Contexto · Análisis fonético · Estadísticas · Coincidencia · Configuración; Análisis fonético tiene Imágenes/Métricas/Praatpicture; Estadísticas tiene Este archivo/Corpus completo.

- [ ] **Step 7: Commit**

```bash
git add etiquetador_oral.R
git commit -m "feat: reorganizar menú (quitar Tabla; subpestañas en Análisis fonético y Estadísticas)"
```

---

### Task 3: Contexto — edición de la fila activa + columna `ejemplo_para_paper`

**Files:**
- Modify: `etiquetador_oral.R` (UI del `tabPanel("Contexto")`; servidor: observers + `output$context_table`)

**Interfaces:**
- Consumes: `format_cita`, `recompute_contexto`, `corpus_base_name` (Task 1); `rv$df_full`, `rv$selected_row_index`, `rv$current_filename`, `save_analysis_file`, `dt_with_buttons`, `%||%` (existentes).

- [ ] **Step 1: Reemplazar la UI del `tabPanel("Contexto")`**

Sustituye el `tabPanel("Contexto", br(), …)` actual por:

```r
            tabPanel("Contexto", br(),
              fluidRow(
                column(4, textInput("edit_speaker", "Speaker:", width = "100%")),
                column(6, textInput("edit_label", "Label (texto):", width = "100%")),
                column(2, br(),
                  actionButton("save_row_edit", "Guardar fila",
                               class = "btn-primary btn-sm", style = "width:100%;"))
              ),
              fluidRow(
                column(4, numericInput("context_rows","Filas de contexto (+-):",
                                       value = 5, min = 1, max = 20, step = 1, width = "100%")),
                column(4, br(),
                  actionButton("toggle_ejemplo", "Mostrar ejemplo_para_paper",
                               class = "btn-info btn-sm", style = "width:100%;")),
                column(4, div(class = "small-helper-text", br(),
                              "El contexto se muestra en orden temporal con formato ",
                              tags$code("speaker: texto")))
              ),
              hr(), DTOutput("context_table")
            ),
```

- [ ] **Step 2: Añadir los observers de edición y toggle en el servidor**

Añade en `server` (cerca del bloque de `context_table`):

```r
  # --- Contexto: editar la fila activa y guardar ---
  observeEvent(rv$selected_row_index, {
    req(rv$df_full, rv$selected_row_index)
    idx <- rv$selected_row_index
    updateTextInput(session, "edit_speaker", value = rv$df_full$speaker[idx] %||% "")
    updateTextInput(session, "edit_label",   value = rv$df_full$label[idx]   %||% "")
  })

  observeEvent(input$save_row_edit, {
    req(rv$df_full, rv$selected_row_index)
    idx <- rv$selected_row_index
    rv$df_full$speaker[idx] <- input$edit_speaker %||% ""
    rv$df_full$label[idx]   <- input$edit_label   %||% ""
    rv$df_full <- recompute_contexto(rv$df_full, window = 5)
    tryCatch({
      save_analysis_file(rv$df_full, rv$current_filename, make_backup_copy = FALSE)
      showNotification("Fila guardada", type = "message")
    }, error = function(e) showNotification(paste("Error al guardar:", e$message), type = "error"))
  })

  # --- Contexto: mostrar/ocultar columna ejemplo_para_paper ---
  show_ejemplo <- reactiveVal(FALSE)
  observeEvent(input$toggle_ejemplo, {
    show_ejemplo(!show_ejemplo())
    updateActionButton(session, "toggle_ejemplo",
      label = if (show_ejemplo()) "Ocultar ejemplo_para_paper" else "Mostrar ejemplo_para_paper")
  })
```

- [ ] **Step 3: Reescribir `output$context_table` con la columna `ejemplo_para_paper`**

Sustituye el `output$context_table <- renderDT({ … }, server = FALSE)` actual por:

```r
  output$context_table <- renderDT({
    req(rv$df_full, rv$selected_row_index, input$context_rows)
    idx    <- rv$selected_row_index
    nc     <- input$context_rows
    filas  <- max(1, idx - nc):min(nrow(rv$df_full), idx + nc)
    corpus <- corpus_base_name(rv$current_filename %||% "")
    cita   <- format_cita(corpus, rv$df_full$start[idx], rv$df_full$end[idx])
    ctx_df <- data.frame(
      Fila     = filas,
      speaker  = rv$df_full$speaker[filas],
      label    = rv$df_full$label[filas],
      ejemplo_para_paper = paste0(rv$df_full$contexto[filas], " ", cita),
      es_actual= (filas == idx),
      stringsAsFactors = FALSE
    )
    # es_actual (índice 4) siempre oculta; ejemplo_para_paper (índice 3) oculta salvo toggle
    hidden <- if (show_ejemplo()) 4 else c(3, 4)
    datatable(ctx_df,
      extensions = "Buttons",
      options = dt_with_buttons(list(pageLength = 2 * nc + 1, scrollX = TRUE,
                     searching = FALSE, paging = FALSE,
                     columnDefs = list(list(targets = hidden, visible = FALSE)))),
      rownames = FALSE
    ) %>% formatStyle("es_actual", target = "row",
                      backgroundColor = styleEqual(c(TRUE,FALSE), c("#ffffcc","white")))
  }, server = FALSE)
```

- [ ] **Step 4: Verificar parse + build + tests**

Run: `Rscript -e 'invisible(parse("etiquetador_oral.R")); cat("PARSE OK\n")'`  → `PARSE OK`
Run: `Rscript -e 'shinyApp <- function(ui, server) cat("BUILT OK\n"); suppressWarnings(source("etiquetador_oral.R"))'`  → `BUILT OK`
Run: `Rscript -e 'testthat::test_dir("tests/testthat", stop_on_failure = TRUE)'`  → `FAIL 0 | WARN 0`

Verificación manual (usuario): cargar un análisis, ir a Contexto, editar speaker/label de la fila activa y pulsar «Guardar fila» (comprobar que el TSV cambia); pulsar «Mostrar ejemplo_para_paper» y ver la columna con la cita `(corpus, inicio-fin)` de la fila activa.

- [ ] **Step 5: Commit**

```bash
git add etiquetador_oral.R
git commit -m "feat: Contexto — editar speaker/label de la fila activa y columna ejemplo_para_paper"
```

---

### Task 4: Logo hexagonal

**Files:**
- Create: `www/logo.svg`
- Modify: `etiquetador_oral.R` (insertar el logo en `titlePanel`)

- [ ] **Step 1: Crear `www/logo.svg`**

Crea la carpeta `www` si no existe y escribe `www/logo.svg`:

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="100" height="100" role="img" aria-label="Oraltags">
  <polygon points="50,4 91,27 91,73 50,96 9,73 9,27" fill="#e95420" stroke="#b5401a" stroke-width="3"/>
  <rect x="24" y="30" width="52" height="30" rx="9" fill="#ffffff"/>
  <polygon points="36,59 36,73 50,59" fill="#ffffff"/>
  <g stroke="#e95420" stroke-width="4" stroke-linecap="round">
    <line x1="34" y1="40" x2="34" y2="50"/>
    <line x1="42" y1="35" x2="42" y2="55"/>
    <line x1="50" y1="38" x2="50" y2="52"/>
    <line x1="58" y1="33" x2="58" y2="57"/>
    <line x1="66" y1="41" x2="66" y2="49"/>
  </g>
</svg>
```

- [ ] **Step 2: Insertar el logo en el `titlePanel`**

Localiza el `titlePanel(div( … span("Oraltags") … ))` en la UI. Envuelve el logo y el título en un `div` flex a la izquierda. Sustituye el `div(...)` interno del titlePanel por:

```r
    titlePanel(div(
      style = "display:flex; align-items:center; justify-content:space-between;",
      div(style = "display:flex; align-items:center;",
        tags$img(src = "logo.svg", height = "40px", style = "margin-right:10px;"),
        span("Oraltags", style = "font-size:22px; font-weight:600;")
      ),
      span(style = "font-size:12px; color:#6b7280;",
           "Etiquetador de datos orales · explorador prosódico")
    )),
```

> Si el texto del subtítulo actual difiere, conserva el subtítulo existente; solo añade el `tags$img(...)` antes del `span("Oraltags")` envolviéndolos en el `div` flex izquierdo.

- [ ] **Step 3: Verificar parse + build**

Run: `Rscript -e 'invisible(parse("etiquetador_oral.R")); cat("PARSE OK\n")'`  → `PARSE OK`
Run: `Rscript -e 'shinyApp <- function(ui, server) cat("BUILT OK\n"); suppressWarnings(source("etiquetador_oral.R"))'`  → `BUILT OK`

Verificación manual (usuario): el logo hexagonal naranja aparece junto al título «Oraltags».

- [ ] **Step 4: Commit (solo el logo y el código, no el resto de `www/`)**

```bash
git add www/logo.svg etiquetador_oral.R
git commit -m "feat: logo hexagonal junto al título"
```

---

### Task 5: Documentación y verificación final

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Actualizar la tabla de pestañas del README**

En la tabla de pestañas, refleja el nuevo menú: elimina la fila **Tabla**, integra **Métricas**/**Praatpicture** como subpestañas de **Análisis fonético** y **Corpus** como subpestaña de **Estadísticas**. Sustituye las filas afectadas para que la tabla quede con: Anotaciones, Contexto, Análisis fonético (Imágenes/Métricas/Praatpicture), Estadísticas (Este archivo/Corpus completo), Coincidencia, Configuración. Añade una nota sobre la edición de speaker/label en Contexto y la columna `ejemplo_para_paper`. Usa este bloque para las filas reorganizadas:

```markdown
| **Contexto** | Filas anteriores/posteriores a la selección; permite **editar speaker/label de la fila activa** (se guarda en el análisis) y mostrar una columna **`ejemplo_para_paper`** con cita `(corpus, inicio-fin)`. |
| **Análisis fonético** | Subpestañas **Imágenes** (oscilograma, espectrograma, F0), **Métricas** (informe prosódico) y **Praatpicture** (figura multipanel). |
| **Estadísticas** | Subpestañas **Este archivo** (barras/boxplots del corpus cargado) y **Corpus completo** (visión global de `analisis_todos.txt`). |
```

- [ ] **Step 2: Ejecutar suite + parse + build finales**

Run: `Rscript -e 'testthat::test_dir("tests/testthat", stop_on_failure = TRUE)'`  → `FAIL 0 | WARN 0`
Run: `Rscript -e 'invisible(parse("etiquetador_oral.R")); cat("OK\n")'`  → `OK`
Run: `Rscript -e 'shinyApp <- function(ui, server) cat("BUILT OK\n"); suppressWarnings(source("etiquetador_oral.R"))'`  → `BUILT OK`

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: menú reorganizado, edición en Contexto y ejemplo_para_paper"
```

---

## Self-Review

**Spec coverage:**
- A. Quitar Tabla → Task 2 Step 1. ✓
- B.1 Editar fila activa → Task 3 (UI + observers + save). `recompute_contexto` de Task 1. ✓
- B.2 `ejemplo_para_paper` + cita → Task 3 Step 3 + `format_cita`/`corpus_base_name` (Task 1). ✓
- C. Análisis fonético subpestañas (mover Métricas/Praatpicture) → Task 2 Steps 2-3. ✓
- D. Estadísticas subpestañas (mover Corpus) → Task 2 Steps 4-5. ✓
- E. Logo → Task 4. ✓
- Refactor del cálculo de contexto (DRY para que el guardado lo reuse) → Task 1 Step 6. ✓

**Placeholder scan:** los bloques marcados «PEGA AQUÍ …» en la Task 2 son MOVIMIENTOS verbatim de bloques existentes en el archivo (no contenido por inventar); se indican rangos/identificadores exactos y el parse/build es la verificación. El resto del código está completo.

**Type consistency:** `format_cita(corpus, start, end)`, `recompute_contexto(df, window)`, `corpus_base_name(filename)` definidos en Task 1 y usados en Task 3. `show_ejemplo` reactiveVal usado en el observer y en `context_table` (Task 3). Ids de columnas de `ctx_df` (Fila=0, speaker=1, label=2, ejemplo_para_paper=3, es_actual=4) coherentes con `columnDefs` `hidden`. Ids de inputs `edit_speaker/edit_label/save_row_edit/toggle_ejemplo` coinciden entre UI (Task 3 Step 1) y servidor (Task 3 Step 2).

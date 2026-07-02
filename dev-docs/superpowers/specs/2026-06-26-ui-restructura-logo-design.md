# Diseño: reorganización de pestañas, edición en Contexto y logo

Fecha: 2026-06-26
App: `etiquetador_oral.R` (Oraltags, Shiny de un solo archivo, ~2790 líneas)
Rama: `feature/ui-restructura-logo`

## Contexto

El menú superior (`tabsetPanel`) tiene hoy estas pestañas: Anotaciones, Tabla, Contexto,
Análisis fonético, Métricas, Praatpicture, Estadísticas, Coincidencia, Corpus, Configuración.

Datos relevantes del código:
- `context_table` (render ~1924, `server = FALSE`) construye `ctx_df` con columnas
  `Fila, speaker, label, contexto, es_actual` a partir de `rv$df_full` alrededor de
  `rv$selected_row_index`. La columna `contexto` por fila se calcula en ~1703
  (`paste(ctx, collapse=" | ")`).
- Persistencia: `save_analysis_file(rv$df_full, rv$current_filename)` escribe el TSV de
  análisis y el consolidado. `rv$selected_row_index` es la fila activa.
- `rv$current_filename` permite derivar el nombre base del corpus.
- El título/cabecera está en `titlePanel(div(... span("Oraltags") ...))` (~427).
- Tema Shiny: `shinytheme("united")` (naranja `#e95420`).

Este lote es reorganización de UI + pequeñas funciones; va ANTES del selector de idioma.

## Decisiones tomadas (brainstorming)

1. Quitar «Tabla» del menú (solo desactivar en UI; servidor intacto).
2. En Contexto: editar `speaker`/`label` de la **fila activa** (guardar al archivo de análisis);
   columna `ejemplo_para_paper` (toggle por botón) con cita `(corpus, inicio-fin)` usando los
   **tiempos de la fila activa**, añadida a **todas** las celdas.
3. «Análisis fonético» con 3 subpestañas: Imágenes, Métricas, Praatpicture (Métricas y
   Praatpicture se mueven desde el nivel superior y desaparecen de arriba).
4. «Estadísticas» con 2 subpestañas: Este archivo (la actual) y Corpus completo (la pestaña
   superior Corpus, que desaparece de arriba).
5. Logo hexagonal naranja con bocadillo + onda, junto al título.

---

## A. Quitar pestaña «Tabla»

- Eliminar el `tabPanel("Tabla", …)` del `tabsetPanel`. NO tocar el servidor
  (`output$table`, `dataTableProxy("table")`, `observeEvent(input$table_cell_edit, …)`):
  quedan inactivos pero presentes (YAGNI: reactivable sin reescribir).

## B. Pestaña «Contexto»

### B.1 Edición de la fila activa (arriba, antes de «Filas de contexto»)
- UI: un `fluidRow` con `textInput("edit_speaker", "Speaker:")`,
  `textInput("edit_label", "Label (texto):")` y
  `actionButton("save_row_edit", "Guardar fila", class = "btn-primary btn-sm")`.
- Servidor:
  - `observeEvent(rv$selected_row_index, …)`: precarga los dos campos con
    `rv$df_full$speaker[idx]` y `rv$df_full$label[idx]` (vía `updateTextInput`).
  - `observeEvent(input$save_row_edit, …)`: con `idx <- rv$selected_row_index`, asigna
    `rv$df_full$speaker[idx] <- input$edit_speaker` y `rv$df_full$label[idx] <- input$edit_label`,
    recalcula la columna `contexto` (la misma rutina que ya la genera, porque el texto del
    contexto depende de `label`), persiste con
    `save_analysis_file(rv$df_full, rv$current_filename)` y muestra
    `showNotification("Fila guardada")`. Requiere `req(rv$df_full, rv$selected_row_index)`.

### B.2 Columna `ejemplo_para_paper` (toggle)
- UI: `actionButton("toggle_ejemplo", "Mostrar ejemplo_para_paper", class = "btn-info btn-sm")`.
- Servidor: un `reactiveVal show_ejemplo (FALSE)` que alterna con cada clic; el texto del
  botón cambia entre «Mostrar…»/«Ocultar…».
- `context_table` pasa a incluir una columna `ejemplo_para_paper` en lugar de la antigua
  `contexto` visible. Su contenido por fila:
  `paste0(<contexto de la fila>, " ", format_cita(corpus, start_activa, end_activa))`,
  donde `corpus` = nombre base del corpus (de `rv$current_filename`) y `start_activa`/`end_activa`
  son `rv$df_full$start/end[rv$selected_row_index]`.
- Visibilidad: la columna `ejemplo_para_paper` se oculta vía `columnDefs`
  (`visible = FALSE`) cuando `show_ejemplo()` es `FALSE`, y se muestra cuando es `TRUE`.
- `es_actual` sigue oculta y el resaltado de la fila activa (`formatStyle`) se mantiene.

### Helper puro testeable
- `format_cita(corpus, start, end)` → `"(<corpus>, <s>-<e>)"` con `start`/`end`
  formateados a 2 decimales (`sprintf("%.2f", as.numeric(x))`); corpus tal cual.
  Va en `R/cita.R` (sourceado al arranque) y se testea con `testthat`.

## C. «Análisis fonético» con subpestañas

- El `tabPanel("Analisis fonetico", …)` pasa a contener un `tabsetPanel(type="tabs")` con:
  - **Imágenes**: el contenido actual (botones reproducir/`compute_all`, `video_player`,
    `oscillo_plot`, `spectro_plot`, `pitch_plot`).
  - **Métricas**: el contenido del actual `tabPanel("Metricas", …)` (`metrics_display`).
  - **Praatpicture**: el contenido del actual `tabPanel("Praatpicture", …)` (checkboxes,
    botón render, `praatpicture_plot`, y la rama `HAS_PRAATPICTURE`).
- Se ELIMINAN del nivel superior los `tabPanel("Metricas", …)` y `tabPanel("Praatpicture", …)`.
- Los `output$…` y sus ids no cambian (solo se mueven en la UI), así que el servidor sigue igual.

## D. «Estadísticas» con subpestañas

- El `tabPanel("Estadísticas", …)` pasa a contener un `tabsetPanel(type="tabs")` con:
  - **Este archivo**: el contenido actual de Estadísticas (su `tabsetPanel` Barras/Boxplots
    sobre `rv$df_full`) — anidado.
  - **Corpus completo**: el contenido del actual `tabPanel("Corpus", …)`.
- Se ELIMINA del nivel superior el `tabPanel("Corpus", …)`.
- Ids de `output$…` sin cambios.

## E. Logo hexagonal

- Crear `www/logo.svg`: hexágono (relleno naranja `#e95420`, borde más oscuro) con un
  bocadillo de diálogo blanco y, dentro o bajo él, una pequeña onda de sonido (barras
  verticales). Vectorial, escalable, ~40 px en la cabecera.
- Insertar en `titlePanel(...)`: `tags$img(src = "logo.svg", height = "40px",
  style = "margin-right:10px;")` antes del `span("Oraltags")`, dentro del `div` flex.

---

## Menú superior resultante
Anotaciones · Contexto · Análisis fonético · Estadísticas · Coincidencia · Configuración.
(Eliminadas: Tabla, Métricas, Praatpicture, Corpus — estas tres últimas reubicadas como
subpestañas.)

## Integración
- Todo en `etiquetador_oral.R` salvo el helper puro (`R/cita.R`) y el logo (`www/logo.svg`).
- Añadir `"cita.R"` al bucle `source()` del arranque y a `tests/testthat/setup.R`.
- Sin dependencias nuevas.

## Plan de pruebas
- `testthat` para `format_cita()` (2 decimales; enteros y decimales; corpus literal).
- Verificación de UI: `parse()` OK; build con stub `shinyApp` (BUILT OK); suite verde.
- Verificación manual (usuario): el menú ya no muestra Tabla/Métricas/Praatpicture/Corpus;
  Análisis fonético y Estadísticas tienen sus subpestañas; editar speaker/label de la fila
  activa y comprobar que se guarda; toggle de `ejemplo_para_paper` con la cita correcta;
  el logo aparece junto al título.

## Fuera de alcance (YAGNI)
- Edición inline de cualquier fila del contexto (solo la fila activa).
- Borrar el código de servidor de la pestaña Tabla (solo se oculta).
- Selector de idioma (lote posterior).

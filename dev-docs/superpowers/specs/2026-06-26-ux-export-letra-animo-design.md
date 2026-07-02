# Diseño: lote UX — descargas, tamaño de letra y mensajes de ánimo

Fecha: 2026-06-26
App: `etiquetador_oral.R` (Oraltags, Shiny de un solo archivo, ~2731 líneas)
Rama: `feature/ux-export-letra-animo`

## Contexto

Oraltags tiene 8 gráficos (`plotOutput`) y 7 tablas (`DTOutput`) y ninguno tiene hoy
botón de descarga. Los `cex` de los gráficos están fijos (texto pequeño). La pestaña
**Configuración** ya existe, igual que el sistema de carpetas de trabajo (`CONFIG_DIR`,
`ensure_dirs()`), por lo que es el lugar natural para preferencias persistentes.

Gráficos (ids): `oscillo_plot`, `spectro_plot`, `pitch_plot` (acústicos), `praatpicture_plot`,
`stat_barplot`, `stat_boxplot` (Estadísticas), `coinc_barplot` (Coincidencia), `corpus_plot` (Corpus).
Tablas (ids): `table`, `context_table`, `coinc_files_info`, `coinc_table`,
`corpus_perfile`, `corpus_desc`, `corpus_cross`.

Este lote NO incluye el selector de idioma (se diseña como Spec 2 aparte). Las frases
de ánimo se definen como cadenas en español ahora; en el Spec 2 pasarán por i18n.

## Decisiones tomadas (brainstorming)

1. Descarga en alta calidad solo para los **4 gráficos estadísticos/datos**:
   `stat_barplot`, `stat_boxplot`, `coinc_barplot`, `corpus_plot`.
2. Formato de descarga: **PNG a 300 ppp + PDF vectorial** (dos botones por gráfico).
3. Tablas: **botones CSV + Excel + Copiar** (extensión Buttons de DT), exportando **todas las filas**.
4. Tamaño de letra: **un deslizador global** en Configuración que escala el texto de
   todos los gráficos base-R (no praatpicture) y también las descargas.
5. Mensajes de ánimo: **modal de bienvenida** al iniciar, activable desde Configuración
   (**desmarcado por defecto**), con **frase predefinida al azar** o **mensaje propio**.

---

## Componente 1 — Tamaño de letra global de gráficos

### UI (Configuración)
- `sliderInput("plot_font_scale", "Tamaño de letra de gráficos:", min = 0.7, max = 2,
  value = 1, step = 0.1, width = "100%")`.

### Servidor
- Reactivo `gcex <- reactive({ as.numeric(input$plot_font_scale %||% 1) })`.
- En cada gráfico base-R se multiplican los tamaños de texto por `gcex()`:
  `cex.axis`, `cex.names`, `cex.main`, `cex.lab` y los `cex` de etiquetas de barras y de
  `stripchart`. Afecta a: `oscillo_plot`, `spectro_plot`, `pitch_plot`, `stat_barplot`,
  `stat_boxplot`, `coinc_barplot`, `corpus_plot`. **`praatpicture_plot` queda fuera**
  (la figura la dimensiona el propio paquete).
- El valor inicial proviene de las preferencias persistentes (Componente 4).

---

## Componente 2 — Descarga de gráficos (PNG 300 ppp + PDF)

### Refactor DRY
El cuerpo de dibujo de cada uno de los 4 gráficos estadísticos se extrae a una función
`draw_<id>()` (p. ej. `draw_stat_barplot()`), que lee los `input$`/`rv$` que necesita y
usa `gcex()`. Tanto `renderPlot` como los `downloadHandler` invocan esa función, de modo
que la descarga reproduce exactamente lo que se ve en pantalla.

### UI
Bajo cada uno de los 4 gráficos, una fila con dos botones:
`downloadButton("<id>_png", "PNG")` y `downloadButton("<id>_pdf", "PDF")`.

### Servidor (helper reutilizable)
- `add_plot_download(output, id, draw_fun, basename)` registra dos `downloadHandler`:
  - `<id>_png`: nombre `plot_filename(basename, "png")`; `grDevices::png(file, width = 9,
    height = 6, units = "in", res = 300)`, dibuja con `draw_fun()`, `dev.off()`.
  - `<id>_pdf`: nombre `plot_filename(basename, "pdf")`; `grDevices::pdf(file, width = 9,
    height = 6)` (vectorial), dibuja con `draw_fun()`, `dev.off()`.
- `basename` por gráfico: `barras`, `boxplot`, `coincidencia_kappa`, `corpus`.

### Utilidad pura (testeable, en `R/plot_export.R`)
- `plot_filename(base, ext, date = Sys.Date())`:
  saneado a `[a-z0-9_-]` + fecha ISO + extensión → `"<base>_AAAA-MM-DD.<ext>"`.

---

## Componente 3 — Exportación de tablas (CSV/Excel/Copiar)

### Helper
- `dt_with_buttons(options = list())`: devuelve una lista de opciones de `DT::datatable`
  que añade `dom` con `B` (Buttons) y `buttons = list(list(extend = "copy",
  exportOptions = list(modifier = list(page = "all"))), list(extend = "csv", ...),
  list(extend = "excel", ...))`, conservando/uniendo el `dom` y demás claves ya presentes
  en `options`. Exporta **todas las filas** (`page = "all"`).
- Cada una de las 7 tablas pasa a `DT::datatable(..., extensions = "Buttons",
  options = dt_with_buttons(<opciones actuales>))`. Se respetan paginación y selección
  existentes de cada tabla.
- Si el botón Excel no estuviera disponible sin conexión, CSV y Copiar siguen operativos
  (no es bloqueante).

---

## Componente 4 — Mensajes de ánimo (modal de bienvenida) + preferencias persistentes

### Persistencia
- Archivo `config/preferencias.txt` (líneas `clave<TAB>valor`), con helpers puros en
  `R/prefs.R`:
  - `load_prefs(path)`: devuelve una named list con defaults si el archivo no existe:
    `list(animo_enabled = FALSE, animo_custom = "", plot_font_scale = 1)`.
  - `save_prefs(prefs, path)`: escribe las claves conocidas en formato `clave<TAB>valor`.
  - Parsing robusto: ignora líneas vacías/mal formadas; convierte tipos (`TRUE/FALSE`,
    numérico) de forma segura.
- `choose_message(custom, presets)`: si `custom` no está vacío (tras `trimws`) lo devuelve;
  si no, devuelve `sample(presets, 1)`; si `presets` está vacío, `""`.

### UI (Configuración, bloque "Preferencias")
- `checkboxInput("animo_enabled", "Mostrar mensaje de ánimo al iniciar", value = FALSE)`.
- `textAreaInput("animo_custom", "Tu propio mensaje (opcional):", rows = 2)`.
- El deslizador `plot_font_scale` (Componente 1) vive en este mismo bloque.
- `actionButton("save_prefs_btn", "Guardar preferencias")` que persiste los tres valores.
  Al guardar, `showNotification("Preferencias guardadas")`.

### Frases predefinidas
- Vector `ANIMO_PRESETS` (constante, ~8–10 frases de ánimo para el investigador en
  español). Ejemplo: "Cada grupo entonativo que anotas acerca un poco más el corpus a la
  ciencia. ¡Ánimo!".

### Comportamiento al iniciar
- Al cargar la app, se leen las preferencias y se inicializan los controles
  (`updateCheckboxInput`, `updateTextAreaInput`, `updateSliderInput`).
- En `server`, una sola vez por sesión: si `isTRUE(prefs$animo_enabled)`,
  `showModal(modalDialog(title = "Bienvenido/a", choose_message(prefs$animo_custom,
  ANIMO_PRESETS), easyClose = TRUE, footer = modalButton("Cerrar")))`.

---

## Integración

- Todos los cambios en `etiquetador_oral.R`, salvo las utilidades puras, que van en dos
  archivos nuevos sourceados al arranque (junto a los ya existentes `R/stats_utils.R`,
  `R/agreement.R`, `R/corpus_stats.R`):
  - `R/plot_export.R`: `plot_filename()`.
  - `R/prefs.R`: `load_prefs()`, `save_prefs()`, `choose_message()`.
- El bucle de `source()` del arranque ya los cargará (usa `if (file.exists(...)) source(...)`).
- Sin dependencias nuevas obligatorias (`DT`, `grDevices` ya están).

## Plan de pruebas
- `testthat` para las utilidades puras:
  - `plot_filename()`: saneado, fecha fija, extensión.
  - `load_prefs()/save_prefs()`: ida y vuelta (round-trip), defaults sin archivo, líneas
    mal formadas ignoradas, tipos correctos.
  - `choose_message()`: devuelve el propio si hay; si no, una de las predefinidas;
    `""` si no hay ninguna.
- Verificación manual: descargar PNG/PDF de los 4 gráficos (abrir y comprobar nitidez),
  exportar una tabla a CSV/Excel, mover el deslizador y ver crecer el texto, activar el
  mensaje de ánimo y reiniciar para ver el modal.

## Fuera de alcance (YAGNI)
- Descarga de los gráficos acústicos y de praatpicture (solo los 4 estadísticos).
- SVG (solo PNG + PDF).
- Selector de idioma / i18n (Spec 2 aparte). Las frases de ánimo se traducirán entonces.
- Exportación de tablas a PDF.

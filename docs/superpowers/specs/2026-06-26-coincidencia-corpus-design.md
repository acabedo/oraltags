# Diseño: pestañas «Coincidencia» y «Corpus»

Fecha: 2026-06-26
App: `etiquetador_oral.R` (Oraltags v2.0, Shiny de un solo archivo)
Autor del diseño: Adrián Cabedo (asistido)

## Contexto

Oraltags es una app Shiny en R, en un solo archivo `etiquetador_oral.R` (~2390 líneas),
para anotación lingüística y análisis acústico de corpus orales. Cada fila es un grupo
entonativo con columnas `speaker/start/end/label/contexto`, métricas acústicas numéricas
(`F0_*`, `Int_*`, `n_palabras`, `palabras_por_seg`, `fonemas_por_seg`, cuartiles) y
anotaciones categóricas configurables `anot1..anot33` (`n_anot = 33`), más `observaciones`.

Los datos se persisten como TSV: un archivo por corpus en `analisis/analisis_<nombre>.txt`
y un consolidado `analisis/analisis_todos.txt` que añade una columna `filename`.

La UI principal es un `tabsetPanel` (línea ~476) con 8 pestañas. Ya existe una pestaña
«Estadísticas» con barras/boxplots que opera sobre el corpus **cargado** (`rv$df_full`).

Helpers reutilizables ya presentes:
- `stat_num_cols`: vector de columnas numéricas analizables.
- `stat_col_label(cn)`: etiqueta legible de una columna numérica.
- `stat_skewness(x)`, `stat_kurtosis(x)`: asimetría y curtosis sin paquetes extra.
- `rv$anot_defs[[cn]]$label`: etiqueta legible de cada `anot*`.
- `%||%`: coalescing de nulos.
- Patrón de dependencia opcional: `HAS_PRAATPICTURE <- requireNamespace("praatpicture", quietly = TRUE)`.

Se añaden DOS pestañas nuevas tras «Estadísticas», sin tocar la lógica existente.

## Decisiones tomadas (brainstorming)

1. **Emparejado de filas (Coincidencia):** por `start`/`end` (redondeados) + `label`.
   Solo se comparan los segmentos presentes en TODOS los archivos seleccionados.
2. **Anotadores (Coincidencia):** de 2 a 10 jueces (archivos). Medidas: % de acuerdo,
   Cohen's Kappa (ponderado para ordinales), Fleiss' Kappa + kappa medio por parejas
   cuando hay >2, Krippendorff's α opcional. Para >2 jueces, las medidas pareadas
   (Cohen, matriz de confusión) usan la media sobre todas las parejas.
3. **Agrupación (Corpus):** «agrupar por hasta 4 variables» genera una tabla de
   descriptivos cruzada; el gráfico usa 1 sola variable de agrupación.

---

## Pestaña 1 — «Coincidencia» (acuerdo entre anotadores)

### Propósito
Subir varios archivos `analisis_*.txt` del mismo corpus anotado por distintas personas
(mismos segmentos, distintas anotaciones) y medir cuánto coinciden.

### UI
- `fileInput("coinc_files", multiple = TRUE)` aceptando `.txt/.tsv/.csv`.
  Soporta de **2 a 10 archivos** (jueces); si se suben más de 10, se avisa y se usan
  los 10 primeros (o se rechaza con mensaje claro).
- Tabla/lista de archivos cargados con su nº de filas leídas.
- `selectInput("coinc_vars", multiple = TRUE)`: variables a comparar; por defecto todas
  las `anot*` con datos en ≥2 archivos. Etiquetas vía `anot_defs`.
- `checkboxGroupInput`/selector de variables **ordinales** (autodetección por defecto:
  niveles que parsean a número, p. ej. intensidad emocional 1–5) → habilita kappa ponderado.
- `actionButton("coinc_run", "Calcular")`.

### Emparejado de filas
- Clave de emparejado: `paste(round(start, 3), round(end, 3), trimws(tolower(label)))`.
- Se toma la **intersección** de claves presentes en todos los archivos seleccionados.
- Se informa: nº de filas emparejadas y nº descartadas por archivo.
- Si la intersección es 0, mensaje claro («los archivos no comparten segmentos; revisa
  que sean el mismo corpus»).

### Cálculo (funciones puras, sin dependencias nuevas)
Cada celda se trata como **categoría exacta** (las multivalor `a; b` cuentan como una
categoría propia). Para cada variable comparada, sobre las filas emparejadas:
- `agreement_percent(mat)`: % de filas donde todos los anotadores coinciden.
- `cohen_kappa(a, b)`: kappa de Cohen para 2 anotadores.
- `cohen_kappa_weighted(a, b, weights = "linear")`: kappa ponderado para ordinales.
- `fleiss_kappa(mat)`: kappa de Fleiss para >2 anotadores.
- `mean_pairwise_kappa(mat)`: media de Cohen sobre todas las parejas (>2 anotadores).
- `krippendorff_alpha(mat)`: vía `irr::kripp.alpha` SOLO si `requireNamespace("irr")`;
  si no está, se omite con nota (no es obligatorio instalarlo).
- `interpret_kappa(k)`: escala Landis & Koch (<0 pobre; 0–.2 leve; .2–.4 aceptable;
  .4–.6 moderado; .6–.8 considerable; .8–1 casi perfecto).

`mat` = matriz filas-emparejadas × anotadores con la categoría de cada uno.

### Resultados (output)
- **Resumen**: nº anotadores, nº filas emparejadas, nº variables comparadas, kappa medio global.
- **Tabla por variable** (`DT`): variable, n, % acuerdo, Cohen κ (2 anotadores; marca «(pond.)»
  si ordinal), Fleiss κ (>2), κ medio por parejas (>2), Krippendorff α (si disponible),
  interpretación.
- **Gráfico de barras** del kappa por variable (base R, color `#3b82f6`), ordenado, con
  líneas de referencia en 0.4/0.6/0.8.
- **Opcional** (desplegable, solo 2 anotadores): matriz de confusión por variable seleccionada.

### Aislamiento / testabilidad
Las funciones de cálculo (`cohen_kappa`, `cohen_kappa_weighted`, `fleiss_kappa`,
`mean_pairwise_kappa`, `agreement_percent`, `interpret_kappa`) son **puras** (entran
vectores/matriz, sale número) y van agrupadas en una sección propia del archivo, de modo
que pueden probarse con `testthat` de forma independiente de Shiny.

---

## Pestaña 2 — «Corpus» (visión global con `analisis_todos`)

### Propósito
Explorar de un vistazo todo el corpus consolidado.

### Fuente de datos
- Lee automáticamente `file.path(ANALISIS_DIR, "analisis_todos.txt")` al abrir/refrescar.
- `actionButton("corpus_refresh", "Refrescar")`.
- `fileInput("corpus_file")` opcional para cargar un consolidado alternativo.
- Reactivo `corpus_df()` que devuelve el data.frame activo (subido > disco).

### UI / contenido
1. **Cabecera-resumen**: nº de archivos (`length(unique(filename))`), nº total de filas,
   nº de variables. Mini-tabla de filas por archivo.
2. **Tabla de descriptivos generales** (`DT`): una fila por variable numérica de
   `stat_num_cols` presente, con columnas n, media, sd, mín, p25, mediana, p75, máx,
   asimetría (`stat_skewness`), curtosis (`stat_kurtosis`).
3. **Gráfico**: `selectInput` variable numérica + `radioButtons` tipo (boxplot /
   barplot de medias) + 1 `selectInput` de agrupación (speaker, filename, `anot*` con
   pocos niveles). Mismo estilo que la pestaña Estadísticas.
4. **Agrupar por hasta 4 variables**: 4 `selectInput` categóricos (opcionales:
   speaker, filename, `anot*`). Con la variable numérica elegida, genera una **tabla
   cruzada de descriptivos** (`DT`): una fila por combinación de grupos presentes, con
   n, media, sd, mín, máx, mediana. Filas ordenadas por los grupos.

### Aislamiento / testabilidad
La agregación de descriptivos se factoriza en un helper puro
`describe_numeric(df, num_col, group_cols = character(0))` que devuelve un data.frame de
descriptivos (con o sin agrupación). Reutilizable por la tabla general (sin grupos) y por
la tabla cruzada (1–4 grupos), y testeable con `testthat`.

---

## Integración

- Dos `tabPanel("Coincidencia", ...)` y `tabPanel("Corpus", ...)` insertados en el
  `tabsetPanel` principal tras «Estadísticas» (~línea 608), antes de «Configuración».
- Lógica de servidor añadida al final del bloque `server` reutilizando helpers existentes.
- Estilo gráfico base R coherente (`#3b82f6` barras, `#93c5fd`/`#1d4ed8` boxplots).
- **Sin dependencias nuevas obligatorias.** `irr` es opcional para Krippendorff α,
  detectado con `requireNamespace` igual que `praatpicture`.
- Backup del código v2.0 ya creado en `backup_codigo/etiquetador_oral_v2.0_20260626.R`.

## Plan de pruebas
- Tests `testthat` para las funciones puras de acuerdo (`cohen_kappa` contra casos
  conocidos: acuerdo perfecto → 1; acuerdo al azar → ~0; un ejemplo de la literatura) y
  para `describe_numeric` (sin grupos y con 1–2 grupos).
- Verificación manual: lanzar la app, subir 2 archivos `analisis_*` de prueba y revisar
  la tabla de kappa; abrir «Corpus» y comprobar conteos y descriptivos contra `analisis_todos.txt`.

## Fuera de alcance (YAGNI)
- Comparar contra el corpus cargado en memoria (modo uno-vs-referencia): descartado.
- Gráficos facetados con las 4 variables de agrupación: descartado (saturación).
- Acuerdo multi-etiqueta tipo Jaccard para celdas multivalor: descartado (categoría exacta).

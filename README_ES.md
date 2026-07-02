# Oraltags. Oral data tagger — v2.2

**🌐 Idioma / Language:** [🇬🇧 English](README.md) · 🇪🇸 **Español**

> *Oraltags — explorador prosódico de datos orales*

Aplicación Shiny en R para la anotación lingüística y el análisis acústico de corpus orales. Permite cargar audio y transcripción, navegar grupo entonativo a grupo entonativo, calcular automáticamente métricas prosódicas, anotar con categorías totalmente configurables y explorar los resultados con tablas, figuras tipo Praat y gráficos estadísticos.

> **⚡ Instalación rápida (recomendada):** en R, ejecuta
> `remotes::install_github("acabedo/oraltags", subdir = "package")`
> y después `oraltags::run_app()`. Las dependencias se instalan solas y se incluyen tres muestras de audio + TextGrid para probarlo al instante. Todos los detalles en [Instalación y uso](#instalación-y-uso).

> **📖 Documentación completa:** la guía de usuario detallada (cada operación de la app, todas las variables anotadas y computadas, archivos de entrada/salida y el código R del paquete) está publicada en **<https://acabedo.github.io/oraltags/>** (generada con pkgdown desde [`package/vignettes/`](package/vignettes/) hacia [`docs/`](docs/)).

![Pantalla inicial del etiquetador](imgs/1_pantalla_inicial.png)

---

## Novedades de la v2.0

- **Editor de variables de anotación**: ahora todas las categorías (etiquetas y valores posibles) son configurables desde la propia interfaz, sin tocar el código.
- **Nueva pestaña *Emociones*** con tono emocional de Ekman e intensidad.
- **Pestaña *Métricas*** con un informe prosódico textual completo de la fila activa.
- **Pestaña *Praatpicture*** para renderizar figuras multipanel al estilo Praat.
- **Pestaña *Estadísticas*** con gráficos de barras y diagramas de caja sobre las anotaciones.
- Panel lateral con **navegación secuencial**, reproducción del segmento y de su contexto previo/posterior ajustable.

---

## Funcionalidades principales

La app se organiza en seis pestañas superiores:

| Pestaña | Función |
|---|---|
| **Anotaciones** | Formulario de etiquetado dividido en cinco bloques temáticos (ver más abajo). |
| **Contexto** | Filas anteriores/posteriores a la selección; permite **editar speaker/label de la fila activa** (se guarda en el análisis) y mostrar una columna **`ejemplo_para_paper`** con cita `(corpus, inicio-fin)`. |
| **Análisis fonético** | Subpestañas **Imágenes** (oscilograma, espectrograma, F0), **Métricas** (informe prosódico) y **Praatpicture** (figura multipanel). |
| **Estadísticas** | Subpestañas **Este archivo** (barras/boxplots del corpus cargado) y **Corpus completo** (visión global de `analisis_todos.txt`). |
| **Coincidencia** | Acuerdo entre 2–10 jueces (archivos de análisis de otros equipos): % de acuerdo, Cohen's Kappa (ponderado para ordinales), Fleiss' Kappa y Krippendorff's α (opcional). |
| **Configuración** | Editor de variables de anotación (personaliza etiquetas y categorías), preferencias de gráficos y **gestión de análisis guardados** (eliminar análisis previos). |

### Carga de material y navegación

- **Carga de material**: audio en WAV, MP3 o MP4 + transcripción en CSV, TXT o TextGrid (Praat). Conversión automática de MP3/MP4 a WAV para el análisis.
- **Navegación secuencial**: botones ⬅ Anterior / Siguiente ➡, salto directo a cualquier fila e indicador de posición (`Fila X de N`).
- **Reproducción**: del segmento aislado o con contexto previo/posterior, ajustando los segundos *Antes (s)* y *Después (s)*.
- **Pares precargados**: coloca audio + transcripción con el mismo nombre base en `www/audios/` y la app los detecta automáticamente.

### Análisis acústico automático por segmento

Las métricas se recalculan automáticamente al cambiar de fila:

- F0 media y mediana (Hz), con `wrassp::ksvF0`
- Desviación típica y rango de F0 (en semitonos / p10–p90)
- Inflexión global y tonema final (último 20 %), con su patrón melódico
- Intensidad media (dB)
- Velocidad de habla (palabras/s y fonemas/s) y pausas anterior/posterior

![Análisis fonético: oscilograma, espectrograma y curva melódica](imgs/4_analisis_fonetico.png)

![Métricas: informe prosódico textual de la fila activa](imgs/5_metricas.png)

![Praatpicture: figura multipanel al estilo Praat](imgs/6_praatpicture.png)

### Anotación

El formulario de **Anotaciones** se divide en cinco bloques. Las categorías que se muestran son las de fábrica, pero pueden modificarse por completo desde **Configuración**:

| Bloque | Ejemplos de categorías |
|---|---|
| **Estructura** | Tipo de enunciado, modalidad oracional, estatus informativo, complejidad sintáctica, reformulación / expansión, función discursiva global, referencia a discurso ajeno, temporalidad del contenido |
| **Pragmática** | Función pragmática, función interpersonal, atenuación, intensificación, cortesía, imagen del otro, autoimagen |
| **Discurso e interacción** | Movimiento conversacional, gestión del turno, relación con el turno previo, dinámica interactiva, marcador discursivo, función fática, deixis, recursos coloquiales |
| **Paralingüístico / no verbal** | Sonidos no verbales, solapamientos no verbales, ruido articulatorio, fenómenos respiratorios, turnos no verbales, ruido ambiental, actitud vocal |
| **Emociones** | Tono emocional de Ekman (Neutra, Alegría, Tristeza, Miedo, Ira, Asco, Sorpresa, Desprecio) e intensidad (1–5) |

![Formulario de anotación (bloque Estructura)](imgs/2_anotacion.png)

### Contexto

La pestaña **Contexto** muestra las filas anteriores/posteriores al segmento activo (resaltado), permite editar el hablante/etiqueta de la fila activa y añadir una columna `ejemplo_para_paper` con cita `(corpus, inicio-fin)`.

![Vista de contexto: filas anteriores y posteriores a la selección actual](imgs/3_contexto.png)

### Estadísticas

![Estadísticas: gráfico de barras de una variable categórica](imgs/7_grafico_barras.png)

![Estadísticas: diagrama de caja de una variable numérica](imgs/8_grafico_boxplot.png)

En **Estadísticas → Corpus completo** ahora puedes **elegir qué archivos** del consolidado (`analisis_todos.txt`) se incluyen: un selector múltiple lista todos los archivos y todas las tablas y gráficos se recalculan con tu selección (por defecto se incluyen todos).

### Coincidencia (acuerdo entre jueces)

Sube 2–10 archivos `analisis_*.txt` de anotadores del mismo corpus (o carga la muestra incluida con 3 jueces): la app empareja los segmentos comunes y calcula % de acuerdo, kappa de Cohen/Fleiss, kappa por pares y alfa de Krippendorff por variable, además de un gráfico de kappa y matrices de confusión por pares.

![Acuerdo entre jueces](imgs/9_acuerdo_jueces.png)

![Kappa de Fleiss por variable y matriz de confusión](imgs/10_acuerdo_kappa.png)

### Configuración (editor de variables y gestión de análisis)

Cada variable de anotación (`anot1`, `anot2`, …) tiene una etiqueta editable y su lista de categorías (una por línea). Así, el mismo etiquetador sirve para esquemas de anotación distintos sin reprogramar nada.

**Configuración** incluye además la **gestión de análisis guardados**: selecciona uno o varios análisis previos (`analisis_*.txt`) y elimínalos — antes de borrar se guarda una copia con marca temporal en `backup/`, sus filas se retiran del consolidado `analisis_todos.txt` y, opcionalmente, se elimina también el audio asociado.

### Persistencia y exportación

- **Guardado automático**: al navegar o anotar, los datos se persisten en un TSV (`analisis_<nombre>.txt`) y en un consolidado (`analisis_todos.txt`).
- **Sistema de backup**: copia de seguridad con marca de tiempo en `backup/` al cargar datos.
- **Exportación**: CSV, TXT y volcado directo a Google Sheets.

### Exportación y personalización (v2.1)

- **Descarga de gráficos** en alta calidad (PNG 300 ppp y PDF vectorial) en los gráficos de *Estadísticas*, *Coincidencia* y *Corpus*.
- **Exportación de tablas** a CSV, Excel y portapapeles (botones integrados en cada tabla; exportan todas las filas).
- **Tamaño de letra de los gráficos** ajustable con un deslizador global en *Configuración*.
- **Mensaje de ánimo** opcional al iniciar (frase al azar o mensaje propio), activable en *Configuración*.
- **Idioma de la interfaz**: selector **Español / English** en la cabecera (cambio en caliente; recuerda la elección). El esquema de anotación permanece en español.

### Novedades de la v2.2

- **Gestión de análisis guardados** (*Configuración*): elimina análisis previos con confirmación, backup automático, limpieza del consolidado y borrado opcional del audio asociado.
- **Selección de archivos en las estadísticas de *Corpus completo***: elige qué archivos de `analisis_todos.txt` entran en las tablas y gráficos.
- **Sitio de documentación** generado con pkgdown en <https://acabedo.github.io/oraltags/> (fuentes en `package/vignettes/`, salida en `docs/`).

---

## Requisitos

- R ≥ 4.1
- Paquetes R — **si instalas con la Opción A de abajo (`install_github`) se instalan solos**, así que puedes saltarte este paso. Solo necesitas instalarlos a mano si ejecutas la app desde el código fuente (Opción B):

```r
install.packages(c(
  "shiny", "DT", "tuneR", "shinyjs", "shinythemes",
  "seewave", "wrassp", "praatpicture", "tools", "av", "rPraat", "shiny.i18n"
))
```

> `rPraat` es necesario solo para leer archivos TextGrid de Praat; `praatpicture` (de [Rasmus Puggaard-Rode](https://github.com/rpuggaardrode/praatpicture)) solo para la pestaña *Praatpicture*.
> `irr` es opcional: habilita Krippendorff's α en la pestaña *Coincidencia*. Sin él, esa columna aparece como N/D.
> `ffmpeg` es opcional (binario externo, no un paquete de R): si está en el `PATH`, al cargar un MP4 el visor del sidebar corta y reproduce el clip exacto de cada grupo entonativo. Sin él la app funciona igual, pero el vídeo del segmento usa el archivo completo (sincronización aproximada). El audio y el resto del análisis no lo necesitan.

---

## Instalación y uso

### Opción A — Instalar como paquete de R (recomendada)

La vía más fácil. Instala directamente desde GitHub; todos los paquetes de R necesarios se instalan solos:

```r
# install.packages("remotes")   # si aún no lo tienes
remotes::install_github("acabedo/oraltags", subdir = "package")

# Lanzar la aplicación
oraltags::run_app()
```

No hace falta clonar el repositorio ni fijar un directorio de trabajo. Tus datos —análisis guardados, copias de seguridad, preferencias y el audio que cargues— se guardan en una carpeta estándar por usuario (`tools::R_user_dir("oraltags", "data")`), de modo que nunca se escribe nada dentro del paquete instalado.

**Pruébalo con las muestras incluidas:** el paquete trae **tres ejemplos de audio + TextGrid**. En el panel lateral de archivos, elige una en **«Cargar muestra de ejemplo»** y pulsa el botón: puedes explorar todas las funciones sin aportar material propio.

> Opcional: instala `ffmpeg` (binario externo, no un paquete de R) para el recorte exacto del vídeo por segmento con MP4. La app funciona igual sin él; ver *Requisitos*.

### Opción B — Ejecutar desde el código fuente (clonar)

Si prefieres trabajar directamente con el script, clona el repositorio y, desde R dentro de la carpeta del repo:

```r
# Instala primero los paquetes de R (ver Requisitos) y luego:
source("etiquetador_oral.R")   # o ábrelo en RStudio y pulsa "Run App"
```

En este modo, las carpetas de trabajo (`config/`, `analisis/`, `backup/`, `www/audios/`) viven dentro del repositorio.

### Organización de archivos (versión de código fuente)

```
oraltags/
├── etiquetador_oral.R       # Código principal de la app (Shiny en un solo archivo)
├── package/                 # Paquete de R instalable (Opción A): oraltags::run_app()
├── R/                       # Funciones auxiliares puras
├── docs/                    # Sitio de documentación (pkgdown; GitHub Pages)
├── imgs/                    # Capturas de ejemplo (este README)
├── samples/                 # Pares de ejemplo audio + TextGrid
├── www/
│   └── audios/              # Pares precargados (mismo nombre base)
├── config/                  # Esquema de etiquetas personalizado y preferencias
├── backup/                  # Backups automáticos (se crea al cargar datos)
└── analisis/                # Análisis por corpus + consolidado analisis_todos.txt
```

### Formato de la transcripción (CSV / TXT)

La transcripción debe incluir al menos estas columnas:

| Columna | Descripción |
|---|---|
| `speaker` | Identificador del hablante |
| `start` | Tiempo de inicio en segundos |
| `end` | Tiempo de fin en segundos |
| `label` | Transcripción del segmento |

---

## Flujo de trabajo

1. Carga el audio y la transcripción (pestaña **Precargados** o **Cargar**).
2. Navega con **⬅ Anterior / Siguiente ➡** o salta directamente a una fila.
3. Escucha el segmento con **▶ Segmento** o con contexto previo/posterior ajustable.
4. Las métricas acústicas se calculan automáticamente al cambiar de fila (pestañas *Análisis fonético* y *Métricas*).
5. Rellena las anotaciones en los bloques de **Anotaciones** y pulsa **Guardar**.
6. Si lo necesitas, ajusta el esquema de etiquetas en **Configuración**.
7. Explora los resultados en **Estadísticas** y exporta como CSV, TXT o Google Sheets.

---

## Agradecimientos

- La pestaña *Praatpicture* funciona gracias al paquete [praatpicture](https://github.com/rpuggaardrode/praatpicture) de **Rasmus Puggaard-Rode**.
- **Asistencia de IA**: la infraestructura del paquete de R y partes del código de la aplicación y de la documentación se desarrollaron con ayuda de IA generativa (Claude, de Anthropic), bajo el diseño, la supervisión y la revisión del autor.

## Cómo citar

> Cabedo-Nebot, A. (2026). *Oraltags: oral data tagger and prosody explorer*. R package version 2.2.0. <https://github.com/acabedo/oraltags>

En R: `citation("oraltags")`. Véase también [`CITATION.cff`](CITATION.cff).

## Licencia

© 2025 Adrián Cabedo Nebot.  
Distribuido bajo licencia **GNU General Public License v3.0 (GPL-3.0)**.  
Se permite el uso, distribución y modificación bajo los términos de la GPL-3.0.  
[Ver texto completo de la licencia](LICENSE)

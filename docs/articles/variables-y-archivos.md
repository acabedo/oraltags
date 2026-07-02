# Variables y archivos (entradas y salidas)

> 🇬🇧 *This page is also available in English: [Variables and
> files](https://acabedo.github.io/oraltags/articles/variables-and-files.md).*

Esta página documenta el **modelo de datos** de oraltags: qué archivos
necesita la aplicación, qué archivos crea, y todas las variables — de
anotación manual y computadas automáticamente — que se guardan en cada
análisis.

## Archivos de entrada

| Archivo | Formato | Obligatorio | Notas |
|----|----|----|----|
| Audio | `.wav`, `.mp3` | Sí | El MP3 se convierte a WAV internamente (paquete `av`) |
| Vídeo | `.mp4` | No | Activa el visor de vídeo; con `ffmpeg` se corta el clip exacto del segmento |
| Transcripción | `.TextGrid` (Praat) | Sí (primera vez) | Si contiene los tiers `phones` y `words` (Montreal Forced Aligner), la app genera los grupos entonativos automáticamente con un umbral de pausa mínima configurable |
| Transcripción | `.csv` / `.txt` | Alternativa | Debe incluir al menos las columnas `speaker`, `start`, `end`, `label` (tiempos en segundos) |

El audio y la transcripción se emparejan por **nombre base**
(`entrevista.wav` ↔︎ `entrevista.TextGrid`).

## Archivos de salida

Todos se crean bajo la carpeta de datos del usuario
([`oraltags::oraltags_data_dir()`](https://acabedo.github.io/oraltags/reference/oraltags_data_dir.md)
en la versión de paquete; las carpetas del repositorio si ejecutas el
script fuente):

| Archivo | Cuándo se crea | Contenido |
|----|----|----|
| `analisis/analisis_<nombre>.txt` | Al generar los GE o guardar la primera anotación | TSV con una fila por grupo entonativo y todas las variables (véase abajo) |
| `analisis/analisis_todos.txt` | Se actualiza en cada guardado | Consolidado de todos los corpus; añade la columna `filename` con el archivo de origen. Es la base de *Estadísticas → Corpus completo* |
| `backup/<nombre>_backup_<fecha>.txt` | Al recargar datos y **antes de eliminar un análisis** | Copia de seguridad con marca temporal |
| `config/etiquetas_variables.txt` | Al guardar cambios en el editor de variables | Esquema personalizado (etiquetas y categorías de `anot1`–`anot33`) |
| `config/preferencias.txt` | Al guardar preferencias | Idioma, tamaño de letra de gráficos, mensaje de ánimo |
| `audios/<nombre>.wav` | Al subir un audio (versión de paquete) | Copia del audio para reutilizarlo en sesiones futuras |

Los archivos de análisis son **TSV planos (UTF-8)**: puedes abrirlos en
R, Excel o cualquier editor. La app también exporta directamente a
**CSV** (botón de la barra lateral), y cada tabla tiene botones **Copy /
CSV / Excel**; los gráficos se descargan en **PNG (300 dpi)** y **PDF**.

## Estructura del archivo de análisis

Cada fila de `analisis_<nombre>.txt` es un **grupo entonativo (GE)** con
estas columnas:

### Identificación y texto

| Columna | Descripción |
|----|----|
| `speaker` | Identificador del hablante (del TextGrid o CSV) |
| `start`, `end` | Tiempos de inicio y fin en segundos |
| `label` | Transcripción del segmento |
| `contexto` | Contexto discursivo (`hablante: texto | …`) generado automáticamente |
| `observaciones` | Notas libres del anotador |
| `filename` | Solo en el consolidado: archivo de origen |

### Métricas acústicas y de velocidad (computadas)

Se calculan automáticamente al navegar (o en bloque con **«Calcular
F0/Int de todos los segmentos»**). El F0 se estima con
[`wrassp::ksvF0`](https://rdrr.io/pkg/wrassp/man/ksvF0.html) y la
intensidad con `wrassp`/`seewave`:

| Columna | Descripción |
|----|----|
| `n_palabras` | Número de palabras del segmento |
| `palabras_por_seg` | Velocidad de habla en palabras/segundo |
| `fonemas_por_seg` | Velocidad de habla en fonemas/segundo |
| `F0_mean`, `F0_median`, `F0_sd` | Media, mediana y desviación típica del F0 (Hz) |
| `F0_range_st` | Rango tonal p10–p90 en **semitonos** |
| `F0_delta_st` | Inflexión global del segmento (semitonos) |
| `F0_final_delta_st` | Movimiento del **tonema** (último tramo, por defecto 20 %) en semitonos |
| `F0_final_pattern` | Patrón melódico del tonema (secuencia de subidas/bajadas/llanos, p. ej. `PPP`) |
| `Int_mean`, `Int_median`, `Int_sd` | Media, mediana y desviación típica de la intensidad (dB) |
| `F0_ini_q1`–`F0_ini_q4` | F0 medio en los 4 cuartos de la **ventana inicial** del segmento |
| `F0_fin_q1`–`F0_fin_q4` | F0 medio en los 4 cuartos de la **ventana final** |
| `Int_ini_q1`–`Int_ini_q4`, `Int_fin_q1`–`Int_fin_q4` | Lo mismo para la intensidad |

El tamaño de las ventanas inicial/final se controla con **Configuración
→ Porcentaje cuartiles (%)** (por defecto 20 % del segmento).

Además, el informe de la subpestaña **Métricas** muestra las **pausas**
anterior y posterior (calculadas a partir de los tiempos de los GE
adyacentes).

### Variables de anotación (`anot1`–`anot33`)

Son las variables manuales del formulario **Anotaciones**. Las etiquetas
y categorías siguientes son las **por defecto**; todas pueden
modificarse en *Configuración → Editar variables* (el archivo TSV
siempre guarda el texto de la categoría, no un código):

**Bloque Estructura**

| Columna | Variable                       |
|---------|--------------------------------|
| `anot1` | Tipo de enunciado (estructura) |
| `anot2` | Modalidad oracional            |
| `anot3` | Estatus informativo            |
| `anot4` | Complejidad sintáctica         |
| `anot5` | Reformulación / expansión      |
| `anot6` | Función discursiva global      |
| `anot7` | Referencia a discurso ajeno    |
| `anot8` | Temporalidad del contenido     |

**Bloque Pragmática**

| Columna  | Variable                            |
|----------|-------------------------------------|
| `anot9`  | Función pragmática básica           |
| `anot10` | Función interpersonal               |
| `anot11` | Atenuación: presencia y tipo global |
| `anot12` | Atenuación: orientación principal   |
| `anot13` | Atenuación: procedimiento dominante |
| `anot14` | Intensificación                     |
| `anot15` | Estrategia de cortesía              |
| `anot16` | Imagen del otro                     |
| `anot17` | Autoimagen                          |

**Bloque Discurso e interacción**

| Columna  | Variable                                  |
|----------|-------------------------------------------|
| `anot18` | Movimiento conversacional                 |
| `anot19` | Gestión del turno                         |
| `anot20` | Relación con el turno previo              |
| `anot21` | Dinámica interactiva (solapamiento/ritmo) |
| `anot22` | Marcador discursivo principal             |
| `anot23` | Función fática / de contacto              |
| `anot24` | Deixis dominante                          |
| `anot25` | Recursos coloquiales y muletillas         |

**Bloque Paralingüístico / no verbal**

| Columna  | Variable                               |
|----------|----------------------------------------|
| `anot26` | Paralenguaje (sonidos no verbales)     |
| `anot28` | Solapamientos no verbales              |
| `anot29` | Ruido articulatorio / gestual audible  |
| `anot30` | Fenómenos respiratorios                |
| `anot31` | Sonidos no verbales como toma de turno |
| `anot32` | Ruido ambiental con impacto discursivo |
| `anot33` | Actitud vocal no verbal                |

**Bloque Emociones**

| Columna | Variable |
|----|----|
| `anot27` | Tono emocional (Ekman) + intensidad, guardado como `Emoción - N` (p. ej. `Alegría - 4`) |

> **Nota sobre el idioma:** aunque la interfaz puede mostrarse en
> inglés, las categorías se guardan siempre con su **texto canónico en
> español**, para que los análisis de distintos anotadores (y de
> distintos idiomas de interfaz) sean directamente comparables.

## Variables derivadas en Estadísticas y Coincidencia

- **Estadísticas** trata como numéricas la duración, las velocidades y
  todas las métricas de F0/intensidad, y como categóricas el hablante,
  el archivo (`filename`, en el corpus completo) y cualquier `anot*` con
  entre 2 y 30 niveles observados.
- **Coincidencia** empareja los segmentos de 2–10 jueces por
  `start`/`end`/`label` y calcula por variable: **% de acuerdo**,
  **kappa de Cohen** (ponderado si la variable se marca como ordinal),
  **kappa de Fleiss**, **kappa medio por pares** y **alfa de
  Krippendorff** (requiere `irr`), con la interpretación de Landis y
  Koch.

# Primeros pasos con oraltags

**oraltags** es una aplicación R/Shiny para la anotación lingüística y
el análisis acústico de corpus orales. Esta página cubre la instalación
y la primera sesión; la [guía completa de la
aplicación](https://acabedo.github.io/oraltags/articles/guia-aplicacion.md)
describe cada operación en detalle.

## Instalación

Instala el paquete directamente desde GitHub; las dependencias de R se
instalan automáticamente:

``` r

# install.packages("remotes")   # si aún no lo tienes
remotes::install_github("acabedo/oraltags", subdir = "package")
```

Dependencias opcionales:

- **`praatpicture`**: habilita la subpestaña *Praatpicture* (figuras
  multipanel al estilo Praat).
- **`irr`**: habilita el alfa de Krippendorff en la pestaña
  *Coincidencia*. Sin él, esa columna aparece como N/A.
- **`ffmpeg`** (binario externo, no un paquete de R): si está en el
  `PATH`, al cargar un MP4 el visor lateral corta y reproduce el clip
  exacto de cada grupo entonativo. Sin él la app funciona igualmente.

## Lanzar la aplicación

``` r

oraltags::run_app()
```

[`run_app()`](https://acabedo.github.io/oraltags/reference/run_app.md)
acepta los argumentos habituales de
[`shiny::runApp()`](https://rdrr.io/pkg/shiny/man/runApp.html) (`port`,
`host`, `launch.browser`…).

La interfaz está disponible en **español e inglés**: el selector de
idioma está en la cabecera, a la derecha. El cambio es inmediato y la
elección se recuerda entre sesiones. El esquema de anotación (los
valores que se guardan en el archivo de análisis) se mantiene siempre en
español para que los corpus sean comparables entre equipos.

## Probar con las muestras incluidas

El paquete incluye **tres pares de audio + TextGrid** (`muestra_1`,
`muestra_2`, `muestra_3`). En la barra lateral, sección **«Probar con
una muestra»**, elige una y pulsa **«Cargar muestra de ejemplo»**: la
app genera los grupos entonativos y puedes explorar todas las pestañas
sin material propio.

![Pantalla
inicial](https://raw.githubusercontent.com/acabedo/oraltags/main/imgs/1_pantalla_inicial.png)

Pantalla inicial

Para la pestaña **Coincidencia** (acuerdo entre jueces) también se
incluyen tres análisis simulados de tres jueces sobre `muestra_1` (botón
**«Cargar análisis de muestra (jueces)»**).

## Dónde se guardan tus datos

La app nunca escribe dentro del paquete instalado. Todos los datos del
usuario (análisis, copias de seguridad, preferencias y audios subidos)
se guardan en una carpeta estándar por usuario:

``` r

oraltags::oraltags_data_dir()
#> p. ej. "~/Library/Application Support/org.R-project.R/R/oraltags"  (macOS)
#>        "~/.local/share/R/oraltags"                                 (Linux)
#>        "C:\\Users\\<usuario>\\AppData\\Roaming\\R\\data\\R\\oraltags" (Windows)
```

Dentro de esa carpeta encontrarás:

| Subcarpeta | Contenido |
|----|----|
| `analisis/` | Un TSV por corpus (`analisis_<nombre>.txt`) y el consolidado `analisis_todos.txt` |
| `backup/` | Copias de seguridad con marca temporal (también antes de eliminar un análisis) |
| `config/` | Esquema de variables personalizado (`etiquetas_variables.txt`) y preferencias (`preferencias.txt`) |
| `audios/` | Audios subidos, para reutilizarlos en sesiones futuras |

Consulta [Variables y
archivos](https://acabedo.github.io/oraltags/articles/variables-y-archivos.md)
para el detalle de cada formato.

## Flujo de trabajo típico

1.  Carga el audio y la transcripción (o una muestra incluida).
2.  Navega con **⬅ Anterior / Siguiente ➡** o salta a una fila concreta.
3.  Escucha el segmento aislado (**▶ Segmento**) o con contexto
    ajustable.
4.  Las métricas acústicas se calculan solas al cambiar de fila.
5.  Rellena las anotaciones y pulsa **Guardar** (hay autoguardado al
    navegar).
6.  Ajusta el esquema de etiquetas en **Configuración**, si lo
    necesitas.
7.  Explora resultados en **Estadísticas** y expórtalos (CSV, Excel,
    PNG, PDF).
8.  Para estudios de fiabilidad, reúne los `analisis_*.txt` de varios
    jueces y calcula el acuerdo en **Coincidencia**.

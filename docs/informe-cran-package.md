# Informe de viabilidad: convertir Oraltags en un paquete de R en CRAN

Fecha: 2026-06-27

## Veredicto

**Técnicamente viable, pero NO es "compilar y subir".** Empaquetar una app Shiny es un
patrón conocido (lanzador `run_app()` + recursos en `inst/`, o el framework `golem`), y casi
todas las dependencias ya están en CRAN. Pero CRAN tiene políticas estrictas que el proyecto
**hoy incumple en varios puntos**; el mayor es que la app **escribe en disco** fuera de
`tempdir()`. Para una app de investigación, **GitHub / r-universe** suele dar el 90 % del
beneficio (instalación con una línea) con una fracción del trabajo de CRAN.

## A favor (lo que ya facilita el camino)

- **Empaquetar Shiny es estándar**: mover UI/servidor a funciones (`app_ui()`, `app_server()`,
  `run_app()`), poner CSS/`translation.json`/logo en `inst/app/www`, exponer `run_app()`.
- **Dependencias en CRAN** (no hay paquetes solo-GitHub): `shiny`, `DT`, `shinyjs`,
  `shinythemes`, `seewave`, `tuneR`, `wrassp`, `rPraat`, `praatpicture`, `av`, `shiny.i18n`,
  `jsonlite`, `irr` (opcional). ✓
- **Base de pruebas ya existente**: hay tests `testthat` y helpers puros en `R/` — buen punto
  de partida para `R CMD check`.
- **Licencia GPL-3** (archivo `LICENSE`) es **aceptada por CRAN**. ✓

## Bloqueos reales (lo que CRAN exige y hoy NO se cumple)

1. **Escritura en disco (el mayor trabajo).** CRAN prohíbe escribir fuera de `tempdir()` sin
   consentimiento explícito del usuario, y **nunca** en la carpeta del paquete instalado. La app
   hace `setwd(APP_DIR)` y escribe `config/`, `backup/`, `analisis/`, `www/audios/` en la carpeta
   de la app. Hay que **reescribir toda la persistencia** a rutas permitidas:
   `tools::R_user_dir("oraltags", "data")`, `tempdir()`, o una carpeta que elija el usuario.
2. **`setwd()`** está prohibido/desaconsejado en código de paquete (cambia estado global). Eliminar.
3. **Tamaño del tarball.** CRAN limita a ~5 MB. `www/` pesa **230 MB** (audios y MP4 de prueba),
   `imgs/` 4,2 MB, `analisis/` 1,5 MB. Todos los **medios deben quedar fuera del paquete**
   (son datos del usuario): solo entra el código + recursos mínimos (CSS, `translation.json`, logo).
   Usar `.Rbuildignore` para excluir `www/audios`, `imgs`, `analisis`, `jueces`, `backup_codigo`,
   `docs/superpowers`, `.superpowers`.
4. **Dependencia externa `ffmpeg`.** Declararla en `SystemRequirements`. El código ya degrada si
   no está (bien). Importante: **ejemplos y tests no pueden depender de ffmpeg ni de audios**.
5. **Estado global al cargar.** `options(shiny.maxRequestSize=...)` y `addResourcePath(...)` deben
   ir dentro de `run_app()`/`.onLoad`, no a nivel de script.
6. **Documentación formal.** `man/*.Rd` (con roxygen2) para cada función exportada, con `\examples`
   que corran rápido (<5 s) sin red, sin escribir fuera de `tempdir` y sin audio/ffmpeg (la app
   interactiva se documenta con `if (interactive())` o `\dontrun{}`). `DESCRIPTION` completo
   (`Title` en estilo título, `Description` en prosa, `Authors@R`, `License`), `NAMESPACE`.
   Vignette recomendable.
7. **`R CMD check --as-cran` limpio**: 0 ERROR / 0 WARNING y NOTEs mínimos; sin `print/cat`
   espurios, sin abrir conexiones a internet durante el check.
8. **Incoherencia de licencia a resolver.** El archivo `LICENSE` es **GPL-3**, pero el pie del
   README/cabecera dice **CC BY 4.0**. CC BY **no es válida para código** en CRAN. Hay que unificar
   a una licencia aceptada (GPL-3 sirve) y corregir el pie de página.

## Esfuerzo orientativo

| Tarea | Coste |
|---|---|
| Estructura de paquete (`usethis`/`golem`): DESCRIPTION, NAMESPACE, R/, inst/app | Bajo-medio |
| Mover UI/servidor a funciones + recursos a `inst/app/www` | Medio |
| **Reescribir la persistencia** (R_user_dir/tempdir/elección) y quitar `setwd` | **Alto** |
| Sacar medios del paquete (`.Rbuildignore`) | Bajo |
| roxygen2 + ejemplos `\dontrun`/`interactive()` + DESCRIPTION/SystemRequirements | Medio |
| Unificar licencia | Bajo |
| Dejar `R CMD check --as-cran` sin WARNINGs | Medio (iterativo) |
| Mantenimiento continuo ante cambios de política/deps de CRAN | Recurrente |

## Alternativas más fáciles que CRAN

- **GitHub + `remotes::install_github("acabedo/oraltags")`**: sin políticas de CRAN; permite
  escribir en disco, incluir medios, etc. Instalación con una línea. **La opción más simple y
  habitual para apps Shiny de investigación.** (Recomendada para distribuir.)
- **r-universe** (`acabedo.r-universe.dev`): publica desde GitHub con binarios e `install.packages`,
  sin el rigor de revisión de CRAN.
- **shinyapps.io / Shiny Server / Docker**: si el objetivo es que la gente la **use** sin instalar R.

## Conclusión

Viable, sí, pero con trabajo real: el bloqueo principal es la **persistencia en disco** (hay que
moverla a directorios permitidos y eliminar `setwd`), más **sacar los 230 MB de medios**, la
**documentación formal** y unificar la **licencia**. Si el objetivo es que la gente la instale
fácilmente, **`install_github` o r-universe** dan casi todo el valor con mucho menos esfuerzo.
CRAN solo compensa si necesitas su sello de revisión y sus binarios, y aceptas la reescritura y
el mantenimiento continuo.

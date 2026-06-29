# Nota de traspaso (para continuar en otro ordenador)

Fecha: 2026-06-29

## Cómo retomar
1. En el otro ordenador: `git clone https://github.com/acabedo/oraltags.git` (o `git pull` si ya lo tienes).
2. Abre Claude Code en la carpeta del repo.
3. Dile: «Continúa según `docs/HANDOFF.md`», y elige el alcance del paquete (ver abajo).

> El trabajo de la última sesión ya está en GitHub (`main` == `origin/main`). Los archivos
> locales de prueba **no** están en GitHub y **no** hacen falta para continuar: `analisis/*.txt`,
> `www/audios/*.mp4` y `*.wav`, `paper/paper_preview.*`.

## TAREA PRINCIPAL pendiente: convertir la app en un paquete `install_github`

Crear una carpeta nueva `package/` con un paquete R llamado **oraltags** (estilo `install_github`,
**no** CRAN). Diseño acordado (Opción A — "paquete envoltorio", mínima alteración):

```
package/
├── DESCRIPTION          # dependencias en Imports → install_github las instala solas
├── NAMESPACE            # export(run_app)
├── R/
│   └── run_app.R        # run_app(): options(shiny.maxRequestSize), addResourcePath, lanza inst/app
└── inst/
    └── app/
        ├── app.R        # copia adaptada de etiquetador_oral.R
        ├── helpers/     # los R/*.R actuales (stats_utils, agreement, corpus_stats, …)
        ├── www/         # CSS, logo, translation.json (SIN los 230 MB de audios)
        └── i18n/
```

- **Dejar `etiquetador_oral.R` de la raíz INTACTO**: `package/` es una copia adaptada e instalable.
- **Único cambio de código real** = la **persistencia**: añadir `oraltags_data_dir()`
  (= `tools::R_user_dir("oraltags","data")`, se crea al primer arranque) y **redirigir ahí** los
  ~12 puntos que hoy escriben `config/`, `analisis_*.txt`, `backup/` y los audios precargados;
  **quitar `setwd()`**; mover 3-4 líneas de arranque global dentro de `run_app()`. Assets vía `system.file()`.
- Dependencias para el DESCRIPTION (Imports): shiny, DT, tuneR, shinyjs, shinythemes, seewave,
  wrassp, praatpicture, av, rPraat, shiny.i18n, jsonlite (irr en Suggests). `SystemRequirements: ffmpeg` (opcional).

### Decisión de alcance pendiente (el usuario elegirá al retomar)
- **(A) Esqueleto que instala y lanza** ahora: estructura + `run_app()` + DESCRIPTION + copia de la app
  y helpers, con la persistencia principal (analisis_*, config, backup) ya redirigida a la carpeta de
  datos. Instalable y lanzable; afinar casos límite después.
- **(B) Paquete completo (sesión dedicada)**: spec + plan de implementación y ejecución completa
  (reescritura total de persistencia + verificación end-to-end). Recomendado para que sea sólido.
- **(C) Solo el spec/diseño** ahora.

Recomendación: empezar por (A) si hay presupuesto; si no, (B) con writing-plans.

## OTROS pendientes (menores)
- **Eliminar a Claude como contributor** (sin resolver): un `git pull`/merge reintrodujo los 29 trailers
  `Co-Authored-By: Claude` y duplicó commits (historia enredada). Hacerlo **al final**, cuando no vaya a
  haber más pulls: re-strip con `git filter-branch` o `git rebase`, y **force-push inmediato**
  (`git push --force-with-lease origin main`) ANTES de cualquier pull. Hay backups locales
  `backup-con-trailers` / `-2` (solo en este ordenador).
- **paper/paper.bib**: añadir referencias propias / PRESEEA si se quieren citar.
- **CITATION.cff / CONTRIBUTING.md**: las URLs `github.com/acabedo/oraltags` — confirmar el repo real.
- **paper/paper.qmd** para el PDF oficial vía Quarto (opcional; ya hay GitHub Action `draft-pdf.yaml`).

## Qué hacer ANTES de apagar este ordenador
Sube esta nota a GitHub (es un fast-forward, push normal):

```
git push origin main
```

(El resto del trabajo ya está en `origin/main`.)

# Informe de viabilidad: enviar Oraltags a JOSS (Journal of Open Source Software)

Fecha: 2026-06-27

## Veredicto

**Muy viable, y bastante más asequible que CRAN.** JOSS está pensado justo para software de
investigación de código abierto como este. Cumples ya lo esencial; el grueso del trabajo pendiente
es **escribir el paper corto (`paper.md`)** y añadir piezas de comunidad/CI — **no** reescribir
código. JOSS **no** exige empaquetar para CRAN, ni cambiar la persistencia en disco, ni sacar los
medios: nada de lo del informe de CRAN es necesario para JOSS.

## Cómo funciona JOSS (resumen)

JOSS publica un **paper muy corto** (`paper.md`, ~250–1000 palabras) y revisa **el software** en su
repositorio público mediante una **checklist** (un editor + ~2 revisores). No es un artículo
académico tradicional: lo que se evalúa es que el software sea abierto, usable, documentado, probado
y de utilidad para la investigación.

## Lo que YA cumples

- **Código abierto en repo público** (GitHub). ✓
- **Licencia OSI**: GPL-3 (archivo `LICENSE`). ✓ *(corregir la incoherencia con el "CC BY 4.0" del footer).*
- **Esfuerzo sustancial**: ~2900 líneas de R, múltiples subsistemas (anotación, análisis acústico,
  estadística, acuerdo entre jueces, i18n). Supera con holgura el umbral de JOSS. ✓
- **Aplicación de investigación clara**: anotación lingüística y análisis prosódico/acústico de
  corpus orales. ✓
- **Suite de pruebas** (`testthat`, 9 archivos). ✓
- **README** con instalación y uso. ✓

## Lo que FALTA (gaps concretos para superar la revisión)

1. **`paper.md` + `paper.bib`** (el corazón del envío):
   - Título; autores con afiliación y **ORCID**.
   - **Summary**: qué hace y para quién.
   - **Statement of need**: por qué hace falta, situándolo frente a herramientas existentes
     (Praat, ELAN, EXMARaLDA, herramientas de prosodia) y qué aporta (anotación configurable +
     métricas prosódicas automáticas + acuerdo entre jueces + exportación, todo en una app Shiny).
   - Referencias bibliográficas en `paper.bib`.
2. **Archivos de comunidad** (JOSS los exige):
   - `CONTRIBUTING.md` (cómo contribuir).
   - Guía clara para **reportar problemas** y **pedir soporte** (uso de Issues).
   - Recomendables: `CODE_OF_CONDUCT.md`, `CITATION.cff`.
3. **Integración continua (CI)** — en la práctica casi obligatoria:
   - GitHub Actions que instale dependencias y corra `testthat` (demuestra que los tests pasan).
   - Documentar en el README **cómo correr los tests**.
4. **Instalabilidad para revisores**: un revisor debe poder **instalar y ejecutar** la app sin
   fricción. Hoy es "clonar + `install.packages(...)` + `runApp`". Conviene:
   - Instrucciones de instalación reproducibles y una "prueba rápida" con los **datos de ejemplo**
     (ya existen en `www/audios` y `analisis/`).
   - Dejar explícito que `ffmpeg` es **opcional** (ya documentado).
   - (No hace falta que sea un paquete de CRAN; sí que se pueda usar siguiendo el README.)
5. **Unificar la licencia**: usar GPL-3 (OSI) de forma coherente en `LICENSE`, README y cabecera del
   código (quitar el "CC BY 4.0").
6. **Archivo con DOI**: al ser aceptado, se archiva un *release* en **Zenodo** y se obtiene un DOI.
   `CITATION.cff` ayuda.

## Pasos recomendados (orden)

1. Unificar licencia a GPL-3 y corregir el footer.
2. Redactar `paper.md` + `paper.bib` (Summary + Statement of need + comparación con Praat/ELAN).
3. Añadir `CONTRIBUTING.md`, sección de Issues/soporte y (opcional) `CODE_OF_CONDUCT.md` + `CITATION.cff`.
4. Añadir CI (GitHub Actions: instalar deps + correr `testthat`) y documentar cómo correr los tests.
5. Pulir el README: instalación reproducible, datos de ejemplo, nota de `ffmpeg`.
6. Crear un *release* en GitHub; al enviar, archivar en Zenodo (DOI).
7. Enviar en https://joss.theoj.org (URL del repo + `paper.md`).

## JOSS vs CRAN (relación con el informe anterior)

| | CRAN | JOSS |
|---|---|---|
| Reescribir persistencia (no escribir en disco) | **Obligatorio** | No |
| Sacar los 230 MB de medios | **Obligatorio** | No (ayuda, pero no bloquea) |
| Empaquetar (DESCRIPTION/NAMESPACE/man) | **Obligatorio** | No (basta repo usable) |
| `paper.md` + comunidad + CI | No | **Sí** |
| Resultado | Paquete instalable con `install.packages` | Publicación citable (DOI) del software |

Para **publicar y citar** el software, JOSS es el camino corto y adecuado. CRAN es un proyecto
aparte y mucho más costoso; no es prerrequisito de JOSS.

## Conclusión

Encaja muy bien en JOSS. El trabajo pendiente es sobre todo **redactar el `paper.md` y las piezas de
comunidad/CI**, más unificar la licencia — todo ello sin tocar la lógica de la app. Es perfectamente
abordable.

# Oraltags <img src="man/figures/logo.svg" align="right" height="120" alt="Oraltags logo" />

**Oral data tagger & prosody explorer · Etiquetador de datos orales y explorador prosódico**

## 🇬🇧 English

An R/Shiny application for the linguistic annotation and acoustic analysis
of oral corpora. Load an audio file and its transcription (Praat TextGrid,
CSV or TXT), navigate intonation group by intonation group, compute
prosodic metrics automatically (F0, intensity, speech rate, pauses),
annotate with a fully configurable category scheme, explore the results
with tables and charts, and measure **inter-annotator agreement**
(Cohen's/Fleiss' kappa, Krippendorff's α).

- [Getting started](articles/oraltags.html)
- [Complete guide to the application](articles/app-guide.html)
- [Variables and files (inputs and outputs)](articles/variables-and-files.html)
- [Using oraltags from R (code)](articles/using-r.html)

## 🇪🇸 Español

Aplicación R/Shiny para la anotación lingüística y el análisis acústico de
corpus orales. Carga un audio y su transcripción (TextGrid de Praat, CSV o
TXT), navega grupo entonativo a grupo entonativo, calcula automáticamente
métricas prosódicas (F0, intensidad, velocidad de habla, pausas), anota con
un esquema de categorías totalmente configurable, explora los resultados
con tablas y gráficos, y mide el **acuerdo entre jueces** (kappa de
Cohen/Fleiss, alfa de Krippendorff).

- [Primeros pasos](articles/primeros-pasos.html)
- [Guía completa de la aplicación](articles/guia-aplicacion.html)
- [Variables y archivos (entradas y salidas)](articles/variables-y-archivos.html)
- [Uso desde R (código)](articles/uso-con-r.html)

![Oraltags](https://raw.githubusercontent.com/acabedo/oraltags/main/imgs/1_pantalla_inicial.png)

## Installation / Instalación

```r
# install.packages("remotes")
remotes::install_github("acabedo/oraltags", subdir = "package")

oraltags::run_app()
```

The package bundles **three audio + TextGrid samples** and three
sample judge analyses — try every feature without your own material. /
El paquete incluye **tres muestras de audio + TextGrid** y tres análisis de
jueces de ejemplo: prueba todas las funciones sin material propio.

## How to cite / Cómo citar

> Cabedo-Nebot, A. (2026). *Oraltags: oral data tagger and prosody
> explorer*. R package version 2.2.0.
> <https://github.com/acabedo/oraltags>

In R: `citation("oraltags")`.

## Acknowledgements / Agradecimientos

The *Praatpicture* tab is powered by the
[praatpicture](https://github.com/rpuggaardrode/praatpicture) package by
**Rasmus Puggaard-Rode**. / La pestaña *Praatpicture* funciona gracias al
paquete [praatpicture](https://github.com/rpuggaardrode/praatpicture) de
**Rasmus Puggaard-Rode**.

**AI assistance:** the R package infrastructure and parts of the
application code and documentation were developed with the assistance of
generative AI (Anthropic's Claude), under the design, supervision and
review of the author. / **Asistencia de IA:** la infraestructura del
paquete de R y partes del código de la aplicación y de la documentación se
desarrollaron con ayuda de IA generativa (Claude, de Anthropic), bajo el
diseño, la supervisión y la revisión del autor.

## License / Licencia

© 2025–2026 Adrián Cabedo Nebot. GPL-3.

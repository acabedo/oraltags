# oraltags <img src="https://raw.githubusercontent.com/acabedo/oraltags/main/www/logo.svg" align="right" height="90" alt="" />

**Etiquetador de corpus oral y explorador prosódico** — una aplicación
R/Shiny para la anotación lingüística y el análisis acústico de corpus
orales.

Con oraltags puedes cargar un audio y su transcripción (TextGrid de Praat,
CSV o TXT), navegar grupo entonativo a grupo entonativo, calcular
automáticamente métricas prosódicas (F0, intensidad, velocidad de habla,
pausas), anotar con un esquema de categorías totalmente configurable,
explorar los resultados con tablas y gráficos, y medir el **acuerdo entre
jueces** (kappa de Cohen/Fleiss, alfa de Krippendorff).

![Pantalla inicial de Oraltags](https://raw.githubusercontent.com/acabedo/oraltags/main/imgs/1_pantalla_inicial.png)

## Instalación

```r
# install.packages("remotes")
remotes::install_github("acabedo/oraltags", subdir = "package")

# Lanzar la aplicación
oraltags::run_app()
```

El paquete incluye **tres muestras de audio + TextGrid** y tres análisis de
jueces de ejemplo: puedes probar todas las funciones sin material propio.

## Documentación

- [Primeros pasos](articles/oraltags.html): instalación, primera sesión y
  dónde se guardan tus datos.
- [Guía completa de la aplicación](articles/guia-aplicacion.html): todas las
  operaciones, pestaña a pestaña.
- [Variables y archivos](articles/variables-y-archivos.html): qué variables
  se anotan y se computan, qué archivos necesita la app y cuáles crea.
- [Uso desde R](articles/uso-con-r.html): funciones del paquete y cómo
  trabajar con los análisis desde código.

## Licencia

© 2025–2026 Adrián Cabedo Nebot. GPL-3.

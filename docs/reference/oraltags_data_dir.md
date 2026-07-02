# Carpeta de datos del usuario para oraltags

Devuelve (y crea, si no existe) la carpeta estándar donde oraltags
persiste la configuración, los análisis guardados, las copias de
seguridad y los audios cargados. Usa
[`tools::R_user_dir()`](https://rdrr.io/r/tools/userdir.html) para
respetar las convenciones del sistema operativo.

## Usage

``` r
oraltags_data_dir()
```

## Value

Ruta (cadena) a la carpeta de datos del usuario.

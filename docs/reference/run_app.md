# Lanzar la aplicación oraltags

Inicia la aplicación Shiny de etiquetado de corpus oral. Los datos del
usuario se guardan en
[`oraltags_data_dir()`](https://acabedo.github.io/oraltags/reference/oraltags_data_dir.md).

## Uso

``` r
run_app(...)
```

## Argumentos

- ...:

  Argumentos adicionales pasados a
  [`shiny::runApp()`](https://rdrr.io/pkg/shiny/man/runApp.html) (por
  ejemplo `launch.browser`, `port`, `host`).

## Valor

Invisible. Se llama por su efecto: lanza la app.

## Ejemplos

``` r
if (FALSE) { # \dontrun{
oraltags::run_app()
} # }
```

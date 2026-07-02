# Lanzar la aplicación oraltags

Inicia la aplicación Shiny de etiquetado de corpus oral. Los datos del
usuario se guardan en
[`oraltags_data_dir()`](https://acabedo.github.io/oraltags/reference/oraltags_data_dir.md).

## Usage

``` r
run_app(...)
```

## Arguments

- ...:

  Argumentos adicionales pasados a
  [`shiny::runApp()`](https://rdrr.io/pkg/shiny/man/runApp.html) (por
  ejemplo `launch.browser`, `port`, `host`).

## Value

Invisible. Se llama por su efecto: lanza la app.

## Examples

``` r
if (FALSE) { # \dontrun{
oraltags::run_app()
} # }
```

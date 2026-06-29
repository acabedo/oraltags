#' Carpeta de datos del usuario para oraltags
#'
#' Devuelve (y crea, si no existe) la carpeta estándar donde oraltags persiste
#' la configuración, los análisis guardados, las copias de seguridad y los
#' audios cargados. Usa \code{tools::R_user_dir()} para respetar las
#' convenciones del sistema operativo.
#'
#' @return Ruta (cadena) a la carpeta de datos del usuario.
#' @export
oraltags_data_dir <- function() {
  d <- tools::R_user_dir("oraltags", "data")
  if (!dir.exists(d)) dir.create(d, recursive = TRUE)
  d
}

#' Lanzar la aplicación oraltags
#'
#' Inicia la aplicación Shiny de etiquetado de corpus oral. Los datos del
#' usuario se guardan en \code{\link{oraltags_data_dir}()}.
#'
#' @param ... Argumentos adicionales pasados a \code{shiny::runApp()}
#'   (por ejemplo \code{launch.browser}, \code{port}, \code{host}).
#' @return Invisible. Se llama por su efecto: lanza la app.
#' @examples
#' \dontrun{
#' oraltags::run_app()
#' }
#' @export
run_app <- function(...) {
  options(shiny.maxRequestSize = 2048 * 1024^2)
  oraltags_data_dir()  # crea la carpeta de datos en el primer arranque
  app_dir <- system.file("app", package = "oraltags")
  if (!nzchar(app_dir)) {
    stop("No se encuentra la carpeta 'app' del paquete oraltags; ",
         "reinstala el paquete.")
  }
  shiny::runApp(app_dir, ...)
}

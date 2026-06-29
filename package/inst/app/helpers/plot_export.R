# R/plot_export.R — utilidades puras de exportación (sin Shiny)

# Nombre de archivo saneado + fecha ISO + extensión.
plot_filename <- function(base, ext, date = Sys.Date()) {
  b <- gsub("[^a-z0-9_-]+", "_", tolower(base))
  b <- gsub("^_+|_+$", "", b)
  if (!nzchar(b)) b <- "grafico"
  sprintf("%s_%s.%s", b, format(as.Date(date), "%Y-%m-%d"), ext)
}

# Inyecta botones de exportación (copy/csv/excel) en las opciones de DT::datatable,
# exportando TODAS las filas. Conserva el resto de opciones.
dt_with_buttons <- function(options = list()) {
  dom <- if (is.null(options$dom)) "lfrtip" else options$dom
  if (!grepl("B", dom, fixed = TRUE)) dom <- paste0("B", dom)
  options$dom <- dom
  exp_all <- list(modifier = list(page = "all"))
  options$buttons <- list(
    list(extend = "copy",  exportOptions = exp_all),
    list(extend = "csv",   exportOptions = exp_all),
    list(extend = "excel", exportOptions = exp_all)
  )
  options
}

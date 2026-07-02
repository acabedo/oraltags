# Diseño: selector de idioma de la interfaz (español / inglés)

Fecha: 2026-06-27
App: `etiquetador_oral.R` (Oraltags, Shiny de un solo archivo, ~2870 líneas)
Rama: `feature/i18n-es-en`

## Contexto

Primer paso de internacionalización (ver `docs/informe-internacionalizacion.md`). Solo
**español (por defecto) e inglés**. `shiny.i18n` 0.3.0 está instalado y expone el patrón
estándar: `Translator$new(...)`, `usei18n(i18n)`, `i18n$t("…")`, `update_lang(...)`.

La cabecera es `titlePanel(div(style="display:flex; justify-content:space-between; …", …))`
(~línea 439). Las preferencias persistentes viven en `config/preferencias.txt` con helpers
puros en `R/prefs.R` (`PREFS_DEFAULTS`, `load_prefs`, `save_prefs`). Los helpers se sourcean
al arranque vía un bucle `for (.f in c(...)) source(...)`.

No se traduce el **esquema de anotación** (33 etiquetas + 181 categorías) ni el **texto
dinámico generado en servidor** (títulos de gráficos, informe de *Métricas*, contenido de
tablas) en este paso.

## Decisiones tomadas (brainstorming)

1. Idiomas: español (default) e inglés. Cambio **en caliente** (sin recargar) con `update_lang`.
2. Selector en la **cabecera, arriba a la derecha**.
3. Cobertura: **núcleo bilingüe** (~120-150 cadenas): pestañas/subpestañas, botones de acción
   principales, cabeceras de sección, textos de ayuda visibles, etiquetas de controles muy
   usados y avisos clave. El resto queda en español, ampliable después.
4. **Persistir** el idioma elegido en `config/preferencias.txt`; default español.

---

## A. Infraestructura i18n

- Crear `i18n/translation.json` (formato shiny.i18n):
  ```json
  {
    "languages": ["es", "en"],
    "translation": [
      { "es": "Anotaciones", "en": "Annotations" },
      { "es": "Contexto",    "en": "Context" }
    ]
  }
  ```
  La **clave de traducción es la cadena en español** (idioma cultural por defecto).
- Al arrancar (global, antes de definir la UI):
  ```r
  i18n <- shiny.i18n::Translator$new(translation_json_path = file.path(APP_DIR, "i18n", "translation.json"))
  i18n$set_translation_language("es")   # default: español
  ```
- En la UI: `shiny.i18n::usei18n(i18n)` (inyecta el JS que permite el cambio en caliente).
- Las cadenas a traducir se escriben `i18n$t("Texto en español")`. Con idioma "es",
  `i18n$t()` devuelve la propia clave; con "en", su traducción.

## B. Selector en la cabecera

- En el lado derecho del `titlePanel`, junto al subtítulo, un selector compacto:
  ```r
  div(style = "display:flex; align-items:center; gap:10px;",
    span(style = "font-size:12px; color:#6b7280;", i18n$t("Etiquetador de datos orales · explorador prosódico")),
    selectInput("lang", NULL, choices = c("Español" = "es", "English" = "en"),
                selected = "es", width = "110px")
  )
  ```
- Servidor:
  ```r
  observeEvent(input$lang, {
    shiny.i18n::update_lang(input$lang, session)   # 0.3.0: update_lang(language, session)
    # persistir
    save_prefs(modifyList(load_prefs(PREFS_FILE), list(idioma = input$lang)), PREFS_FILE)
  }, ignoreInit = TRUE)
  ```
- Por sesión, al conectar, aplicar el idioma persistido (en el bloque de arranque que ya
  carga preferencias): si `prefs$idioma == "en"`, `update_lang("en", session)` y
  `updateSelectInput(session, "lang", selected = "en")`. El default global del traductor
  sigue siendo "es" (la UI estática se construye en español; se cambia por sesión).

## C. Cobertura — núcleo bilingüe (~120-150 cadenas)

Envolver con `i18n$t("…")` SOLO estas categorías (la clave es el texto español actual):
- **Nombres de pestañas y subpestañas**: Anotaciones, Contexto, Análisis fonético,
  Imágenes, Métricas, Praatpicture, Estadísticas, Este archivo, Corpus completo,
  Coincidencia, Barras, Boxplots, Configuración.
- **Botones de acción principales**: Guardar, Guardar fila, Reproducir segmento,
  Calcular F0/Int…, Renderizar, Actualizar, Calcular acuerdo, Refrescar desde disco,
  Guardar preferencias, Mostrar/Ocultar ejemplo_para_paper, Editar variables, etc.
- **Cabeceras de sección** (h5/h6) y el subtítulo del título.
- **Etiquetas de controles muy usados**: Speaker, Label (texto), Filas de contexto (±),
  Variable categórica/numérica, Agrupar por…, Tamaño de letra de gráficos, Mostrar mensaje
  de ánimo al iniciar, Tu propio mensaje, etc.
- **Textos de ayuda visibles** (los `div(class="small-helper-text", …)` cortos).
- **Avisos clave** `showNotification(...)`: "Fila guardada", "Preferencias guardadas", etc.

NO se envuelven: las etiquetas/categorías de anotación (`anot_defs`), ni el texto generado
en servidor (títulos de `plot`, informe de Métricas, encabezados de DT, mensajes largos
puntuales). Quedan en español.

## D. Persistencia

- Extender `PREFS_DEFAULTS` en `R/prefs.R` con `idioma = "es"`. `load_prefs`/`save_prefs`
  ya iteran sobre `names(PREFS_DEFAULTS)`, así que `idioma` se guarda/lee como texto sin
  más cambios (cae en la rama `val` del `switch`).
- El selector persiste el idioma al cambiar; el bloque de arranque lo aplica.

## Integración

- `i18n` es un objeto global creado antes de `ui`. Tanto `ui` como `server` lo usan por
  closure (el archivo es uno solo).
- Dependencia: `shiny.i18n` pasa a ser **requerida** (ya instalada). Se añade a la lista del
  README. (Alternativa de degradación no contemplada: si faltara, la app no arrancaría; se
  documenta el `install.packages("shiny.i18n")`.)
- Sin cambios en el esquema de datos.

## Pruebas

- **Test de consistencia de traducciones** (`testthat`): un helper puro
  `i18n_missing_translations(code_path, json_path)` que (a) parsea el JSON y valida su
  estructura, y (b) extrae todas las claves `i18n$t("…")` del código y devuelve las que no
  tengan una entrada con `en` no vacío. El test exige que la lista de faltantes esté vacía.
  Esto evita olvidar traducir una cadena envuelta.
- Verificación manual: cambiar ES↔EN y comprobar que pestañas, botones y cabeceras cambian
  al instante; reiniciar la app y comprobar que recuerda el idioma; comprobar que el esquema
  de anotación sigue en español.

## Fuera de alcance (YAGNI)

- Traducir el esquema de anotación y el texto dinámico de servidor (paso posterior).
- Idiomas más allá de es/en (la infraestructura queda lista para añadirlos al JSON).
- Formato decimal localizado, fuentes CJK, etc.

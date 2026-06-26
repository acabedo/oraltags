# Informe de viabilidad: internacionalización (i18n) de Oraltags

Fecha: 2026-06-26
Idiomas objetivo: español (actual), inglés, francés, catalán, chino, italiano, alemán.
Ámbito: aplicación Shiny `etiquetador_oral.R` (~2731 líneas, un solo archivo).

---

## 1. Veredicto

**Es viable, pero hay que distinguir dos proyectos muy distintos bajo la misma petición:**

| Capa | Dificultad | Naturaleza |
|---|---|---|
| **A. Interfaz (chrome)**: botones, etiquetas, títulos, pestañas, mensajes, textos de ayuda | Media | Técnica + traducción estándar |
| **B. Esquema de anotación**: 33 variables + 181 categorías lingüísticas | **Alta** | **Lingüística/metodológica, no técnica** |

La capa A es un trabajo de i18n clásico y abordable. La capa B es el verdadero proyecto: traducir el esquema de anotación no es traducir software, es **adaptar un sistema de categorías pragmático-discursivas entre tradiciones lingüísticas**, y además **condiciona el modelo de datos** (ver §4.1 y §6). Recomendación global: **hacerlo por fases**, empezando por la interfaz (es/en) sin tocar el esquema.

---

## 2. Alcance real a traducir (medido sobre el código)

- **~318** cadenas de interfaz en español (labels de inputs, títulos, textos de pestaña, ayudas).
- **44** mensajes/avisos (`showNotification`, `validate(need(...))`, `message(...)`), varios con formato `sprintf` (plantillas).
- **33** variables de anotación + **181** categorías no vacías (`anot_defs_default`).
- **Informes textuales** de la pestaña *Métricas* (prosa generada con `cat`/`sprintf`).
- **Nombres de columnas** de exportación (TSV/CSV): `speaker`, `start`, `F0_mean`, `anot1…` — decisión aparte (ver §4.4).
- **Documentación** (`README.md`, este `docs/`).
- **NO se traduce**: el contenido del usuario (transcripciones, audio, anotaciones ya guardadas).

Volumen aproximado de "unidades de traducción": **chrome ≈ 360 cadenas**; **esquema ≈ 214 (33 labels + 181 categorías)**. Por 6 idiomas nuevos: **chrome ≈ 2160** y **esquema ≈ 1284** traducciones. El esquema es menos volumen pero mucho más caro por unidad (requiere lingüistas, no traductores generales).

---

## 3. Enfoques técnicos en R/Shiny

| Enfoque | Pros | Contras | Apto para Oraltags |
|---|---|---|---|
| **`shiny.i18n`** (Appsilon) | Maduro; diccionario JSON/CSV; cambio de idioma en runtime con un selector; `i18n$t("texto")` | Una dependencia más; hay que envolver cada cadena | **Recomendado** para la capa A |
| **Diccionario propio** (named list + función `tr(key, lang)`) | Sin dependencias; control total; fácil de versionar | Hay que implementar el selector y la reactividad a mano | Buena alternativa ligera |
| **`gettext` / archivos `.po`** (Poedit) | Estándar de la industria; herramientas de traducción maduras | Menos idiomático en Shiny; flujo de compilación | Posible, pero menos natural aquí |

**Recomendación:** `shiny.i18n` con diccionario en CSV/JSON y un `selectInput` de idioma en la cabecera. El patrón de la app ayuda: las variables de anotación **ya son configurables desde la UI** (`anot_defs`, editor de variables), así que la capa B puede apoyarse en diccionarios por idioma cargados en `anot_defs`.

---

## 4. Retos específicos por contenido

### 4.1. El esquema de anotación (el gran reto)
Las 181 categorías son terminología pragmático-discursiva muy fina (atenuación orientada al *yo*/*tú*, marcadores de reformulación, tonema, función fática…). Problemas:
- **No siempre hay equivalente directo** entre tradiciones lingüísticas (p. ej. categorías de cortesía o atenuación del español coloquial no mapean 1:1 al alemán o al chino).
- **Traducción experta, no automática**: requiere lingüistas de cada lengua, idealmente con formación en pragmática.
- **Impacto en los datos** (crítico): hoy las anotaciones se guardan como **el texto de la categoría** en el TSV. Si la categoría se traduce, el mismo dato se guardaría distinto según el idioma activo → **dos análisis del mismo corpus en idiomas distintos dejarían de ser comparables**, y la pestaña *Coincidencia* **dejaría de emparejar por categoría** (compara el texto exacto). Solución en §6.

### 4.2. Chino y otros scripts (CJK)
- **Encoding**: la app ya trabaja en UTF-8 (lectura/escritura), así que el almacenamiento de chino no es problema.
- **Fuentes en gráficos base-R**: los títulos/ejes con caracteres chinos **no se renderizan** si el dispositivo gráfico no usa una fuente CJK (saldrían cuadros "tofu"). Hay que configurar la familia de fuente por SO (p. ej. `par(family=...)`, o `showtext`/`ragg`) para `oscillo/spectro/F0` y los gráficos estadísticos. *Praatpicture* y *seewave* dibujan con sus propios textos (en inglés) y no son traducibles.
- Mismo cuidado, en menor grado, con acentos de francés/alemán/catalán (UTF-8 lo cubre; solo vigilar fuentes de los PDF de descarga).

### 4.3. Mensajes con formato y plantillas
Los `sprintf("...%d...", n)` deben convertirse en **plantillas traducibles** (la cadena con los `%` va al diccionario). Cuidar el **orden de argumentos** (algunas lenguas reordenan) usando `%1$s`, `%2$d`, etc.

### 4.4. Formato numérico y de columnas
- **Decimal**: es/fr/de/ca usan **coma** decimal; en/zh/it usan punto (it varía). Afecta a la **visualización** y, si se aplicara al export, rompería la lectura posterior. Recomendación: **mantener punto en los archivos guardados** (formato de datos estable) y traducir solo la *visualización*.
- **Nombres de columnas** del TSV: **no traducir** las claves (`F0_mean`, `anot1`…). Son contrato de datos; traducir solo sus *etiquetas mostradas*.

### 4.5. Componentes externos no traducibles
Textos internos de `praatpicture`, `seewave`, `DT` (paginación) y mensajes de R quedan en su idioma (mayormente inglés). `DT` sí admite traducir su interfaz vía `language` (URLs de i18n de DataTables).

---

## 5. Estimación de esfuerzo (orientativa, por fases)

| Trabajo | Esfuerzo técnico | Esfuerzo de traducción |
|---|---|---|
| Infra i18n (paquete + selector + envolver ~360 cadenas) | Medio | — |
| Traducir chrome ×6 idiomas | Bajo (cargar diccionarios) | **Alto** (~2160 unidades) |
| Modelo clave-estable + etiqueta (refactor de datos) | Medio-alto | — |
| Traducir esquema de anotación ×6 (lingüistas) | Bajo (datos) | **Muy alto / especializado** (~1284 unidades) |
| Fuentes CJK + decimal de visualización | Bajo-medio | — |

El cuello de botella **no es programar**, sino **traducir con calidad** (sobre todo el esquema) y **rediseñar el almacenamiento** para que los datos sigan siendo comparables.

---

## 6. Recomendación: modelo de datos "clave estable + etiqueta"

Cambio de fondo que habilita todo lo demás sin romper datos:
- Cada categoría tiene una **clave interna estable** (p. ej. `att_orient_yo`) y un **diccionario de etiquetas por idioma** (`{es: "Orientada al yo", en: "Self-oriented", …}`).
- En el TSV se guarda **la clave**, no la etiqueta; la UI muestra la etiqueta del idioma activo.
- Beneficios: los análisis y los archivos de jueces **emparejan por clave** (idioma-independiente); *Coincidencia* y *Corpus* siguen funcionando entre idiomas; añadir un idioma es añadir una columna al diccionario.
- Coste: migrar `anot_defs` y los TSV existentes (script de migración de etiqueta→clave).

---

## 7. Plan por fases sugerido

1. **Fase 1 — Interfaz es/en** (quick win): `shiny.i18n` + selector de idioma; traducir solo el *chrome* (botones, pestañas, ayudas, mensajes). El esquema de anotación sigue configurable y en español. Sin cambios en datos. *Demuestra valor con poco riesgo.*
2. **Fase 2 — Modelo clave/etiqueta**: refactor de `anot_defs` y migración de datos; preparar el terreno para traducir el esquema sin romper comparabilidad.
3. **Fase 3 — Esquema multilingüe**: traducir las 214 unidades del esquema con lingüistas, idioma a idioma. Empezar por los más cercanos (catalán, italiano), luego francés/alemán.
4. **Fase 4 — Chino/CJK**: fuentes CJK en los gráficos (showtext/ragg), revisión de PDF de descarga, y traducción del esquema al chino (la más costosa por distancia conceptual).
5. **Transversal**: formato decimal de visualización, `DT` `language`, README/docs por idioma.

**Orden de coste creciente por idioma**: inglés < catalán ≈ italiano < francés ≈ alemán < **chino** (script + fuentes + mayor distancia conceptual del esquema).

---

## 8. Conclusión

- **Sí es viable.** La interfaz se internacionaliza con un patrón estándar (`shiny.i18n`) y esfuerzo moderado.
- **El verdadero proyecto es el esquema de anotación**: es trabajo lingüístico especializado y obliga a un **cambio de modelo de datos** (clave estable + etiqueta) para no perder la comparabilidad entre corpus ni romper la pestaña de jueces.
- **El chino** es el idioma más caro (fuentes en gráficos + adaptación conceptual), no por encoding.
- **Recomendación**: empezar por **Fase 1 (es/en, solo interfaz)** para validar el enfoque con bajo riesgo, y planificar las fases 2–4 con presupuesto de traducción experta.

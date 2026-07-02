# Complete guide to the application

> 🇪🇸 *Esta página también está disponible en español: [Guía completa de
> la
> aplicación](https://acabedo.github.io/oraltags/articles/guia-aplicacion.md).*

This guide describes **every operation** available in the oraltags
interface, organised as in the application itself: first the sidebar
(loading material and navigating) and then each main tab
(**Annotations**, **Context**, **Phonetic analysis**, **Statistics**,
**Agreement** and **Settings**).

## Sidebar: loading material and navigating

![Initial
screen](https://raw.githubusercontent.com/acabedo/oraltags/main/imgs/1_pantalla_inicial.png)

Initial screen

### Opening an existing analysis

If you have already worked on a corpus, it appears in the **“Open
analysis”** dropdown. Clicking **Open** loads the saved TSV
(`analisis_<name>.txt`) and looks for the audio with the same base name
in the audio folder. This is the fast path: nothing is recomputed.

### Trying a sample

The package bundles three audio + TextGrid pairs (`muestra_1..3`). Pick
one under **“Try a sample”** and click **“Load sample”**.

### First time with a new file

1.  **Upload TextGrid**: accepts Praat TextGrids. If the TextGrid
    contains the tiers `phones` and `words` (typical *Montreal Forced
    Aligner* output), the app offers to **generate the intonation groups
    (IGs) automatically**; you can adjust the **minimum pause (s)**
    threshold (0.3 s by default) that separates two IGs. If an analysis
    already existed for that name, the app asks whether to **load the
    saved one** or **regenerate the IGs** from the TextGrid.
2.  **Upload audio**: WAV or MP3 (MP3 is converted to WAV for analysis).
    Only needed if the audio is not already loaded from a previous
    session.
3.  **Upload MP4**: in addition to the audio analysis, it enables a
    video viewer in the sidebar. With `ffmpeg` installed, the viewer
    plays the exact clip of the active segment.

Audio and transcription are paired by **base name**: `interview.wav` +
`interview.TextGrid` → analysis `analisis_interview.txt`.

### Listening and navigation

With an active analysis, the sidebar shows:

- The **“Active analysis”** card with the name and the number of
  intonation groups, and the **“Change file”** button to return to the
  initial state.
- The **current segment** (speaker and transcription).
- **▶ Segment**: plays only the active segment. **▶ Context**: plays it
  extended by the seconds set in **Before (s)** and **After (s)**.
- **Sequential navigation**: **⬅ Previous / Next ➡** buttons, a “Row X
  of N” indicator and a direct jump with **“Go to row”**.
- **Download CSV**: exports the full analysis of this corpus.

When you change row, the app **automatically computes** the acoustic
metrics of the segment and **autosaves** your work.

## Annotations tab

![Annotation
form](https://raw.githubusercontent.com/acabedo/oraltags/main/imgs/2_anotacion.png)

Annotation form

The tagging form is divided into **five thematic blocks**:

| Block | Content |
|----|----|
| **Structure** | Utterance type, sentence modality, information status, syntactic complexity, reformulation/expansion, global discourse function, reference to others’ discourse, temporality |
| **Pragmatics** | Basic pragmatic function, interpersonal function, mitigation (presence, orientation and procedure), intensification, politeness, other’s face, self-image |
| **Discourse and interaction** | Conversational move, turn management, relation to the previous turn, interactive dynamics, discourse marker, phatic function, deixis, colloquial resources |
| **Paralinguistic / non-verbal** | Paralanguage, non-verbal overlaps, articulatory noise, breathing phenomena, non-verbal sounds as turn-taking, ambient noise, vocal attitude |
| **Emotions** | Ekman emotional tone (Neutral, Joy, Sadness, Fear, Anger, Disgust, Surprise, Contempt) and **intensity** on a 1–5 scale |

Operations:

- Fill in the dropdowns of the block and click **Save** (or simply
  navigate: there is autosave, with the notice “✓ Auto-saved (row N)”).
- In **Emotions**, click an emoji and adjust the intensity with the
  slider; the value is stored as `Emotion - intensity`
  (e.g. `Alegría - 4`).
- The **Notes** field accepts free notes per segment.
- All categories are **configurable** from *Settings → Edit variables*
  (see below). The full list of variables is in [Variables and
  files](https://acabedo.github.io/oraltags/articles/variables-and-files.md).

## Context tab

![Segment
context](https://raw.githubusercontent.com/acabedo/oraltags/main/imgs/3_contexto.png)

Segment context

- **Speaker** and **Label (text)**: let you **edit** the speaker and the
  transcription of the active row; saved with **“Save row”**.
- **Context rows (±)**: how many previous and following rows are shown
  in the table (the active row is highlighted).
- **“Show ejemplo_para_paper”**: adds a column with the example
  formatted for citing in a paper, with the reference
  `(corpus, start-end)`.
- **Copy / CSV / Excel** buttons: export the whole table.

## Phonetic analysis tab

Three subtabs about the active segment:

### Images

![Oscillogram, spectrogram and F0
curve](https://raw.githubusercontent.com/acabedo/oraltags/main/imgs/4_analisis_fonetico.png)

Oscillogram, spectrogram and F0 curve

- **Oscillogram**, **spectrogram** and **pitch curve (F0)** of the
  segment.
- **▶ Play segment** and the **“Compute F0/Int for all segments”**
  button, which computes the acoustic metrics of **all** rows of the
  corpus at once (useful before going to Statistics).

### Metrics

![Textual prosodic
report](https://raw.githubusercontent.com/acabedo/oraltags/main/imgs/5_metricas.png)

Textual prosodic report

Complete textual prosodic report of the current row: speaker,
start/end/duration, preceding and following pauses, number of words,
speech rate (words/s and phonemes/s), F0 (mean, median, SD, p10–p90
range in semitones, global inflection, final toneme and melodic pattern)
and intensity. Each measure is described in [Variables and
files](https://acabedo.github.io/oraltags/articles/variables-and-files.md).

### Praatpicture

![Multi-panel Praat-style
figure](https://raw.githubusercontent.com/acabedo/oraltags/main/imgs/6_praatpicture.png)

Multi-panel Praat-style figure

Multi-panel Praat-style figure, powered by the
[praatpicture](https://github.com/rpuggaardrode/praatpicture) package by
**Rasmus Puggaard-Rode**. Tick the panels you want — **Oscillogram**,
**Spectrogram**, **F0**, **Intensity** — and click **Render**.

## Statistics tab

Two scopes: **This file** (the active corpus) and **Full corpus** (the
consolidated file of all your corpora).

### This file

![Bar
chart](https://raw.githubusercontent.com/acabedo/oraltags/main/imgs/7_grafico_barras.png)

Bar chart

- **Bars**: frequencies of a **categorical variable** (speaker or any
  annotation variable), as **absolute** values or **percentage**. Click
  **Update** to redraw.
- **Boxplots**: distribution of a **numeric variable** (duration, F0,
  intensity, speech rate…), optionally **grouped** by a categorical
  variable; a descriptive summary is shown below.

![Grouped
boxplot](https://raw.githubusercontent.com/acabedo/oraltags/main/imgs/8_grafico_boxplot.png)

Grouped boxplot

All charts can be downloaded as **PNG (300 dpi)** and **vector PDF**;
tables via **Copy / CSV / Excel**.

### Full corpus

Global overview of the consolidated `analisis_todos.txt`, which gathers
all rows of all your corpora (the `filename` column identifies the
origin).

- **Refresh from disk**: re-reads the consolidated file.
- **(Optional) Load another consolidated file**: analyse an external
  file (for example, another team’s consolidated corpus).
- **Files included in the statistics**: multi-select with the files
  present in the consolidated corpus. **All** are included by default;
  remove or add files (each has its ✕ button) and every table and chart
  of the tab is recomputed with the selection only.
- **Summary** (files, rows and variables) and **per-file table**.
- **General descriptives** of all numeric variables.
- **Chart**: bars (absolute or % frequencies) or boxplot with grouping.
- **Cross table**: descriptives of a numeric variable grouped by up to
  **4 variables** simultaneously.

## Agreement tab (inter-annotator agreement)

![Agreement between
judges](https://raw.githubusercontent.com/acabedo/oraltags/main/imgs/9_acuerdo_jueces.png)

Agreement between judges

Measures annotation reliability when **2–10 people** tag the same
corpus:

1.  Each judge works on the **same audio and TextGrid** and saves their
    `analisis_*.txt` (just copy the file from each annotator’s
    `analisis/` folder).
2.  Upload the files in **“Analysis files (2–10)”** — or click **“Load
    sample analyses (judges)”** to see the bundled 3-judge example.
3.  The app **matches the common segments** by start, end and label
    (`start`/`end`/`label`).
4.  Choose the **variables to compare** and, if any is ordinal (numeric
    levels, e.g. 1–5), mark it under **“Ordinal variables”** to use
    **weighted kappa**.
5.  Click **“Compute agreement”**.

Results:

- Summary: number of judges, matched common segments, variables compared
  and mean kappa.
- Per-variable table: **n**, **% agreement**, **Cohen’s kappa** (2
  judges or pairwise mean), **Fleiss’ kappa**, **pairwise kappa**,
  **Krippendorff’s α** (requires the `irr` package) and
  **interpretation** (Landis & Koch scale: *Slight*, *Fair*, *Moderate*,
  *Substantial*, *Almost perfect*).
- **Kappa chart by variable** (downloadable as PNG/PDF).
- **Confusion matrix** between any two judges for a variable: choose the
  variable, the row judge and the column judge.

![Kappa by variable and confusion
matrix](https://raw.githubusercontent.com/acabedo/oraltags/main/imgs/10_acuerdo_kappa.png)

Kappa by variable and confusion matrix

## Settings tab

### Acoustic parameters

- **Quartile percentage (%)**: size of the initial/final window (20 % by
  default) used for the toneme and the per-stretch averages
  (`F0_ini_q*`, `F0_fin_q*`, `Int_ini_q*`, `Int_fin_q*`).

### Annotation-variable editor

- **“Edit variables”** opens an editor with the 33 variables (`anot1` …
  `anot33`): for each one you can change the **label** and the list of
  **categories** (one per line). This way the same tagger works for
  different annotation schemes without touching code.
- The custom scheme is stored in `config/etiquetas_variables.txt`.
- **“Restore defaults”** returns to the original scheme.

### Saved-analyses manager

To **delete previous analyses**:

1.  Select one or more files in the (multiple) dropdown.
2.  Click **“Delete selected”**.
3.  In the confirmation dialog you can tick **“Also delete the
    associated audio”**.

Upon confirmation, the app: saves a **backup copy** of each file in
`backup/`, deletes the `analisis_*.txt`, removes its rows from the
consolidated `analisis_todos.txt` and, if the deleted analysis was the
active one, returns to the initial screen.

### Preferences

- **Chart font size**: global slider (0.7×–2×).
- **Encouraging message at startup**: a random phrase or your own text.
- **“Save preferences”** persists these settings (and the language
  chosen in the header) in `config/preferencias.txt`.

## Interface language

The **Español / English** selector in the header switches the interface
instantly and remembers your choice. Important: **the values stored in
the analysis files stay in Spanish** (canonical scheme), so two
annotators using different interface languages produce comparable files.

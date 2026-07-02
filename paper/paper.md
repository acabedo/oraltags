---
title: 'Oraltags: an R/Shiny application for pragmatic-discursive annotation and prosodic analysis of oral corpora'
tags:
  - R
  - Shiny
  - corpus linguistics
  - spoken language
  - prosody
  - speech analysis
  - pragmatics
  - annotation
  - inter-rater agreement
authors:
  - name: Adrián Cabedo-Nebot
    orcid: 0000-0002-3881-9308
    affiliation: 1
affiliations:
  - name: Universitat de València, Spain
    index: 1
date: 2 July 2026
bibliography: paper.bib
---

# Summary

The analysis of spoken language usually requires two tasks that are typically carried out
in separate tools: fine-grained linguistic annotation and quantitative acoustic/prosodic
measurement. `Oraltags` is an open-source application, written in R [@rcore] with the Shiny
framework [@shiny], that integrates both in a single, no-code graphical interface. Users
load an audio or video recording together with its transcription (CSV, plain text, or Praat
TextGrid), navigate the material intonation group by intonation group, and obtain, for each
segment, a set of automatically computed prosodic metrics: fundamental frequency (mean,
median, standard deviation and range in semitones), global pitch movement and final toneme,
intensity, speech rate (words and phonemes per second) and surrounding pauses. The same
segments can be annotated with a **fully configurable**, multi-block scheme (structure,
pragmatics, discourse and interaction, paralinguistic phenomena and emotions), and the
results explored through navigable tables, Praat-style figures [@praatpicture] and
statistical charts — for a single recording or for a user-defined selection of the
consolidated corpus — with export to CSV/Excel and publication-quality PNG/PDF. `Oraltags`
also estimates **inter-annotator agreement** (Cohen's and Fleiss' kappa, and Krippendorff's
alpha) for files annotated by several judges, and offers a bilingual (Spanish/English)
interface and documentation. Acoustic computation relies on established R packages for sound
analysis [@seewave; @wrassp; @tuner; @rpraat].

# Statement of need

Researchers working with oral corpora must combine two methodologically distinct
operations, discourse-level annotation and prosodic measurement, that current tools keep
apart. Praat [@praat] is the de facto standard for acoustic analysis but provides no
integrated, configurable scheme for pragmatic or discursive annotation. Tier-based
annotation environments such as ELAN [@elan] support rich multimodal annotation but do not
compute prosodic metrics automatically. Tools that do automate intonation analysis, such as
the Eti_ToBI transcriber [@elviragarcia] or the Momel/INTSINT Praat plugin [@hirst], assume
prior familiarity both with Praat and with a phonological transcription model such as ToBI.
General-purpose R packages for speech [@seewave; @wrassp; @rpraat; @tuner] expose powerful
acoustic routines but require programming skills [@gries; @anthony]. Prosodic annotation is,
moreover, notoriously slow and difficult in itself: segmenting speech into prosodic units is
a traditional bottleneck of prosody studies [@garrido], and the same acoustic cue may signal
emphasis, topic change or speaker change, so that interpretation cannot be fully delegated
to an algorithm [@mary]. As a result, a typical workflow is fragmented across several
applications and manual steps, which is time-consuming and hampers reproducibility.

`Oraltags` addresses this gap by bringing together, in one application that requires no
programming, (i) a configurable multi-layer pragmatic-discursive annotation scheme, (ii)
automatic per-segment prosodic metrics, and (iii) inter-annotator agreement statistics,
together with export of the resulting annotated, time-aligned dataset. In doing so it
follows the design principle that corpus software should combine analytical power with
usability for non-programmers [@hardie], while remaining open and inspectable so that
methodological choices stay visible and replicable [@anthony].

`Oraltags` is aimed primarily at researchers and graduate students in pragmatics,
conversation analysis and discourse studies, who often need to relate intonation to
discourse function but are not specialists in phonetics. Such users are not assumed to have
worked with Praat, nor to be familiar with concepts such as PitchTier or IntensityTier: for
each segment the melodic curve is displayed and the prosodic information is delivered as a
plain-language report of named metrics (\autoref{fig:metrics}), so that the emphasis can
remain on what the intonation does in the discourse rather than on the acoustic machinery
behind it.

Because every annotation label and category is fully editable from the interface, the default
scheme—organised in blocks covering utterance structure, pragmatics, discourse and
interaction, paralinguistic phenomena and emotion (the latter following Ekman's basic
emotions [@ekman])—can be adapted or replaced for different research questions without
changing any code.

`Oraltags` has already supported empirical graduate research: two Master's theses in the
*Máster de Estudios Hispánicos Avanzados* at the Universitat de València used it to annotate
and prosodically analyse semi-directed sociolinguistic interviews — one on spontaneous speech
from the PRESEEA-Valencia corpus (Alba Molins), and the other on gender differences in covert
and overt prestige in interviews about bodybuilding (Yaiza Bustos).

# Functionality

`Oraltags` is organised as a set of tabs covering a full analysis workflow without leaving the
application (\autoref{fig:main}):

- **Material loading and navigation.** Audio (WAV/MP3) or video (MP4) together with a
  transcription (CSV, plain text or Praat TextGrid) are loaded as time-aligned intonation
  groups, which the user reviews sequentially while listening to each segment or its
  surrounding context. TextGrids produced by forced alignment (tiers `words`/`phones`) are
  segmented into intonation groups automatically using a configurable pause threshold.
- **Automatic prosodic metrics.** For every segment the application computes, using established
  R routines [@wrassp; @seewave], the mean, median, standard deviation and range of F0, global
  pitch movement and final toneme, intensity, speech rate, and surrounding pauses.
- **Configurable annotation.** A multi-block scheme (structure, pragmatics, discourse and
  interaction, paralinguistic phenomena, and emotion) whose labels and categories are fully
  editable from the interface, so the same tool serves different annotation schemes.
- **Inter-annotator agreement.** For a corpus annotated by several judges, `Oraltags` reports
  percentage agreement, Cohen's and Fleiss' kappa [@landiskoch], and Krippendorff's alpha
  [@krippendorff], together with per-variable kappa charts and pairwise confusion matrices.
- **Exploration, corpus management and export.** Navigable tables, bar and box plots,
  Praat-style multi-panel figures [@praatpicture], and descriptive statistics for the active
  recording or for a user-defined selection of the consolidated corpus; saved analyses can be
  managed (and safely deleted, with automatic backups) from the interface. Tables export to
  CSV/Excel and charts to PNG/PDF; the interface is bilingual (Spanish/English).

![The main annotation and analysis interface of Oraltags.\label{fig:main}](../imgs/1_pantalla_inicial.png)

![Per-segment prosodic report. The computed metrics (F0 statistics in semitones, pitch movement and final toneme, intensity, speech rate and surrounding pauses) are presented as a plain-language summary, so that users who are not phoneticians can read the prosody of a segment without handling PitchTier or IntensityTier objects.\label{fig:metrics}](../imgs/5_metricas.png)

`Oraltags` is open source under the GPL-3.0 license. It can be installed as an R package
(`remotes::install_github("acabedo/oraltags", subdir = "package")`) and launched with
`oraltags::run_app()`; three audio + TextGrid samples and three sample judge annotations are
bundled, so every feature can be tried without supplying any material of one's own. The
repository includes a `testthat` suite run through continuous integration, and bilingual
(English/Spanish) user documentation is published at
<https://acabedo.github.io/oraltags/>.

# Acknowledgements

`Oraltags` has been developed in the context of research on the prosody and pragmatics of
spoken Spanish at the Universitat de València. This work and the application were funded by
the research project *Estudio de los condicionantes sociales del español actual en el centro
y norte de España: nuevas identidades, nuevos retos, nuevas soluciones* (ECOS-C/N), grant
PID2023-148371NB-C42, Ministerio de Ciencia, Innovación y Universidades (Spain), coordinated
by A. Cabedo Nebot and C. Illamola Gómez.

The *Praatpicture* tab builds on the `praatpicture` package by Rasmus Puggaard-Rode
[@praatpicture]. Parts of the application code, the R package infrastructure and the
documentation were developed with the assistance of generative AI (Anthropic's Claude); all
AI-assisted code and text were reviewed, tested and validated by the author.

# References

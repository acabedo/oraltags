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
date: 27 June 2026
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
results explored through navigable tables, Praat-style figures and statistical charts, with
export to CSV/Excel. `Oraltags` also estimates **inter-annotator agreement** (Cohen's and
Fleiss' kappa, and Krippendorff's alpha) for files annotated by several judges, and offers a
bilingual (Spanish/English) interface. Acoustic computation relies on established R packages
for sound analysis [@seewave; @wrassp; @tuner; @rpraat].

# Statement of need

Researchers working with oral corpora must combine two methodologically distinct
operations—discourse-level annotation and prosodic measurement—that current tools keep
apart. Praat [@praat] is the de facto standard for acoustic analysis but provides no
integrated, configurable scheme for pragmatic or discursive annotation. Tier-based
annotation environments such as ELAN [@elan] support rich multimodal annotation but do not
compute prosodic metrics automatically. General-purpose R packages for speech
[@seewave; @wrassp; @rpraat; @tuner] expose powerful acoustic routines but require
programming skills that many linguists, especially those working on pragmatics, conversation
analysis or discourse, do not have. As a result, a typical workflow is fragmented across
several applications and manual steps, which is time-consuming and hampers reproducibility.

`Oraltags` addresses this gap by bringing together, in one application that requires no
programming, (i) a configurable multi-layer pragmatic-discursive annotation scheme, (ii)
automatic per-segment prosodic metrics, and (iii) inter-annotator agreement statistics,
together with export of the resulting annotated, time-aligned dataset.

The motivation behind `Oraltags` is to facilitate the combined **qualitative and
quantitative** analysis of real speech material through an interface suited to that task, so
that researchers and students can annotate and measure spoken data within a single
environment and without writing code. It is aimed primarily at linguists and graduate
students working on the pragmatics, discourse and prosody of spoken language, as well as at
teaching in these areas.

Because every annotation label and category is fully editable from the interface, the default
scheme—organised in blocks covering utterance structure, pragmatics, discourse and
interaction, paralinguistic phenomena and emotion (the latter following Ekman's basic
emotions [@ekman])—can be adapted or replaced for different research questions without
changing any code.

`Oraltags` has already supported empirical graduate research: two Master's theses in the
*Máster de Estudios Hispánicos Avanzados* at the Universitat de València (by Alba Molins and
Yaiza Bustos) used the tool for the annotation and prosodic analysis of their oral data.

# References

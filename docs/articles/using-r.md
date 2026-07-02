# Using oraltags from R (package code)

> 🇪🇸 *Esta página también está disponible en español: [Uso desde
> R](https://acabedo.github.io/oraltags/articles/uso-con-r.md).*

oraltags is first and foremost an interactive application, but
everything it produces is a **plain TSV** that you can exploit from R.
This page gathers the exported functions of the package and code recipes
to work with your analyses outside the app.

## Exported functions

### `run_app()`

Launches the Shiny application. Accepts the
[`shiny::runApp()`](https://rdrr.io/pkg/shiny/man/runApp.html)
arguments:

``` r

library(oraltags)

run_app()                          # normal use
run_app(port = 4321)               # fixed port
run_app(launch.browser = FALSE)    # without opening the browser
```

### `oraltags_data_dir()`

Returns (and creates if missing) the user data folder, where the app
stores analyses, backups, configuration and audio:

``` r

oraltags_data_dir()
list.files(oraltags_data_dir(), recursive = TRUE)
```

## Reading your analyses in R

Each corpus is a TSV (UTF-8, tab-separated, unquoted):

``` r

analysis_dir <- file.path(oraltags_data_dir(), "analisis")

# A specific corpus
df <- read.delim(file.path(analysis_dir, "analisis_muestra_1.txt"),
                 fileEncoding = "UTF-8", quote = "", na.strings = "")

# The consolidated file of all corpora (extra `filename` column)
all_df <- read.delim(file.path(analysis_dir, "analisis_todos.txt"),
                     fileEncoding = "UTF-8", quote = "", na.strings = "")
```

Each column is described in [Variables and
files](https://acabedo.github.io/oraltags/articles/variables-and-files.md).

### Analysis examples

``` r

# Mean duration of the intonation groups per speaker
df$duration <- df$end - df$start
aggregate(duration ~ speaker, df, mean)

# Frequencies of sentence modality (anot2)
sort(table(df$anot2), decreasing = TRUE)

# Mean F0 by utterance type (anot1)
aggregate(as.numeric(F0_mean) ~ anot1, df, mean)

# Reproducing the file selection of the "Full corpus" tab:
sub_corpus <- subset(all_df, filename %in% c("analisis_muestra_1.txt",
                                             "analisis_muestra_2.txt"))
```

## Samples bundled with the package

The example materials live in `inst/extdata`:

``` r

# Audio + TextGrid of the three samples
system.file("extdata", "samples", package = "oraltags") |> list.files()

# Simulated analyses by 3 judges (for the Agreement tab)
system.file("extdata", "jueces", package = "oraltags") |>
  list.files(recursive = TRUE, full.names = TRUE)
```

## Using the internal helpers (advanced)

The pure functions the app uses for descriptives and inter-annotator
agreement live in `inst/app/helpers` and can be loaded with
[`source()`](https://rdrr.io/r/base/source.html). They are not part of
the exported API (they may change between versions), but they are useful
to reproduce the app’s computations in a script:

``` r

helpers <- system.file("app", "helpers", package = "oraltags")
source(file.path(helpers, "stats_utils.R"))   # freq_table, skewness…
source(file.path(helpers, "agreement.R"))     # kappa, alpha, judge matrix
source(file.path(helpers, "corpus_stats.R"))  # describe_numeric, per-file summary
```

### Inter-annotator agreement from code

``` r

judges_dir <- system.file("extdata", "jueces", package = "oraltags")
files <- list.files(judges_dir, pattern = "^analisis_.*\\.txt$",
                    recursive = TRUE, full.names = TRUE)

# Read the analyses (auto-detects TSV/CSV)
dfs <- lapply(files, read_analysis_file)
names(dfs) <- tools::file_path_sans_ext(basename(files))

# Common-segments × judges matrix for one variable
mat <- build_rater_matrix(dfs, "anot1")

compute_agreement_for_var(mat)                  # nominal
compute_agreement_for_var(mat, ordinal = TRUE)  # ordinal (weighted kappa)

# Individual measures
agreement_percent(mat)     # % of total agreement
fleiss_kappa(mat)          # Fleiss' kappa (m judges)
cohen_kappa(mat[, 1], mat[, 2])   # Cohen's kappa between two judges
krippendorff_alpha(mat)    # Krippendorff's alpha (requires `irr`)
interpret_kappa(0.64)      # "Substantial" (Landis & Koch)
```

### Corpus descriptives from code

``` r

all_df <- read_analysis_file(file.path(oraltags_data_dir(),
                                       "analisis", "analisis_todos.txt"))

corpus_file_summary(all_df)             # number of files, rows and variables
describe_numeric(all_df, "F0_mean")     # descriptives of a numeric variable
describe_numeric(all_df, "F0_mean",
                 c("speaker", "anot2")) # crossed by up to 4 groups
freq_table(all_df$anot1)                # frequencies of a categorical variable
```

## Where the code lives

- Application: `system.file("app", "app.R", package = "oraltags")`.
- Pure helpers: `system.file("app", "helpers", package = "oraltags")`.
- Repository (with the source-run version, `etiquetador_oral.R`):
  <https://github.com/acabedo/oraltags>.

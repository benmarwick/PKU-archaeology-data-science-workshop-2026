# =============================================================================
# ARCHAEOLOGICAL DATA SCIENCE WORKSHOP
# Master simulation: Lower / Middle / Upper Palaeolithic lithic dataset
# =============================================================================
#
# This script is run ONCE by the instructor before the workshop, NOT by
# students. It generates two files:
#   1. lithics_raw.csv   -> deliberately spoiled, used by students
#   2. (verification only, not saved) the clean tibble used to check that
#      ideal statistical properties exist before the workshop begins
#
# Students reconstruct the clean dataset THEMSELVES using
# parse_number(), str_squish(), case_when(), na_if(), and filter().
# Their cleaned output becomes the dataset used for inference and PCA.
#
# DESIGN PRINCIPLE: every variable here maps to a real, citable pattern in
# Palaeolithic lithic technology. Students are not just learning R - they are
# learning the major technological transitions of human evolution through
# the data itself. See companion reference list for full citations.
# =============================================================================

set.seed(208)  # ARCHY 208 - fixed seed = reproducible across every re-run

library(tidyverse)
library(MASS)  # mvrnorm() for correlated multivariate normal generation

n_per_period <- 100
n_total <- n_per_period * 3


# =============================================================================
# SECTION 1: PERIOD AND CONTEXT
# =============================================================================
# WHY: period is the master organizing variable for the whole dataset and
#      the whole workshop. Every other variable below is generated conditional
#      on period, so that students discover (via PCA and ANOVA)
#      that period is the dominant axis of variation in the assemblage -
#      exactly as it should be, since technological change over time is the
#      central narrative of Palaeolithic archaeology.
# INTERPRETATION: there is no statistical test on period alone - it is the
#      grouping variable for every other test this week.

period <- factor(
  rep(c("Lower", "Middle", "Upper"), each = n_per_period),
  levels = c("Lower", "Middle", "Upper")  # chronological order, not alphabetical
)


# =============================================================================
# SECTION 2: RAW MATERIAL COMPOSITION
# =============================================================================
# WHY: raw material selection strategy is one of the best-documented changes
#      across the sequence. This variable drives the stacked bar
#      plot and provides a second chi-square example alongside platform_prep.
# ARCHAEOLOGICAL BASIS:
#   Lower  - bulk local material dominates (Quartzite), low diversity.
#            Mirrors Acheulian bulk-procurement patterns (Finkel et al. 2023).
#   Middle - the most EVEN mix of the three periods: multiple local/semi-local
#            materials exploited simultaneously, thin exotic component appears
#            (Bourguignon et al. 2008; Chiotti et al. 2018 - La Combette).
#   Upper  - one high-quality material dominant (Fine chert), PLUS a much
#            larger and more persistent exotic component (Obsidian) than
#            earlier periods, consistent with long-distance, quality-driven
#            procurement (Porraz et al. 2013; Negrino & Starnini 2025).
# INTERPRETATION: the shift is NOT simply "more trade over time" - it is
#      bulk-local -> diversified-local -> quality-and-exotic. Flag this
#      nuance explicitly with students; a naive reading risks implying
#      linear progress, which the literature does not support uniformly.

material_probs <- list(
  Lower  = c(Quartzite = 0.70, `Basic chert` = 0.25, `Fine chert` = 0.05, Obsidian = 0.00),
  Middle = c(Quartzite = 0.30, `Basic chert` = 0.35, `Fine chert` = 0.30, Obsidian = 0.05),
  Upper  = c(Quartzite = 0.10, `Basic chert` = 0.15, `Fine chert` = 0.55, Obsidian = 0.20)
)

# NOTE: map2() needs .x and .y to be the SAME length, because it makes one
# function call per pair of elements. We want exactly 3 calls total - one
# per period - each producing n_per_period draws, NOT 300 calls. So .x must
# be the 3 period names (not the already-expanded 300-row period vector)
# and .y must be the 3 sample sizes.
raw_material <- map2(
  c("Lower", "Middle", "Upper"),       # length 3: one call per period
  rep(n_per_period, 3),                # length 3: n for each of those calls
  \(per, n) sample(names(material_probs[[per]]), n,
                   replace = TRUE, prob = material_probs[[per]])
) |>
  unlist() |>  # concatenates the 3 length-100 results into one length-300 vector
  factor(levels = c("Quartzite", "Basic chert", "Fine chert", "Obsidian"))


# =============================================================================
# SECTION 3: PLATFORM PREPARATION
# =============================================================================
# WHY: this is the headline chi-square variable for 03-2. The association
#      with period is strong, directional, and mirrors a REAL significant
#      result reported in the literature (see citation below), so the test
#      result students get is not a simulation artefact - it replicates an
#      actual published finding.
# ARCHAEOLOGICAL BASIS:
#   Lower  - mostly Plain platforms, minimal preparation (simple flaking).
#   Middle - Faceted platforms become characteristic, used to control the
#            angle of blow for predetermined Levallois removals
#            (Ohnuma & Bergman, cited in Wadi Aghar platform study).
#   Upper  - shifts to Abraded/overhang removal as the dominant preparation
#            strategy, distinct from Middle Palaeolithic faceting.
# REAL-WORLD PRECEDENT: Shimelmitz et al. (2014, PLOS ONE) report a
#      significant chi-square association between platform type and
#      preparatory scarring in Yabrudian assemblages (chi^2 = 24.14, df = 1,
#      p < 0.0001) - the test we run below is the same KIND of result.
# INTERPRETATION: a significant chi-square tells us platform_prep and period
#      are NOT independent - knowing the period changes your best guess at
#      platform type. The standardized residual plot (Section 8) shows
#      WHICH period/platform combinations drive that association most.

platform_probs <- list(
  Lower  = c(Plain = 0.65, Faceted = 0.25, Abraded = 0.10),
  Middle = c(Plain = 0.20, Faceted = 0.65, Abraded = 0.15),
  Upper  = c(Plain = 0.15, Faceted = 0.25, Abraded = 0.60)
)

# NOTE: same map2() length rule as raw_material above - .x and .y must both
# be length 3 (one call per period), not length 300 and length 3.
platform_prep <- map2(
  c("Lower", "Middle", "Upper"),       # length 3: one call per period
  rep(n_per_period, 3),                # length 3: n for each of those calls
  \(per, n) sample(names(platform_probs[[per]]), n,
                   replace = TRUE, prob = platform_probs[[per]])
) |>
  unlist() |>
  factor(levels = c("Plain", "Faceted", "Abraded"))


# =============================================================================
# SECTION 4: MORPHOMETRICS (length, width, thickness, platform area)
# =============================================================================
# WHY: these four correlated variables feed BOTH the elongation ratio
#      (Section 5, the ANOVA/Tukey variable) AND the PCA (04-1). Generating
#      them as correlated multivariate normal data, rather than independently,
#      is essential - real flakes have correlated dimensions (bigger flakes
#      are wider AND thicker), and PCA only finds something interesting to
#      say when that real correlation structure is present.
# ARCHAEOLOGICAL BASIS:
#   Lower  - broad, robust, large flakes typical of simple/Acheulian core
#            reduction; LOW elongation (length close to width).
#   Middle - Levallois flakes are large relative to the core and elongate -
#            longer than wide (Wilkins & Chazan framing of Levallois product).
#   Upper  - prismatic blade technology: highest elongation of the sequence,
#            and (per Bustos-Perez et al. on Levallois standardization)
#            LOWER variance than earlier periods - blades are more
#            standardized than Lower Palaeolithic flakes.
# INTERPRETATION: watch the SD, not just the mean, when this is visualised -
#      the Upper Palaeolithic should look both more elongate AND more
#      tightly clustered than the Lower Palaeolithic.

lithic_corr <- matrix(c(
  1.00, 0.75, 0.55, 0.60,
  0.75, 1.00, 0.50, 0.55,
  0.55, 0.50, 1.00, 0.45,
  0.60, 0.55, 0.45, 1.00
), nrow = 4)

gen_morpho <- function(n, mu, sd_scale) {
  S <- diag(mu * 0.22 * sd_scale) %*% lithic_corr %*% diag(mu * 0.22 * sd_scale)
  raw <- mvrnorm(n, mu = mu, Sigma = S)
  raw[raw < 3] <- 3 + abs(rnorm(sum(raw < 3), 0, 0.4))  # floor at 3mm, no negatives
  raw
}

# mu order: length, width, thickness, platform (mm)
# Lower:  low elongation (L approx W), large, high variance (less standardised)
# Middle: rising elongation (Levallois), moderate variance
# Upper:  high elongation (blades), LOWEST variance (most standardised)
morpho_lower  <- gen_morpho(n_per_period, mu = c(46, 38, 13, 9),  sd_scale = 1.25)
morpho_middle <- gen_morpho(n_per_period, mu = c(50, 30, 10, 8),  sd_scale = 1.00)
morpho_upper  <- gen_morpho(n_per_period, mu = c(54, 21, 7,  6),  sd_scale = 0.70)

morpho <- rbind(morpho_lower, morpho_middle, morpho_upper)
colnames(morpho) <- c("length_mm", "width_mm", "thickness_mm", "platform_mm")


# =============================================================================
# SECTION 5: ELONGATION (derived ratio - the headline ANOVA/Tukey variable)
# =============================================================================
# WHY: elongation = length / width. This is the variable used for 03-2's
#      ANOVA and Tukey HSD. Because the underlying length/width means were
#      set deliberately (Section 4), this produces a clean three-step
#      staircase: Lower < Middle < Upper, with ALL THREE pairwise Tukey
#      comparisons significant - the ideal teaching case where the post-hoc
#      test feels necessary rather than procedural.
# INTERPRETATION: elongation rising across the sequence visualises the
#      textbook Lower-flake -> Middle-Levallois -> Upper-blade narrative
#      (Bar-Yosef & Kuhn 1999 on "the big deal about blades"). FLAG TO
#      STUDENTS: this is a simplification. Blade technology is documented
#      well before the Upper Palaeolithic in some regions (Eren et al. 2016),
#      and Levallois has Lower Palaeolithic Acheulian origins (winds-of-change
#      Levantine Acheulian evidence) - the clean staircase here is a
#      teaching model, not a claim that the transition is this tidy
#      everywhere in the real archaeological record.

elongation <- morpho[, "length_mm"] / morpho[, "width_mm"]
# we can compute this in the lesson


# =============================================================================
# SECTION 6: GIUR - Geometric Index of Unifacial Reduction (0-1 ratio scale)
# =============================================================================
# WHY: a continuous 0-1 ratio scale variable, modelled directly on Kuhn's
#      (1990) t/T retouch intensity index, so it behaves correctly as a PCA
#      input (PCA wants continuous variables, not awkward ordinal scales).
# ARCHAEOLOGICAL BASIS: GIUR = t/T, the ratio of retouched-edge thickness to
#      maximum tool thickness. Higher GIUR = more retouch/reduction has
#      occurred (Kuhn 1990; Hiscock & Clarkson 2005). Published means are
#      commonly in the 0.3-0.5 range, with >60% of heavily retouched
#      assemblages exceeding 0.5 (Eren & Sampson-style experimental studies).
# DESIGNED PATTERN (deliberately NON-monotonic, unlike elongation):
#   Lower  - low-moderate GIUR: simple flake tools, less curation.
#   Middle - HIGHEST GIUR: Middle Palaeolithic is "the age of secondary
#            retouch" (Meignen & Bar-Yosef framing), where retouch frequency,
#            intensity and coverage reach their apex.
#   Upper  - moderate GIUR, lower than Middle: retouch becomes more
#            DIVERSIFIED across many specialised tool types rather than
#            uniformly more intense on each piece.
# INTERPRETATION: this is the variable to use when teaching students that
#      not every trend in the data is a simple staircase. GIUR peaks in the
#      Middle and falls in the Upper - a genuinely different, non-linear
#      pattern compared to elongation's clean three-step rise. Good
#      discussion point: "why might MORE specialised tools NOT mean MORE
#      retouch per tool?"

giur_mu <- c(Lower = 0.28, Middle = 0.46, Upper = 0.35)
giur_sd <- c(Lower = 0.10, Middle = 0.09, Upper = 0.10)

giur <- map_dbl(as.character(period), \(p) {
  val <- rnorm(1, mean = giur_mu[[p]], sd = giur_sd[[p]])
  pmin(pmax(val, 0), 1)  # hard bounds at 0 and 1 - GIUR is a true proportion
})


# =============================================================================
# SECTION 7: WEIGHT (derived from morphometrics + raw material density)
# =============================================================================
# WHY: deriving weight from length*width*thickness*density rather than
#      simulating it independently keeps the dataset physically coherent -
#      bigger flakes really do weigh more, and material density differences
#      are real. This matters for the 03-1 scatterplot lesson, which should
#      show a believable, physically-grounded relationship, not noise.

density_lookup <- c(Quartzite = 2.7, `Basic chert` = 2.55,
                    `Fine chert` = 2.6, Obsidian = 2.4)
density <- density_lookup[as.character(raw_material)]

weight_g <- (morpho[, "length_mm"] * morpho[, "width_mm"] * morpho[, "thickness_mm"] / 1000) *
  density * runif(n_total, 0.18, 0.26)  # shape factor: flakes aren't cuboids
weight_g <- round(pmax(weight_g, 0.5), 2)


# =============================================================================
# SECTION 8: ASSEMBLE THE CLEAN TIBBLE (instructor reference only)
# =============================================================================
# This object is NEVER saved or shown to students directly. It exists only
# so the instructor can verify ideal statistical properties before the
# workshop (Section 10) and to derive the deliberately spoiled raw CSV
# (Section 9) that students actually receive.

lithics_clean <- tibble(
  artefact_id   = sprintf("ART-%04d", seq_len(n_total)),
  period        = period,
  raw_material  = raw_material,
  platform_prep = platform_prep,
  length_mm     = round(morpho[, "length_mm"], 1),
  width_mm      = round(morpho[, "width_mm"], 1),
  thickness_mm  = round(morpho[, "thickness_mm"], 1),
  platform_mm   = round(morpho[, "platform_mm"], 1),
  weight_g      = weight_g,
  elongation    = round(elongation, 3),
  giur          = round(giur, 3)
)


# =============================================================================
# SECTION 9: SPOIL THE DATA -> lithics_raw.csv (what students receive)
# =============================================================================
# WHY: real archaeological recording sheets are never this clean. Spoiling
#      the data deliberately - and in a CONTROLLED, REVERSIBLE way - lets
#      02-2 teach genuine data cleaning verbs on a dataset
#      students will then use for real inference later. Every
#      problem introduced here maps to an actual, common field-recording
#      error type, not an arbitrary obstacle.
#
# FOUR DELIBERATE PROBLEMS, each teaching a distinct cleaning verb:
#   (1) Units suffixed onto numbers           -> parse_number()
#   (2) Inconsistent whitespace                -> str_squish()
#   (3) Inconsistent capitalisation + 1 typo    -> str_to_lower() + case_when()
#   (4) Sentinel missing-value codes            -> na_if()
#   PLUS: genuine outlier/impossible rows        -> filter() after EDA

lithics_dirty <- lithics_clean

# --- Problem 1: units suffixed onto length and weight -----------------------
# WHY: field recording sheets and digital calipers often export with units
#      attached as text, turning a numeric column into a character column.
# Cleaning verb taught: parse_number() strips non-numeric characters and
#      coerces back to double in one step.
lithics_dirty <- lithics_dirty |>
  mutate(
    length_mm = paste0(length_mm, "mm"),
    weight_g  = paste0(weight_g, " g")
  )

# --- Problem 2: inconsistent whitespace in raw_material ---------------------
# WHY: copy-pasting between spreadsheet cells, or typing quickly in the
#      field, frequently introduces leading/trailing/double-internal spaces
#      that look identical to the eye but break exact-match filtering.
# Cleaning verb taught: str_squish() collapses internal whitespace and trims
#      leading/trailing space in one call.
set.seed(209)
whitespace_rows <- sample(seq_len(n_total), size = round(n_total * 0.15))
lithics_dirty$raw_material <- as.character(lithics_dirty$raw_material)
lithics_dirty$raw_material[whitespace_rows] <- paste0(
  "  ", lithics_dirty$raw_material[whitespace_rows], "  "
)
# inject a few double-internal-space cases specifically for "Basic chert" / "Fine chert"
double_space_rows <- sample(
  which(str_detect(str_trim(lithics_dirty$raw_material), "chert")),
  size = 10
)
lithics_dirty$raw_material[double_space_rows] <- str_replace(
  lithics_dirty$raw_material[double_space_rows], " ", "  "
)

# --- Problem 3: inconsistent capitalisation + one genuine typo --------------
# WHY: across a field season, multiple people enter data with different
#      capitalisation habits, and at least one typo is essentially
#      guaranteed in any real dataset of this size.
# Cleaning verb taught: str_to_lower() to normalise case, then case_when()
#      (or fct_recode()) as a lookup table to fix the genuine typo, which
#      lowercasing alone cannot solve.
set.seed(210)
upper_rows <- sample(seq_len(n_total), size = round(n_total * 0.10))
lithics_dirty$raw_material[upper_rows] <- str_to_upper(
  str_trim(lithics_dirty$raw_material[upper_rows])
)
# typo_rows <- sample(
#   which(str_detect(str_trim(str_to_lower(lithics_dirty$raw_material)), "^chert$") == FALSE &
#           str_detect(str_trim(str_to_lower(lithics_dirty$raw_material)), "chert")),
#   size = 6
# )
# lithics_dirty$raw_material[typo_rows] <- "chrt"  # the typo: "chrt" instead of "chert"-containing label
# NOTE: the typo deliberately collapses "Basic chert"/"Fine chert" distinction
# for these 6 rows - this is REALISTIC (a rushed field note just writes "chrt"
# without specifying which grade) and gives students a genuine judgment call:
# should these become NA, or be assigned to a category? Recommend NA in the
# teaching solution, with a class discussion on why guessing would be worse.

# --- Problem 4: sentinel missing-value codes ---------------------------------
# WHY: this is a DIFFERENT problem from units/whitespace - it is not a
#      formatting issue but a SEMANTIC one. A value can parse perfectly as a
#      number and still not be real data. Field forms commonly use "-999" or
#      a typed "N/A" inside what is otherwise a numeric column when an
#      artefact was too damaged/fragmented to measure.
# Cleaning verb taught: na_if() (or mutate(across(..., \(x) na_if(x, "-999")))
#      for converting sentinel codes to true NA, AFTER parse_number() has run
#      (since parse_number("-999") returns -999, a real-looking number).
set.seed(211)
sentinel_rows <- sample(seq_len(n_total), size = 8)
lithics_dirty$thickness_mm[sentinel_rows[1:4]] <- "-999"
lithics_dirty$platform_mm[sentinel_rows[5:8]]  <- "N/A"

# --- Outlier / impossible rows (for filter() practice) -----------------------
# WHY: distinct from the four problems above - these are not FORMATTING
#      errors but DATA ENTRY errors that produce physically impossible or
#      wildly implausible values. Teaches visual detection (boxplot) THEN
#      filter() as the remedy, modelling the real workflow: look, then act.
set.seed(212)
outlier_rows <- sample(seq_len(n_total), size = 4)
# row 1: decimal place error - 420mm "flake" is obviously a data entry slip
lithics_dirty$length_mm[outlier_rows[1]] <- "420.0mm"
# row 2: negative thickness - physically impossible, almost certainly a
#        sign error or transcription mistake from a damaged field notebook
lithics_dirty$thickness_mm[outlier_rows[2]] <- "-8.2"
# row 3: weight wildly inconsistent with recorded dimensions (likely
#        transposed with a different artefact's weight during entry)
lithics_dirty$weight_g[outlier_rows[3]] <- "850 g"
# row 4: GIUR outside the valid 0-1 range - someone entered a percentage
#        (e.g. "45" meaning 45%) instead of the proportion (0.45)
lithics_dirty$giur[outlier_rows[4]] <- 45


# =============================================================================
# SECTION 10: WRITE THE STUDENT-FACING RAW FILE
# =============================================================================

lithics_dirty_csv <- lithics_dirty |> dplyr::select(-elongation)
write_csv(lithics_dirty_csv, "data/lithics_raw.csv")


# =============================================================================
# SECTION 11: INSTRUCTOR VERIFICATION (run before the workshop, never shown)
# =============================================================================
# WHY: confirms the clean tibble has the ideal statistical properties this
#      workshop depends on, BEFORE the workshop begins. No cat()/print() -
#      every check below is a bare tibble/object evaluation, inspectable in
#      the RStudio environment pane or by knitting this script as a report.

verify_chisq_platform <- chisq.test(table(lithics_clean$period, lithics_clean$platform_prep))
verify_chisq_material <- chisq.test(table(lithics_clean$period, lithics_clean$raw_material))
verify_aov_elongation  <- aov(elongation ~ period, data = lithics_clean)
verify_tukey           <- TukeyHSD(verify_aov_elongation)

verify_summary <- tibble(
  check = c(
    "chisq platform_prep x period: all expected counts > 5",
    "chisq platform_prep x period: p-value",
    "chisq raw_material x period: p-value",
    "ANOVA elongation ~ period: p-value",
    "Tukey: all 3 pairs significant (TRUE expected)"
  ),
  result = c(
    all(verify_chisq_platform$expected > 5),
    verify_chisq_platform$p.value,
    verify_chisq_material$p.value,
    summary(verify_aov_elongation)[[1]][["Pr(>F)"]][1],
    all(verify_tukey$period[, "p adj"] < 0.05)
  )
)

verify_summary  # bare evaluation, not print() - visible in RStudio/Quarto output


# =============================================================================
# END OF INSTRUCTOR SCRIPT
# Students never see this file. They receive only lithics_raw.csv.
# =============================================================================




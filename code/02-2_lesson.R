# =============================================================================
# LESSON: 02-2 (Visualisation)
# =============================================================================
# LEARNING OBJECTIVES:
#   1. Build histograms, boxplots, and scatterplots with ggplot2
#   2. Apply brewer/viridis colour palettes correctly (never hardcoded colours)
#   3. See the Lower->Middle->Upper elongation trend directly, before any
#      formal statistical test is run - visualisation comes first, inference
#      second, which mirrors good archaeological practice generally
# =============================================================================

library(tidyverse)

lithics <- read_csv("data/lithics_clean.csv") |>
  mutate( # factor conversions control plot ordering. Without them, ggplot sorts alphabetically
    period = factor(period, 
                    levels = c("Lower", "Middle", "Upper")),
    raw_material  = factor(raw_material,
                    levels = c("Quartzite", "Basic Chert", "Fine Chert", "Obsidian")),
    platform_prep = factor(platform_prep, 
                           levels = c("Plain", "Faceted", "Abraded")))

# --- Histogram: elongation distribution by period ---------------------------
# WHY: a histogram shows DISTRIBUTION SHAPE, not just a single mean - this
#      matters here because we expect not just a shift in the centre of the
#      distribution across periods, but also a narrowing (lower variance) in
#      later periods, consistent with increasing standardisation of blade
#      production relative to earlier flake technologies.

ggplot(lithics) +  # start with basic histogram that we develop
  aes(x = elongation) + 
  geom_histogram() 

ggplot(lithics) + # develop the basic plot into more elaborate one
  aes(x = elongation, 
      fill = period) + 
  geom_histogram() +
  scale_fill_brewer(palette = "Dark2") +
  labs(x = "Elongation (length / width)", y = "Count", fill = "Period") +
  theme_minimal() # consider to show facet_wrap to improve

# INTERPRETATION: Upper Palaeolithic elongation values cluster in a
# narrower, higher range than Lower Palaeolithic values, which spread more
# widely around a lower centre. This is the FIRST visual hint of the
# flake -> Levallois -> blade technological trajectory, before any p-value
# has been computed. Bar-Yosef & Kuhn (1999) frame blade production as the
# defining laminar technology of this later trajectory.

# --- Barplot: elongation by period --- Raw material composition across periods
# =============================================================================
# WHY A STACKED BAR PLOT: this is fundamentally a COMPOSITIONAL question -
#      not "how many artefacts of each material exist" (which would be
#      sensitive to our arbitrary sample size choices) but "what PROPORTION
#      of each period's assemblage is made of each material." Converting
#      counts to within-period proportions BEFORE plotting is what makes
#      this a fair compositional comparison across periods of equal sample
#      size here, and would remain fair even if period sample sizes differed
#      in a real dataset.
# ARCHAEOLOGICAL BASIS: this is NOT a simple "more trade over time" story.
#      Lower Palaeolithic = bulk local material (low diversity). Middle
#      Palaeolithic = the MOST diverse/even mix of local and semi-local
#      materials (Bourguignon et al. on La Combette provisioning). Upper
#      Palaeolithic = one quality material dominant PLUS a much larger
#      persistent exotic component than earlier periods (long-distance,
#      quality-driven procurement). The pattern is bulk-local ->
#      diversified-local -> quality-and-exotic, not a linear increase in
#      "trade."

ggplot(lithics) + # basic barplot to setup for hypothesis test in next lesson
  aes(x = period,  
      fill = platform_prep)  +
  geom_bar()

ggplot(lithics) + # develop the basic barplot into a more polished plot
  aes(x = period,  
      fill = raw_material) +
  geom_bar() +
  scale_fill_viridis_d(option = "D") +
  labs(x = "Period", y = "Count", fill = "Raw material")

# INTERPRETATION: Lower Palaeolithic shows one colour band (Quartzite)
# dominating most of the bar. Middle Palaeolithic shows the most EVEN split
# across three-to-four colour bands - the most compositionally diverse
# period. Upper Palaeolithic shows one band (Fine Chert) dominant again,
# but with a visible, persistent Obsidian band that barely existed in
# earlier periods - this is the "exotic component" the literature
# documents, not simply "more of everything."

# --- Boxplot: elongation by period -------------------------------------------
# WHY: boxplots make the period-to-period SHIFT IN MEDIAN easier to compare
#      at a glance than a histogram does, at the cost of hiding some
#      distributional detail the histogram showed. Showing both is
#      deliberate - no single plot type tells the whole story.
ggplot(lithics) + # basic boxplot, can add ggbeeswarm
  aes(x = period, 
      y = elongation) +
  geom_boxplot() +
  theme_minimal()

# INTERPRETATION: if the three boxes barely overlap, that is a strong visual
# clue an ANOVA run on this variable will return a small p-value - the
# formal test in Lesson 2 confirms what the eye already suspects here.

# --- Scatterplot: length vs weight, coloured by raw material ----------------
# WHY: scatterplots reveal RELATIONSHIPS BETWEEN two continuous variables -
#      here, confirming that weight increases with length as physically
#      expected, while colour by raw_material shows whether different
#      materials occupy different regions of that relationship (e.g.
#      denser quartzite producing heavier flakes at a given length).

ggplot(lithics) + # basic scatterplot that we develop
  aes(x = length_mm,
      y = weight_g) +
  geom_point() 

ggplot(lithics) + # more elaborate scatterplot
  aes(x = length_mm,
      y = weight_g, 
      colour = raw_material) +
  geom_point(alpha = 0.6) +
  scale_colour_brewer(palette = "Set1") +
  labs(x = "Length (mm)", y = "Weight (g)", colour = "Raw material") +
  theme_minimal()  # consider to show facet_wrap to improve 

# INTERPRETATION: the positive length-weight relationship is expected and
# physically necessary (bigger flakes weigh more) 


# =============================================================================
# LESSON: 04-1 (Multivariate methods: composition + PCA)
# =============================================================================
# LEARNING OBJECTIVES:
#   1. Visualise compositional change across periods using a stacked bar plot
#   2. Understand PCA as a way to view many correlated variables at once
#   3. Run and interpret a PCA biplot using FactoMineR + factoextra
#   4. Connect PC1/PC2 loadings back to archaeological meaning (size vs shape)
# =============================================================================

library(tidyverse)
library(FactoMineR)
library(factoextra)

lithics <- read_csv("data/lithics_clean.csv") |>
  mutate(
    period       = factor(period, 
                          levels = c("Lower", "Middle", "Upper")))

library(GGally)
ggpairs(lithics, # we have too many variables to easily interpret, we need 
        columns = 3:11, # to reduce the dimensionality to help with interpretation. 
        ggplot2::aes(colour = period))

# =============================================================================
# Principal Component Analysis
# =============================================================================
# WHY PCA: we have FIVE correlated morphometric variables per artefact
#      (length, width, thickness, platform, weight). We cannot plot five
#      dimensions at once. PCA finds the 2D view of this 5D data that
#      preserves as much of the real variation as possible - it is a tool
#      for SEEING multivariate structure, not a black box.

pca_vars <- lithics |>
  dplyr::select(length_mm, 
                width_mm, 
                thickness_mm, 
                platform_mm, 
                weight_g,
                period) |>
  drop_na()  # PCA cannot handle missing values 

# WHY scale.unit = TRUE: weight (grams, range roughly 1-50) and length
#      (millimetres, range roughly 15-80) are on completely different
#      scales. Without standardising, PCA would be dominated by whichever
#      variable happens to have the largest numeric range, not whichever
#      variable is most archaeologically informative. scale.unit = TRUE
#      puts all five variables on a comparable footing before finding
#      principal components.
pca_fit <- PCA(pca_vars |> dplyr::select(-period),
               scale.unit = TRUE, 
               graph = FALSE)

# --- Scree plot: how many components are worth looking at? ------------------
# WHY: before interpreting PC1/PC2, confirm they actually capture most of
#      the meaningful variation. If PC1+PC2 explain well over half the
#      total variance, focusing on just those two is justified.
fviz_eig(pca_fit, addlabels = TRUE) +
  scale_fill_viridis_d(option = "D") +
  labs(x = "Principal component",
       y = "Percentage of variance explained")

# INTERPRETATION: expect PC1 alone to explain a large share of variance
# (likely 50-65%) because length, width, thickness, platform, and weight
# are all positively correlated with overall artefact SIZE. PC2 should
# explain a meaningfully smaller but still useful share - this is where
# SHAPE (elongation-type variation) rather than size will appear.


# --- Variable contributions: what does PC1 vs PC2 actually represent? -------
# WHY: principal components are not raw variables - they are WEIGHTED
#      COMBINATIONS of the original variables. Looking at which variables
#      contribute most to each component is how we give PC1/PC2 an
#      archaeological NAME rather than leaving them as anonymous axes.
fviz_contrib(pca_fit, choice = "var", axes = 1) +
  scale_fill_viridis_c(option = "D")

fviz_contrib(pca_fit, choice = "var", axes = 2) +
  scale_fill_viridis_c(option = "D")

# INTERPRETATION: expect length, width, thickness, and weight to all
# contribute strongly and roughly equally to PC1 - this is why PC1 can be
# read as a general "SIZE" axis. Expect platform_mm and the LENGTH/WIDTH
# BALANCE specifically to load more distinctly on PC2 - read PC2 as a
# "SHAPE/ELONGATION" axis, separate from overall size. Naming the axes from
# their loadings, rather than from the plot's appearance alone, is the
# archaeologist's interpretive job - the computer only finds the maths.


# --- The biplot itself, coloured by period -----------------------------------
# WHY COLOUR BY PERIOD (not raw_material): the central pedagogical claim of
#      this whole workshop is that PERIOD is the dominant organising
#      variable. Colouring the biplot by period directly tests that claim -
#      if periods separate cleanly along PC2 (the shape axis) specifically,
#      that is strong multivariate confirmation of the elongation trend
#      already seen in 03-2, now visible simultaneously across
#      ALL FIVE morphometric variables at once rather than one at a time.
fviz_pca_biplot(
  pca_fit,
  habillage = pca_vars$period,  # align after drop_na()
  addEllipses = TRUE,
  label = "var",
  repel = TRUE) +
  scale_colour_brewer(palette = "Dark2") +
  scale_fill_brewer(palette = "Dark2") +
  labs(x = NULL, y = NULL, colour = "Period", fill = "Period", shape = "Period")

# INTERPRETATION: points (individual artefacts) separate primarily ALONG
# PC2 by period - Lower Palaeolithic artefacts cluster toward one end,
# Upper Palaeolithic toward the other, Middle Palaeolithic between them -
# while ALL THREE periods overlap substantially along PC1. This is the
# correct and archaeologically meaningful pattern: periods do NOT differ
# mainly in overall SIZE (PC1), they differ mainly in SHAPE/elongation
# (PC2) - exactly consistent with the flake -> Levallois -> blade
# narrative, now confirmed multivariately rather than through a single
# ratio variable in isolation. The variable loading ARROWS pointing in
# similar directions (length, width, thickness, weight all clustering
# toward PC1) versus the platform/elongation-related loadings pointing
# more toward PC2 is what visually JUSTIFIES calling PC1 "size" and PC2
# "shape" - the arrows and the point separation tell a single, consistent
# archaeological story together.
#
# CAUTION FOR DISCUSSION: clean ellipse separation here partly reflects
# how tightly this teaching dataset was constructed. Real assemblages
# typically show more overlap between adjacent periods, and the
# Lower-Middle-Upper boundary itself is a research convenience, not a
# sharp line in the actual archaeological record.

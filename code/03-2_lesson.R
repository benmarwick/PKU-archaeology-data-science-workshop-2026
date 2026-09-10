# =============================================================================
# LESSON: 03-2 (Multivariate methods: composition + PCA)
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
library(vegan)
library(GGally)
library(pairwiseAdonis)
library(WdStar)

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

# Explicit scaling: puts all five morphometric variables on comparable
# footing (mean = 0, sd = 1). This is what PCA's scale.unit = TRUE does
# internally, but doing it here gives us the scaled matrix for PERMANOVA.
pca_scaled <- pca_vars |>
  dplyr::select(-period) |>
  scale()  # returns matrix with center/scale attributes

# WHY scale.unit = TRUE: weight (grams, range roughly 1-50) and length
#      (millimetres, range roughly 15-80) are on completely different
#      scales. Without standardising, PCA would be dominated by whichever
#      variable happens to have the largest numeric range, not whichever
#      variable is most archaeologically informative. scale.unit = TRUE
#      puts all five variables on a comparable footing before finding
#      principal components.
pca_fit <- PCA(pca_scaled, 
               graph = FALSE)

# --- Scree plot: how many components are worth looking at? ------------------
# WHY: before interpreting PC1/PC2, confirm they actually capture most of
#      the meaningful variation. If PC1+PC2 explain well over half the
#      total variance, focusing on just those two is justified.
fviz_eig(pca_fit, addlabels = TRUE) +
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
fviz_contrib(pca_fit, choice = "var", axes = 1) 
fviz_contrib(pca_fit, choice = "var", axes = 2) 

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
#      already seen in 03-1, now visible simultaneously across
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

# --- PERMANOVA: test for period differences in morphometric space -------
# WHY: PERMANOVA tests whether group centroids (periods) differ significantly
#      in multivariate space. Unlike ANOVA, it makes no distributional
#      assumptions and is ideal for ecological/morphological data. A
#      significant result indicates that at least one period has a different
#      average morphology in the PC space.
# ARCHAEOLOGICAL PRECEDENT: widely used in lithic analysis to test for
#      technological differences between assemblages (e.g., Sharon 2007;
#      Beaumont & Vogel 2006).

# Run PERMANOVA with 999 permutations
set.seed(123)  # for reproducibility 
perm_test <- adonis2(pca_scaled ~ pca_vars$period, 
                     method = "euclidean",
                     permutations = 999)
perm_test  # report pseudo-F, R², df, and p-value

# INTERPRETATION: pseudo-F = 79.142, R² = 0.357, p = 0.001 indicates
#    that period explains 35.7% of the total variation in morphometric
#    space - a highly significant result. This confirms what the biplot
#    shows visually: the three periods DO occupy different regions of
#    multivariate morphospace. The R² of 0.357 is archaeologically
#    meaningful - period is not merely a statistically significant but
#    also a substantial driver of morphological variation. 

# Post-hoc pairwise PERMANOVA if omnibus significant
pairwise.adonis(pca_scaled,
                pca_vars$period,
                sim.method = "euclidean")
  
#. betadisper Implementation (permdist)
# --- betadisper: test for homogeneity of dispersions -------------------
# WHY: PERMANOVA assumes similar dispersion (variance) across groups.
#      betadisper tests this assumption. If significant, PERMANOVA
#      results may be misleading as they could reflect dispersion
#      differences rather than location differences.
# NOTE: This checks the PERMANOVA assumption of homogeneity of
#       multivariate spreads (analogous to Levene's test in ANOVA).

# Calculate betadisper on Euclidean distances
dist_matrix <- dist(pca_scaled, method = "euclidean")
bd_test <- betadisper(dist_matrix, pca_vars$period)
bd_test 

# Test significance of dispersion differences
permutest(bd_test, pairwise = TRUE, permutations = 999)

# INTERPRETATION: significant betadisper (p < 0.05). Significant result 
# suggests PERMANOVA may be detecting dispersion rather than location differences.

# Wd* test (Hamidi et al. 2019) as a multivariate Welch ANOVA robust to dispersion differences.
# Accounts for heteroscedasticity (unequal variances) across groups using permutation testing.
# Provides an effect size (ω²) alongside the test statistic.
# Running both WdS.test and betadisper provides a robustness check - if both are significant,
# the dispersion difference is not an artifact of a single method.
WdS.test(dist_matrix, pca_vars$period)

# INTERPRETATION: WdS.test is significant (WdS = 85.674, p = 0.001, ω² = 0.37)
# indicating significant LOCATION differences between periods (multivariate
# centroid shifts), robust to unequal dispersions. The ω² effect size of
# 0.37 indicates that period explains 37% of the multivariate variation -
# a very substantial effect. betadisper (F = 42.807, p < 0.001) shows
# dispersion is NOT homogeneous across periods, while WdS.test confirms
# location differences remain significant despite this heteroscedasticity.
# This robustness means the PERMANOVA location effect is real and not
# an artifact of dispersion differences. Lower Palaeolithic artefacts
# (average distance 2.086) are more variable than Upper Palaeolithic
# (0.933), consistent with the archaeological expectation that early
# technologies show greater diversity as they develop standardized approaches.


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

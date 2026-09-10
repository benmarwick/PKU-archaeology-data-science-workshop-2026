# =============================================================================
# LESSON: 03-1 (Statistical Inference)
# =============================================================================
# LEARNING OBJECTIVES:
#   1. Use geom_count() correctly for an EDA check before a formal test
#   2. Run and interpret a chi-square test of independence, then diagnose
#      WHICH cells drive the association using standardized residuals
#      visualised with ggcorrplot
#   3. Run ANOVA + Tukey HSD, then visualise the pairwise comparisons as a
#      tidy forest plot using broom::tidy() + geom_pointrange()
# =============================================================================

library(ggcorrplot)
library(broom)
library(car)
library(FSA) 

# --- Chi-square test: platform_prep x period ---------------------------------
# WHY: tests whether platform preparation strategy and period are
#      INDEPENDENT. A small p-value means knowing the period genuinely
#      changes your best guess at platform type - i.e. platform preparation
#      strategy is not random with respect to time period.
chi_sq_test <- chisq.test(table(lithics$period, lithics$platform_prep))

# ASSUMPTION CHECK: Expected counts
chi_sq_test$expected  # all cells should have expected ≥ 5

chi_sq_test # report chi-square statistic, df, and p-value here. 

# A p-value below 0.05 (expected: well below it, by design) means we reject
# the null hypothesis that platform_prep is independent of period.

# WHY STANDARDIZED, NOT RAW, RESIDUALS: chisq.test()$residuals returns
#      PEARSON residuals, which are not directly comparable across cells
#      with different expected counts. chisq.test()$stdres returns
#      STANDARDIZED residuals, which ARE comparable across cells and can be
#      read against the familiar +-1.96 / +-2.58 thresholds (roughly
#      p < 0.05 / p < 0.01 for that individual cell). For a teaching context
#      where students will visually compare circle sizes/colours across
#      cells, standardized residuals are the statistically correct choice -
#      using raw Pearson residuals here would risk teaching students to
#      misread cell-level importance.
ggcorrplot(chi_sq_test$stdres, # Diagnosing WHICH cells drive the association
           method = "circle") +
  scale_fill_distiller(
    palette = "RdBu",
    name = "Std. residual"
  )

# INTERPRETATION: cells with large positive standardized residuals
# (strongly red or blue depending on direction, per the diverging palette)
# are observed MORE often than chance in that period/platform combination;
# large negative residuals mean LESS often than chance. Expect Lower/Plain
# and Middle/Faceted and Upper/Abraded to show the largest positive
# residuals - these are the specific cells driving the overall significant
# chi-square result, which is archaeologically the most useful information
# the test provides: not just "they differ" but "here is exactly how."

# --- Does elongation differ by period? --------------------------------

# WHY: Kruskal-Wallis is a non-parametric alternative to ANOVA when
#      assumptions are violated. It tests whether AT LEAST ONE period's
#      distribution of elongation differs from the others - not which ones.
#      Post-hoc Dunn's test identifies specific pairwise differences.

# ASSUMPTION CHECK: ANOVA assumes equality of variance, normality of residuals

# Homogeneity (Levene's test, robust to non-normality):  Variances are equal across groups? if  p-value > 0.05 then yes, assumptions met
leveneTest(elongation ~ period, data = lithics, center = median)

# Normality (Shapiro-Wilk on residuals), Residuals are normally distributed? if p-value > 0.05 (e.g., 0.212): Assumptions met - data appears normal
shapiro.test(residuals(fit))

# If the assumptions are not met, we could:
# - non-normal residuals: log transform the response:
# - unequal variances: use robust methods (Kruskall test)

# Kruskal-Wallis test (non-parametric alternative to ANOVA)
kw_test <- kruskal.test(elongation ~ period, data = lithics)
tidy(kw_test) # report F statistic, df, and p-value here. 

# INTERPRETATION: a small p-value for the Kruskal-Wallis test means
# elongation distributions differ across periods. Dunn's test identifies
# which specific pairwise comparisons are significant.

# --- Dunn's test, visualised as a tidy forest plot ---------------------------

  # WHY THIS VISUALISATION: Dunn's test requires manual tidiest because
  # dunnTest() returns results in a non-standard format. Tidy conversion
  # creates a data frame suitable for ggplot2: each row is a pairwise
  # comparison with Z statistic, p-value, and significance indicator.

# Dunn's test for post-hoc comparisons (equivalent to Tukey HSD)
dunn_result <- dunnTest(elongation ~ period, data = lithics, method = "bonferroni")

dunn_tidy <- dunn_result$res |>
  mutate(
    contrast = Comparison,
    estimate = Z,  # Use Z statistic as effect size
    # Approximate 95% CI: Z ± 1.96 (since Z~N(0,1) under null)
    conf.low = Z - 1.96,
    conf.high = Z + 1.96,
    significant = P.adj < 0.05
  )

dunn_tidy |>
  ggplot() +
  aes(x = fct_reorder(contrast, estimate), 
      y = estimate) +
  geom_pointrange(aes(ymin = conf.low, 
                      ymax = conf.high, 
                      colour = significant)) +
  geom_hline(yintercept = 0, 
             linetype = "dashed") +
  scale_colour_brewer(palette = "Set1") +
  coord_flip() +
  labs(x = NULL, 
       y = "Z statistic (Dunn's test)", 
       colour = "p adj < 0.05") +
  theme_minimal()

# INTERPRETATION: by design, ALL THREE pairwise comparisons (Lower-Middle,
# Middle-Upper, Lower-Upper) should sit clearly away from the dashed zero
# line and be coloured as significant. This is the ideal teaching case:
# every pair differs, so the post-hoc test earns its place in the workflow
# rather than feeling like an unnecessary extra step after an already-
# significant Kruskal-Wallis. Archaeologically, this confirms the staircase
# narrative - flake elongation increases at EVERY transition in the
# sequence, not just from Lower to Upper while Middle sits ambiguously
# between the two.
#
# CAUTION FOR DISCUSSION: this clean three-step result is a feature of how
# this teaching dataset was deliberately constructed, not a claim that real
# Palaeolithic assemblages always show such a tidy staircase. Levallois
# technology has documented Lower Palaeolithic Acheulian origins, and blade
# technology appears well before the Upper Palaeolithic in some regions -
# the real record is messier than this lesson's data. Flag this explicitly
# with students as the "textbook model vs research reality" discussion.

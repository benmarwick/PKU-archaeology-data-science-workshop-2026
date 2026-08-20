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

# --- Chi-square test: platform_prep x period ---------------------------------
# WHY: tests whether platform preparation strategy and period are
#      INDEPENDENT. A small p-value means knowing the period genuinely
#      changes your best guess at platform type - i.e. platform preparation
#      strategy is not random with respect to time period.
# ARCHAEOLOGICAL PRECEDENT: this mirrors a REAL significant finding -
#      Shimelmitz et al. (2014, PLOS ONE) report chi^2 = 24.14, df = 1,
#      p < 0.0001 for platform type vs preparatory scarring in Yabrudian
#      assemblages. The test below is the same KIND of result, not a
#      simulation artefact invented for this workshop.
chi_sq_test <- chisq.test(table(lithics$period, lithics$platform_prep))
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

# --- ANOVA: does elongation differ by period? --------------------------------
# WHY: ANOVA tests whether AT LEAST ONE period's mean elongation differs
#      from the others. It does NOT tell us WHICH periods differ from which
#      - that is what Tukey HSD (next step) is for. Running ANOVA first and
#      Tukey second mirrors the correct statistical workflow: omnibus test,
#      then post-hoc.
fit <- aov(elongation ~ period, data = lithics)
tidy(fit) # report F statistic, df, and p-value here. 

# INTERPRETATION: a small p-value for the period term means elongation is
# NOT the same across all three periods - but on its own this result cannot
# tell us whether Lower differs from Middle, Middle from Upper, or only
# Lower from Upper. That ambiguity is exactly why Tukey HSD is necessary,
# not merely procedural.

# --- Tukey HSD, visualised as a tidy forest plot -----------------------------
# WHY THIS VISUALISATION: TukeyHSD()'s default plot() method is functional
#      but visually crude. Piping through broom::tidy() converts the test
#      result into a tidy data frame (one row per pairwise comparison),
#      which can then be visualised with the full ggplot2 toolkit - here, a
#      forest plot using geom_pointrange() shows each pairwise difference
#      AND its confidence interval simultaneously, with colour distinguishing
#      significant from non-significant comparisons at a glance.
fit |>
  TukeyHSD() |>
  tidy() |>
  ggplot() +
  aes(x = fct_reorder(contrast, estimate), 
      y = estimate) +
  geom_pointrange(aes(ymin = conf.low, 
                      ymax = conf.high, 
                      colour = adj.p.value < 0.05)) +
  geom_hline(yintercept = 0, 
             linetype = "dashed") +
  scale_colour_brewer(palette = "Set1") +
  coord_flip() +
  labs(x = NULL, 
       y = "Difference in mean elongation", 
       colour = "p adj < 0.05") +
  theme_minimal()

# INTERPRETATION: by design, ALL THREE pairwise comparisons (Lower-Middle,
# Middle-Upper, Lower-Upper) should sit clearly away from the dashed zero
# line and be coloured as significant. This is the ideal teaching case:
# every pair differs, so the post-hoc test earns its place in the workflow
# rather than feeling like an unnecessary extra step after an already-
# significant ANOVA. Archaeologically, this confirms the staircase
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

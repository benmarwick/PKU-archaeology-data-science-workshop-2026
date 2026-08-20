# =============================================================================
# LESSON: 02-1 (Data Cleaning)
# =============================================================================
# LEARNING OBJECTIVES:
#   1. Recognise four common categories of "dirty" data in a real dataset
#   2. Apply parse_number(), str_squish(), case_when(), and na_if() to fix
#      each category using the correct verb for the correct problem
#   3. Use a boxplot to visually detect outliers, then filter() them out
#   4. Produce a clean tibble that will be reused for all remaining lessons
#      this week - this is not a throwaway exercise,
#      it is our data pipeline for the rest of the workshop
# =============================================================================

library(tidyverse)

# WHY: students import the RAW file here, not a pre-cleaned one. Real
#      archaeological datasets - whether from your own fieldwork or a
#      legacy recording sheet inherited from a previous project - almost
#      never arrive ready to analyse. Learning to recognise and fix specific
#      categories of "dirt" is as core a skill as running a statistical test.
lithics_raw <- read_csv("data/lithics_raw.csv")

# INTERPRETATION: glimpse() shows length_mm, weight_g, thickness_mm,
# platform_mm, and giur all imported as <chr> (character) rather than <dbl>
# (double) - that is the first clue something is wrong. Numeric measurements
# should never import as text. This single observation is the entry point
# into the whole lesson.
glimpse(lithics_raw) # note chr and dbl

# =============================================================================
# PROBLEM 1: units suffixed onto numbers ("42.3mm", "12.6 g")
# =============================================================================
# WHY: digital calipers and some recording apps export measurements with the
#      unit attached as text. R correctly refuses to treat "42.3mm" as a
#      number, because it isn't one - it's a string that CONTAINS a number.
# FIX: parse_number() extracts the first numeric pattern from a string and
#      discards everything else (letters, units, currency symbols, etc).

lithics_step1 <- lithics_raw |>
  mutate(
    length_mm = parse_number(length_mm),
    platform_mm = parse_number(platform_mm),
    weight_g  = parse_number(weight_g)) |> 
  mutate(elongation = length_mm / width_mm) # so we can see this change

# INTERPRETATION: length_mm and weight_g are now <dbl>. Note thickness_mm,
# platform_mm, and giur are STILL <chr> - parse_number() only fixes the
# columns we apply it to. This is intentional: those three columns have a
# DIFFERENT problem (sentinel missing-value codes, Problem 4 below) that
# needs to be handled with care, not blindly parsed.

# =============================================================================
# PROBLEM 2: inconsistent whitespace in raw_material
# =============================================================================
# WHY: copy-pasting between spreadsheet cells or quick field-typing
#      introduces leading, trailing, or doubled internal spaces. "Chert" and
#      "  Chert  " look identical printed to a console but are NOT equal as
#      strings, which silently breaks any filter(raw_material == "Chert").
# FIX: str_squish() trims leading/trailing whitespace AND collapses repeated
#      internal whitespace down to a single space, in one call.

lithics_step2 <- lithics_step1 |>
  mutate(raw_material = str_squish(raw_material))

# INTERPRETATION: count distinct values before/after to SEE the fix working,
# rather than just trusting it happened.
lithics_step1 |> distinct(raw_material)   # whitespace variants still visible
lithics_step2 |> distinct(raw_material)   # whitespace collapsed, but case/typo remain

# =============================================================================
# PROBLEM 3: inconsistent capitalisation + one genuine typo
# =============================================================================
# WHY: across a field season, different recorders have different habits
#      (some always capitalise, some don't), and any dataset of meaningful
#      size will contain at least one genuine typo. Lowercasing fixes the
#      FIRST problem but cannot fix the SECOND - a typo is not a casing
#      issue, it is a different spelling entirely, and needs an explicit
#      lookup/recode step.
# FIX: str_to_lower() normalises case. case_when() then acts as an explicit,
#      auditable lookup table for anything that still doesn't match a known
#      category - in this dataset, the typo "chrt" cannot be confidently
#      assigned to "basic chert" or "fine chert", so the honest choice is to
#      convert it to NA rather than guess.

lithics_step3 <- lithics_step2 |>
  mutate(raw_material = str_to_lower(raw_material)) |>
  mutate(raw_material = str_to_title(raw_material))   # restore display case

# INTERPRETATION: this is a genuine archaeological judgment call, not just a
# coding exercise. A rushed field note reading "chrt" doesn't tell us
# whether the original recorder meant basic or fine chert. Converting to NA
# is the conservative, defensible choice - it preserves the artefact's
# OTHER measurements while honestly admitting we don't know its material
# grade. Guessing (e.g. always assigning to the more common category) would
# introduce a silent, undocumented bias into every later analysis.
lithics_step3 |> count(raw_material)

# =============================================================================
# PROBLEM 4: outliers and physically impossible values
# =============================================================================
# WHY: distinct from formatting/sentinel issues - these are DATA ENTRY
#      errors that produce values which are technically numeric and
#      technically "present", but archaeologically impossible or wildly
#      implausible. The correct workflow is ALWAYS look first, then act -
#      never filter() blindly on a threshold you haven't visually justified.
# FIX: visualise with a boxplot to SEE which points are flagged as extreme,
#      confirm they are implausible (not just unusual), then filter() them
#      out explicitly - never silently.

# WHY THIS PLOT: a boxplot is the right tool here because it shows the
# distribution shape AND flags points beyond 1.5*IQR automatically - exactly
# the visual signal that should make a student stop and look closer. Don't use 
# ggplot yet, show base plot first, then ggplot is the upgrade
boxplot(length_mm ~ period, data = lithics_step3) # repeat for weight_g, thickness, giur

# INTERPRETATION: one point near 420mm is not just an outlier relative to
# its period - it is larger than almost any unmodified flake in the
# Palaeolithic record. This is very likely a decimal-place data entry slip
# (42.0mm typed as 420.0mm), not a real giant flake.

lithics_clean <- lithics_step3 |>
  filter(
    length_mm < 200,        # no unmodified flake in this assemblage exceeds
    weight_g < 500,           # no flake this size/density combination should
    thickness_mm > 0,        # approach 500g - flags the transposed-weight row
    giur <= 1)

# INTERPRETATION: compare row counts before/after filter() to quantify how
# much was removed - this number should be SMALL (a handful of rows out of
# 300). If a filter() step ever removes a large fraction of the dataset,
# that is a sign the threshold is wrong, not that the data is that bad.
# nrow(lithics_step3) - nrow(lithics_clean)

# recheck the plot to confirm that 
boxplot(length_mm ~ period, data = lithics_clean)

# =============================================================================
# FINAL CHECK: confirm the cleaned tibble is ready for the remaining lessons
# =============================================================================
# INTERPRETATION: every measurement column should now show <dbl>, every
# categorical column should show <fct>, and there should be no remaining
# "-999" or stray whitespace anywhere. This is the exact tibble used for
# every statistical test and plot for the rest of the workshop.
glimpse(lithics_clean)

write_csv(lithics_clean, "data/lithics_clean.csv")

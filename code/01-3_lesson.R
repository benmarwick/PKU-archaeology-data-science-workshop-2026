# =============================================================================
# LESSON: 01-3 (Quarto)
# =============================================================================
# LEARNING OBJECTIVES:
#   1. Quarto file - text, code block, inline R code 
#   2. code execution options, echo, eval, warning: false 
#   3. import data, inspect with glimpse(), head().
#   4. output formats, YAML, captions and crossref for figures

# Assignment: screenshot of HTML output of quarto document that includes your name, code to import the data, code to inspect it with glimpse() and head(), and inline R code that shows how many artefacts are in our data set, and one sentence to describe any unexpected issues you see with our data.


# ---
#   title: "Untitled"
# format: html
# author: "Ben Marwick"
# execute: 
#   warning: false
# ---
#   
#   ```{r}
# library(tidyverse)
# my_data <- read_csv("data/lithics_raw.csv")
# 
# glimpse(my_data)
# ```
# 
# 
# There are `r nrow(my_data)` artefacts in our data.
#
# Some variables are stored as character, but need to be numeric.
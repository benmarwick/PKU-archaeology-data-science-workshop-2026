
# LESSON: 02-1 (Data Cleaning)

library(tidyverse)

lithics_raw <- read_csv("data/lithics_raw.csv")

glimpse(lithics_raw) # note chr and dbl

lithics_step1 <- lithics_raw |>
  mutate(
    length_mm = parse_number(length_mm),
    platform_mm = parse_number(platform_mm),
    weight_g  = parse_number(weight_g)) |> 
  mutate(elongation = length_mm / width_mm) # so we can see this change

lithics_step2 <- lithics_step1 |>
  mutate(raw_material = str_squish(raw_material))

lithics_step1 |> distinct(raw_material)   # whitespace variants still visible
lithics_step2 |> distinct(raw_material)   # whitespace collapsed, but case/typo remain

lithics_step3 <- lithics_step2 |>
  mutate(raw_material = str_to_lower(raw_material)) |>
  mutate(raw_material = str_to_title(raw_material))   # restore display case

lithics_step3 |> count(raw_material)

boxplot(length_mm ~ period, data = lithics_step3) # repeat for weight_g, thickness, giur

lithics_clean <- lithics_step3 |>
  filter(
    length_mm < 200,        # no unmodified flake in this assemblage exceeds
    weight_g < 500,           # no flake this size/density combination should
    thickness_mm > 0,        # approach 500g - flags the transposed-weight row
    giur <= 1)

boxplot(length_mm ~ period, data = lithics_clean)

glimpse(lithics_clean)

write_csv(lithics_clean, "data/lithics_clean.csv")


# LESSON: 02-2 (Visualisation)

library(tidyverse)

lithics <- read_csv("data/lithics_clean.csv") |>
  mutate( # factor conversions control plot ordering. Without them, ggplot sorts alphabetically
    period = factor(period, 
                    levels = c("Lower", "Middle", "Upper")),
    raw_material  = factor(raw_material,
                    levels = c("Quartzite", "Basic Chert", "Fine Chert", "Obsidian")),
    platform_prep = factor(platform_prep, 
                           levels = c("Plain", "Faceted", "Abraded")))

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

ggplot(lithics) + # basic boxplot, can add ggbeeswarm
  aes(x = period, 
      y = elongation) +
  geom_boxplot() +
  theme_minimal()

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


# LESSON: 03-1 (Statistical Inference)

library(ggcorrplot)
library(broom)

chi_sq_test <- chisq.test(table(lithics$period, lithics$platform_prep))

chi_sq_test # report chi-square statistic, df, and p-value here. 

ggcorrplot(chi_sq_test$stdres, # Diagnosing WHICH cells drive the association
           method = "circle") +
  scale_fill_distiller(
    palette = "RdBu",
    name = "Std. residual"
  )

fit <- aov(elongation ~ period, data = lithics)

tidy(fit) # report F statistic, df, and p-value here. 

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


# LESSON: 03-2 (Multivariate methods: composition + PCA)

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

pca_vars <- lithics |>
  dplyr::select(length_mm, 
                width_mm, 
                thickness_mm, 
                platform_mm, 
                weight_g,
                period) |>
  drop_na()  # PCA cannot handle missing values 

pca_fit <- PCA(pca_vars |> dplyr::select(-period),
               scale.unit = TRUE, 
               graph = FALSE)

fviz_eig(pca_fit, addlabels = TRUE) +
  scale_fill_viridis_d(option = "D") +
  labs(x = "Principal component",
       y = "Percentage of variance explained")

fviz_contrib(pca_fit, choice = "var", axes = 1) +
  scale_fill_viridis_c(option = "D")

fviz_contrib(pca_fit, choice = "var", axes = 2) +
  scale_fill_viridis_c(option = "D")

fviz_pca_biplot(
  pca_fit,
  habillage = pca_vars$period,  # align after drop_na()
  addEllipses = TRUE,
  label = "var",
  repel = TRUE) +
  scale_colour_brewer(palette = "Dark2") +
  scale_fill_brewer(palette = "Dark2") +
  labs(x = NULL, y = NULL, colour = "Period", fill = "Period", shape = "Period")


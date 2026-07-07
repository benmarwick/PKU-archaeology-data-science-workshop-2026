
# Peking University Archaeology Data Science Workshop 2026

A short workshop teaching introductory R for archaeological data analysis, using a simulated Palaeolithic lithic dataset. Students learn data cleaning, visualisation, statistical inference, and multivariate methods while exploring authentic patterns in based on real-world Lower, Middle, and Upper Palaeolithic stone tool assemblages. 

## Prerequisites

No prior R experience is required. These lessons cover RStudio orientation, objects, functions, and data import from scratch.

Install on your computer as follows:

- [R](https://cloud.r-project.org/) 
- [RStudio](https://posit.co/download/rstudio-desktop/) 
- Install required packages: `install.packages(c("tidyverse", "ggcorrplot", "broom", "FactoMineR", "factoextra", "GGally"))`

If you are not able to install software on a device, click on this button to write code in RStudio in your web browser: [![Binder](http://mybinder.org/badge_logo.svg)](http://mybinder.org/v2/gh/benmarwick/PKU-archaeology-data-science-workshop-2026/HEAD?urlpath=rstudio) Note that no log in is required, but file changes do not persist beyond the current session, and your session will time out after a short while. So download your work to your device before closing or moving away from the tab. The moment you close your browser tab, your Binder session is deleted. Any changes you make will be permanently lost. To move a file into RStudio, go to the Files pane and click 'upload'. To export a file, go to the files pane, check the box next to the file name, then click the blue gear button and click 'Export...'

## Workshop Schedule

| Lesson | Topic | Reading |
|--------|-------|---------|
| 01-1 | Orientation to R and RStudio | Wickham et al. (2023), Ch. 1 |
| 01-2 | Objects, functions, importing data | Ambrose (2001) |
| 02-1 | Quarto documents | Wickham et al. (2023), Ch. 28 |
| 02-2 | Data cleaning | Wickham et al. (2023), Ch. 3 |
| 03-1 | Visualisation with ggplot2 | Wickham et al. (2023), Ch. 9 |
| 03-2 | Statistical inference (chi-square, ANOVA, Tukey) | Çetinkaya-Rundel & Hardin (2023), Chs. 18, 22; Ismay & Kim (2023), Ch. 9 |
| 04-1 | Multivariate methods (PCA) | Vanderwarker & Marcoux (2018) |
| 04-2 | Capstone activity and quiz | Marwick et al. (2017) |

## Design Principles

- **Interpretable data**: every variable maps to a real, citable pattern in Palaeolithic lithic technology. You learn R while learning about the major technological transitions of human evolution.
- **Deliberately spoiled data**: I generate a clean dataset (`00_simulate_lithics.R`), then spoils it with four realistic field-recording errors (units on numbers, inconsistent whitespace, capitalisation/typos, sentinel values). You learn how to clean it.
- **Live coding**: I type the code in class and you follow by typing on your computer. You learn how to start simple and elaborate, how to manage errors, and the typical cadence of developing a realistic analysis workflow.
- **Progressive pipeline**: cleaned output from one lesson becomes the input for the next. The lessons follow a logical sequence resembling a real-world data science workflow.

## Dataset

`lithics_raw.csv` contains 300 simulated artefacts (100 per period) with 10 variables. Variable distributions and inter-period patterns are based on published literature on Palaeolithic lithic technology, including raw material provisioning strategies, platform preparation and preparatory scarring (Shimelmitz et al. 2014), and the flake-to-blade technological trajectory (Bar-Yosef & Kuhn 1999).

| Variable | Description |
|----------|-------------|
| `period` | Lower, Middle, Upper Palaeolithic |
| `raw_material` | Quartzite, Basic chert, Fine chert, Obsidian |
| `platform_prep` | Plain, Faceted, Abraded |
| `length_mm`, `width_mm`, `thickness_mm`, `platform_mm` | Morphometric measurements |
| `weight_g` | Weight in grams |
| `elongation` | Length / width ratio |
| `giur` | Geometric Index of Unifacial Reduction (0-1 scale) |

## Repository Structure

```
SCU-UIP-2026/
├── code/
│   ├── 00_simulate_lithics.R        # Instructor-only: generates the dataset
│   ├── 01-1_lesson.R                # L1: orientation (no code)
│   ├── 01-2_lesson.R                # L2: importing data (no code)
│   ├── 02-1_lesson.R                # L1: Quarto (no code)
│   ├── 02-2_lesson.R                # L2: data cleaning
│   ├── 03-1_lesson.R                # L1: visualisation
│   ├── 03-2_lesson.R                # L2: statistical inference
│   ├── 04-1_lesson.R                # L1: PCA
│   ├── 04-2_lesson.R                # L2: capstone
│   ├── extract_lesson_code.R        # Builds the live demo script
│   └── live-demo-script.R           # Combined R code from all lessons
├── data/
│   ├── lithics_raw.csv              # Student-facing raw data
│   └── lithics_clean.csv            # Instructor verification only
├── readings/                        # PDFs for student readings
├── slides/                          # Lecture slides (gitignored)
├── Dockerfile                       # Binder configuration
├── CLAUDE.md                        # AI agent instructions
├── PKU-archaeology-data-science-workshop-2026.Rproj # RStudio project file
└── README.md
```

## Preparing the Live Demo Script

`code/extract_lesson_code.R` reads every lesson `.R` file, extracts executable R code (stripping pure-comment and blank lines), adds day/lesson divider comments, and inserts blank lines between separate statements. The output is `data/live-demo-script.R`, a single file the instructor can print out and read from for live coding demos.

To regenerate after editing lesson files:

```r
source("code/extract_lesson_code.R")
```

## R Packages Required

- `tidyverse` (data import, manipulation, visualisation)
- `ggcorrplot` (chi-square residual plots)
- `broom` (tidy model output)
- `FactoMineR`, `factoextra` (PCA)
- `GGally` (pairs plots)
- `MASS` (multivariate normal simulation, instructor script only)

## References

PDFs for student readings are in the `readings/` directory.

- Ambrose, S. H. (2001). Paleolithic technology and human evolution. *Science*, 291(5509), 1748-1753. https://doi.org/10.1126/science.1059487
- Bar-Yosef, O., & Kuhn, S. L. (1999). The Big Deal about Blades: Laminar Technologies and Human Evolution. *American Anthropologist*, 101(2), 322-338. https://doi.org/10.1525/aa.1999.101.2.322
- Çetinkaya-Rundel, M., & Hardin, J. (2023). *Introduction to Modern Statistics* (2nd ed.). OpenIntro. https://openintro-ims.netlify.app/
- Ismay, C., & Kim, A. Y. (2023). *Statistical Inference via Data Science: A ModernDive into R and the Tidyverse* (2nd ed.). CRC Press. https://moderndive.com/
- Marwick, B., d'Alpoim Guedes, J., Barton, C. M., et al. (2017). Open science in archaeology. *SAA Archaeological Record*, 17(5), 8-14.
- Shimelmitz, R., Kuhn, S. L., Ronen, A., & Weinstein-Evron, M. (2014). Predetermined Flake Production at the Lower/Middle Paleolithic Boundary: Yabrudian Scraper-Blank Technology. *PLoS ONE*, 9(9), e106293. https://doi.org/10.1371/journal.pone.0106293
- Vanderwarker, A. M., & Marcoux, J. B. (2018). Principal component analysis. In S. Pardo-Guerra (Ed.), *The Encyclopedia of Archaeological Sciences*. Wiley. https://doi.org/10.1002/9781119188230.saseas0478
- Wickham, H., Çetinkaya-Rundel, M., & Grolemund, G. (2023). *R for Data Science* (2nd ed.). O'Reilly. https://r4ds.hadley.nz/

## Troubleshooting

When installing packages students sometimes see this warning message in the R console: `WARNING: Rtools is required to build R packages`. The fix is: (1) Go to the official CRAN Rtools page:
https://cran.r-project.org/bin/windows/Rtools/ and download the highest version number. (2) Run the installer by executing the downloaded .exe file. (3) During installation, you will see a checkbox asking to "Add Rtools to the system PATH". Make sure this box is CHECKED. This allows R to automatically find the tools. (4) Restart RStudio and install the R packages again using the `install.packages` function as before, this time it should succeed without any warnings.

When rendering Quarto documents students sometimes experience cryptic errors that turn out to be related to encoding and file paths. These can usually be fixed by having them creating RStudio projects in C:/ not in desktop or downloads, and by running this line in the R console and then restarting RStudio: 

```r
Sys.setenv(TMPDIR = "C:/TEMP"); Sys.setenv(TMPDIR = "C:/quarto_tmp"); Sys.setlocale("LC_ALL", "English_United States.UTF-8") # Now you need to RESTART RStudio
```

## License

This work is licensed under a [Creative Commons Attribution 4.0 International License](https://creativecommons.org/licenses/by/4.0/).

## Acknowledgements

I used [MimoCode](https://mimo.xiaomi.com/mimocode) with Mimo-V2.5 to assist with drafting the lesson plans.

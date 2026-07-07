# install.R

#  Install the rest of the workshop packages
packages <- c(
  'ggcorrplot', 'broom', 'GGally', 'cowplot', 'ggbeeswarm',
  'plotrix', 'RColorBrewer', 'viridis',
  'FactoMineR', 'factoextra', 'performance', 'FSA', 'infer',
  'here', 'readxl', 'rio', 'Rmisc', 'quarto', 'plyr', 'pbapply', 'remotes'
)

install.packages(packages)
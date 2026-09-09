# pull base image 
FROM rocker/binder:4.4

USER root
RUN adduser "$NB_USER" sudo && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >>/etc/sudoers
USER ${NB_USER}

# --- Copy RStudio preferences ---
# Ensure the config directory exists and copy the preferences file
RUN mkdir -p /home/${NB_USER}/.config/rstudio/
COPY rstudio-prefs.json /home/${NB_USER}/.config/rstudio/rstudio-prefs.json


# --- Install R Packages ---
# Copy the installation script into the image and run it as root
COPY install.R /tmp/install.R

RUN Rscript /tmp/install.R

# ---  Copy our GitHub files into the container ---
# Copy all files from your repo into the home directory
COPY .  /home/${NB_USER}/

# --- Automatically open the RStudio project ---
# Create the switch-to-project file so RStudio Server knows which project to restore at startup
RUN mkdir -p /home/${NB_USER}/.local/share/rstudio/projects_settings && \
    echo "/home/${NB_USER}/PKU-archaeology-data-science-workshop-2026.Rproj" > /home/${NB_USER}/.local/share/rstudio/projects_settings/switch-to-project


#  permissions so the binder user owns everything
USER root
RUN chown -R ${NB_USER}:${NB_USER} /home/${NB_USER}
USER ${NB_USER}




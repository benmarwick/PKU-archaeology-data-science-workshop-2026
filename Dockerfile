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

# ---  Configure RStudio to open our project automatically ---
RUN echo 'setHook("rstudio.sessionInit", function(newSession) { if (newSession && is.null(rstudioapi::getActiveProject())) rstudioapi::openProject("/home/${NB_USER}/PKU-archaeology-data-science-workshop-2026.Rproj") }, action = "append")' > /home/${NB_USER}/.Rprofile

#  permissions so the binder user owns everything
USER root
RUN chown -R ${NB_USER}:${NB_USER} /home/${NB_USER}
USER ${NB_USER}




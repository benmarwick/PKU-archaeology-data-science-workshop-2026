# pull base image 
FROM rocker/binder:4.4

USER root
RUN adduser "$NB_USER" sudo && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >>/etc/sudoers
USER ${NB_USER}

# --- 1. Install R Packages ---
# Copy the installation script into the image and run it as root
COPY install.R /tmp/install.R

RUN Rscript /tmp/install.R

# --- 2. Copy your GitHub files into the container ---
# Copy all files from your repo into the home directory
COPY .  /home/${NB_USER}/




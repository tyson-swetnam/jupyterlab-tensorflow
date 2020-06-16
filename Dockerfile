FROM cyversevice/base-notebook-opengl:latest 

USER root

# Install a few dependencies for iCommands, text editing, and monitoring instances
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    gcc \
    gnupg \
    htop \
    less \
    libfuse2 \
    libpq-dev \
    libssl1.0 \
    lsb \
    nano \
    nodejs \
    python-requests \
    software-properties-common \
    vim \
    wget
   
# iCommands
RUN wget -qO - https://packages.irods.org/irods-signing-key.asc | apt-key add - \
    && echo "deb [arch=amd64] https://packages.irods.org/apt/ bionic main" | tee /etc/apt/sources.list.d/renci-irods.list \
    && apt-get update && apt-get install -y irods-runtime irods-icommands
    
   # install the irods plugin for jupyter lab -- non-functional beyond JupyterLab v1.0.9
#RUN pip install jupyterlab_irods==3.0.2 \
#    && jupyter serverextension enable --py jupyterlab_irods \
#    && jupyter labextension install ijab

USER ${NB_USER}
WORKDIR /home/${NB_USER}

# install jupyterlab hub-extension, lab-manager, bokeh
RUN jupyter labextension install @jupyter-widgets/jupyterlab-manager 

# install jupyterlab git extension
RUN jupyter labextension install @jupyterlab/git && \
        pip install --upgrade jupyterlab-git && \
        jupyter serverextension enable --py jupyterlab_git

# install jupyterlab github extension
RUN jupyter labextension install @jupyterlab/github

# Install Tensorflow & Keras
RUN pip install --quiet --no-cache-dir \
    'tensorflow-gpu==2.2.0' \
    'h5py==2.10.0' \
    'pyyaml==5.3.1' \
    'requests==2.23.0' \
    'Pillow==7.1.2' \
    'keras==2.3.1' 
RUN fix-permissions "${CONDA_DIR}" \
    && fix-permissions "/home/${NB_USER}"

# Install and configure jupyter lab.
COPY jupyter_notebook_config.json /opt/conda/etc/jupyter/jupyter_notebook_config.json

# Add the jovyan user to UID 1000
#RUN groupadd jovyan && usermod -aG jovyan jovyan && usermod -d /home/jovyan -u 1000 jovyan
#RUN chown -R jovyan:jovyan /home/jovyan

EXPOSE 8888

COPY entry.sh /bin
RUN mkdir -p /home/${NB_USER}/.irods

CMD source /opt/conda/etc/profile.d/conda/sh \
    && conda activate base

ENTRYPOINT ["bash", "/bin/entry.sh"] 

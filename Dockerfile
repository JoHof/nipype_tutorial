# Generated by Neurodocker v0.2.0-30-g4b9bd64.
#
# Thank you for using Neurodocker. If you discover any issues 
# or ways to improve this software, please submit an issue or 
# pull request on our GitHub repository:
#     https://github.com/kaczmarj/neurodocker
#
# Timestamp: 2017-09-06 14:26:38

FROM neurodebian:stretch-non-free

ARG DEBIAN_FRONTEND=noninteractive

#----------------------------------------------------------
# Install common dependencies and create default entrypoint
#----------------------------------------------------------
ENV LANG="en_US.UTF-8" \
    LC_ALL="C.UTF-8" \
    ND_ENTRYPOINT="/neurodocker/startup.sh"
RUN apt-get update -qq && apt-get install -yq --no-install-recommends  \
    	bzip2 ca-certificates curl locales unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && localedef --force --inputfile=en_US --charmap=UTF-8 C.UTF-8 \
    && chmod 777 /opt && chmod a+s /opt \
    && mkdir -p /neurodocker \
    && if [ ! -f "$ND_ENTRYPOINT" ]; then \
         echo '#!/usr/bin/env bash' >> $ND_ENTRYPOINT \
         && echo 'set +x' >> $ND_ENTRYPOINT \
         && echo 'if [ -z "$*" ]; then /usr/bin/env bash; else $*; fi' >> $ND_ENTRYPOINT; \
       fi \
    && chmod -R 777 /neurodocker && chmod a+s /neurodocker
ENTRYPOINT ["/neurodocker/startup.sh"]

# User-defined instruction
RUN curl -sL https://deb.nodesource.com/setup_6.x | bash -

RUN apt-get update -qq \
    && apt-get install -y -q --no-install-recommends ants \
                                                     dcm2niix \
                                                     convert3d \
                                                     graphviz \
                                                     tree \
                                                     git-annex-standalone \
                                                     vim \
                                                     emacs-nox \
                                                     nano \
                                                     less \
                                                     ncdu \
                                                     tig \
                                                     git-annex-remote-rclone \
                                                     build-essential \
                                                     nodejs \
                                                     r-recommended \
                                                     psmisc \
                                                     libapparmor1 \
                                                     sudo \
                                                     dc \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN apt-get update -qq \
    && apt-get install -y -q --no-install-recommends afni \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# User-defined instruction
ENV PATH=/usr/lib/afni/bin:$PATH 

#--------------------------
# Install FreeSurfer v6.0.0
#--------------------------
# Install version minimized for recon-all
# See https://github.com/freesurfer/freesurfer/issues/70
RUN apt-get update -qq && apt-get install -yq --no-install-recommends bc libgomp1 libxmu6 libxt6 tcsh perl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && echo "Downloading minimized FreeSurfer ..." \
    && curl -sSL https://dl.dropbox.com/s/nnzcfttc41qvt31/recon-all-freesurfer6-3.min.tgz | tar xz -C /opt \
    && sed -i '$isource $FREESURFER_HOME/SetUpFreeSurfer.sh' $ND_ENTRYPOINT
ENV FREESURFER_HOME=/opt/freesurfer

RUN apt-get update -qq \
    && apt-get install -y -q --no-install-recommends fsl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# User-defined instruction
RUN sed -i '$iFSLDIR=/usr/share/fsl\n. ${FSLDIR}/5.0/etc/fslconf/fsl.sh\nPATH=${FSLDIR}/5.0/bin:${PATH}\nexport FSLDIR PATH' $ND_ENTRYPOINT

#----------------------
# Install MCR and SPM12
#----------------------
# Install MATLAB Compiler Runtime
RUN apt-get update -qq && apt-get install -yq --no-install-recommends libxext6 libxt6 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && echo "Downloading MATLAB Compiler Runtime ..." \
    && curl -sSL -o /tmp/mcr.zip https://www.mathworks.com/supportfiles/downloads/R2017a/deployment_files/R2017a/installers/glnxa64/MCR_R2017a_glnxa64_installer.zip \
    && unzip -q /tmp/mcr.zip -d /tmp/mcrtmp \
    && /tmp/mcrtmp/install -destinationFolder /opt/mcr -mode silent -agreeToLicense yes \
    && rm -rf /tmp/*

# Install standalone SPM
RUN echo "Downloading standalone SPM ..." \
    && curl -sSL -o spm.zip http://www.fil.ion.ucl.ac.uk/spm/download/restricted/utopia/dev/spm12_latest_Linux_R2017a.zip \
    && unzip -q spm.zip -d /opt \
    && chmod -R 777 /opt/spm* \
    && rm -rf spm.zip \
    && /opt/spm12/run_spm12.sh /opt/mcr/v92/ quit \
    && sed -i '$iexport SPMMCRCMD=\"/opt/spm12/run_spm12.sh /opt/mcr/v92/ script\"' $ND_ENTRYPOINT
ENV MATLABCMD=/opt/mcr/v92/toolbox/matlab \
    FORCE_SPMMCR=1 \
    LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:/opt/mcr/v92/runtime/glnxa64:/opt/mcr/v92/bin/glnxa64:/opt/mcr/v92/sys/os/glnxa64:$LD_LIBRARY_PATH

# User-defined instruction
RUN curl -sSL https://dl.dropbox.com/s/lfuppfhuhi1li9t/cifti-data.tgz?dl=0 | tar zx -C / 

# Create new user: neuro
RUN useradd --no-user-group --create-home --shell /bin/bash neuro
USER neuro

#------------------
# Install Miniconda
#------------------
ENV CONDA_DIR=/opt/conda \
    PATH=/opt/conda/bin:$PATH
RUN echo "Downloading Miniconda installer ..." \
    && miniconda_installer=/tmp/miniconda.sh \
    && curl -sSL -o $miniconda_installer https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh \
    && /bin/bash $miniconda_installer -b -p $CONDA_DIR \
    && rm -f $miniconda_installer \
    && conda config --system --prepend channels conda-forge \
    && conda config --system --set auto_update_conda false \
    && conda config --system --set show_channel_urls true \
    && conda update -y -q --all && sync \
    && conda clean -tipsy && sync

#-------------------------
# Create conda environment
#-------------------------
RUN conda create -y -q --name neuro3 \
    	python=3.6 altair apptools bokeh codecov configobj cython joblib jupyter jupyter_contrib_nbextensions jupyterhub jupyterlab matplotlib nitime pandas reprounzip reprozip scikit-image scikit-learn seaborn swig traits traitsui \
    && sync && conda clean -tipsy && sync \
    && /bin/bash -c "source activate neuro3 \
    	&& pip install -q --no-cache-dir \
    	https://github.com/nipy/nipype/tarball/master https://github.com/nipy/nibabel/archive/master.zip https://github.com/INCF/pybids/archive/master.zip git+https://github.com/jupyterhub/nbserverproxy.git git+https://github.com/jupyterhub/nbrsessionproxy.git https://github.com/satra/mapalign/archive/master.zip datalad dipy duecredit nilearn nipy niworkflows pprocess pymvpa2" \
    && sync
ENV PATH=/opt/conda/envs/neuro3/bin:$PATH

# User-defined instruction
RUN bash -c "source activate neuro3 && python -m ipykernel install --sys-prefix --name neuro3 --display-name Py3-neuro" 

# User-defined instruction
RUN bash -c "source activate neuro3 && pip install --no-cache-dir --pre --upgrade ipywidgets pythreejs" 

# User-defined instruction
RUN bash -c "source activate neuro3 && pip install --no-cache-dir --upgrade https://github.com/maartenbreddels/ipyvolume/archive/master.zip && jupyter nbextension install --py --sys-prefix ipyvolume && jupyter nbextension enable --py --sys-prefix ipyvolume" 

# User-defined instruction
RUN bash -c "source activate neuro3 && pip install --no-cache-dir git+https://github.com/data-8/gitautosync && jupyter serverextension enable --py nbgitautosync --sys-prefix" 

# User-defined instruction
RUN bash -c "source activate neuro3 && jupyter nbextension enable rubberband/main && jupyter nbextension enable exercise2/main && jupyter nbextension enable spellchecker/main && jupyter nbextension enable vega --py --sys-prefix" 

# User-defined instruction
RUN bash -c "source activate neuro3 && jupyter serverextension enable --sys-prefix --py nbserverproxy && jupyter serverextension enable --sys-prefix --py nbrsessionproxy && jupyter nbextension install --sys-prefix --py nbrsessionproxy && jupyter nbextension enable --sys-prefix --py nbrsessionproxy" 

USER root

# User-defined instruction
RUN echo 'neuro:neuro' | chpasswd && usermod -aG sudo neuro

# User-defined instruction
RUN mkdir /data && chown neuro /data && chmod 777 /data && mkdir /output && chown neuro /output && chmod 777 /output && mkdir /repos && chown neuro /repos && chmod 777 /repos

USER neuro

# User-defined instruction
RUN cd /repos && git clone https://github.com/neuro-data-science/neuroviz.git && git clone https://github.com/neuro-data-science/neuroML.git && git clone https://github.com/ReproNim/reproducible-imaging.git && git clone https://github.com/miykael/nipype_tutorial.git && git clone https://github.com/jmumford/nhwEfficiency.git && git clone https://github.com/jmumford/R-tutorial.git

# User-defined instruction
RUN bash -c "source activate neuro3 && cd /data && datalad install -r ///workshops/nih-2017/ds000114 && datalad --on-failure ignore get -r -J4 ds000114/sub-01/ses-test/anat && datalad --on-failure ignore get -r -J4 ds000114/sub-01/ses-test/func/*fingerfootlips* && datalad --on-failure ignore get -r -J4 ds000114/derivatives/fmriprep/sub-01/anat && datalad --on-failure ignore get -r -J4 ds000114/derivatives/fmriprep/sub-01/ses-test/func/*fingerfootlips*" 

# User-defined instruction
RUN curl -sSL https://osf.io/dhzv7/download?version=3 | tar zx -C /data/ds000114/derivatives/fmriprep

# User-defined instruction
ENV LD_LIBRARY_PATH="/usr/lib/R/lib:${LD_LIBRARY_PATH}" 

# User-defined instruction
RUN bash -c "echo c.NotebookApp.ip = \'0.0.0.0\' > ~/.jupyter/jupyter_notebook_config.py" 

WORKDIR /repos

#--------------------------------------
# Save container specifications to JSON
#--------------------------------------
RUN echo '{ \
    \n  "pkg_manager": "apt", \
    \n  "check_urls": false, \
    \n  "instructions": [ \
    \n    [ \
    \n      "base", \
    \n      "neurodebian:stretch-non-free" \
    \n    ], \
    \n    [ \
    \n      "instruction", \
    \n      "RUN curl -sL https://deb.nodesource.com/setup_6.x | bash -" \
    \n    ], \
    \n    [ \
    \n      "install", \
    \n      [ \
    \n        "ants", \
    \n        "dcm2niix", \
    \n        "convert3d", \
    \n        "graphviz", \
    \n        "tree", \
    \n        "git-annex-standalone", \
    \n        "vim", \
    \n        "emacs-nox", \
    \n        "nano", \
    \n        "less", \
    \n        "ncdu", \
    \n        "tig", \
    \n        "git-annex-remote-rclone", \
    \n        "build-essential", \
    \n        "nodejs", \
    \n        "r-recommended", \
    \n        "psmisc", \
    \n        "libapparmor1", \
    \n        "sudo", \
    \n        "dc" \
    \n      ] \
    \n    ], \
    \n    [ \
    \n      "install", \
    \n      [ \
    \n        "afni" \
    \n      ] \
    \n    ], \
    \n    [ \
    \n      "instruction", \
    \n      "ENV PATH=/usr/lib/afni/bin:$PATH " \
    \n    ], \
    \n    [ \
    \n      "freesurfer", \
    \n      { \
    \n        "version": "6.0.0", \
    \n        "min": true \
    \n      } \
    \n    ], \
    \n    [ \
    \n      "install", \
    \n      [ \
    \n        "fsl" \
    \n      ] \
    \n    ], \
    \n    [ \
    \n      "instruction", \
    \n      "RUN sed -i '$iFSLDIR=/usr/share/fsl\\n. ${FSLDIR}/5.0/etc/fslconf/fsl.sh\\nPATH=${FSLDIR}/5.0/bin:${PATH}\\nexport FSLDIR PATH' $ND_ENTRYPOINT" \
    \n    ], \
    \n    [ \
    \n      "spm", \
    \n      { \
    \n        "version": "12", \
    \n        "matlab_version": "R2017a" \
    \n      } \
    \n    ], \
    \n    [ \
    \n      "instruction", \
    \n      "RUN curl -sSL https://dl.dropbox.com/s/lfuppfhuhi1li9t/cifti-data.tgz?dl=0 | tar zx -C / " \
    \n    ], \
    \n    [ \
    \n      "user", \
    \n      "neuro" \
    \n    ], \
    \n    [ \
    \n      "miniconda", \
    \n      { \
    \n        "conda_install": "python=3.6 altair apptools bokeh codecov configobj cython joblib jupyter jupyter_contrib_nbextensions jupyterhub jupyterlab matplotlib nitime pandas reprounzip reprozip scikit-image scikit-learn seaborn swig traits traitsui", \
    \n        "env_name": "neuro3", \
    \n        "add_to_path": true, \
    \n        "pip_install": "https://github.com/nipy/nipype/tarball/master https://github.com/nipy/nibabel/archive/master.zip https://github.com/INCF/pybids/archive/master.zip git+https://github.com/jupyterhub/nbserverproxy.git git+https://github.com/jupyterhub/nbrsessionproxy.git https://github.com/satra/mapalign/archive/master.zip datalad dipy duecredit nilearn nipy niworkflows pprocess pymvpa2" \
    \n      } \
    \n    ], \
    \n    [ \
    \n      "instruction", \
    \n      "RUN bash -c \"source activate neuro3 && python -m ipykernel install --sys-prefix --name neuro3 --display-name Py3-neuro\" " \
    \n    ], \
    \n    [ \
    \n      "instruction", \
    \n      "RUN bash -c \"source activate neuro3 && pip install --no-cache-dir --pre --upgrade ipywidgets pythreejs\" " \
    \n    ], \
    \n    [ \
    \n      "instruction", \
    \n      "RUN bash -c \"source activate neuro3 && pip install --no-cache-dir --upgrade https://github.com/maartenbreddels/ipyvolume/archive/master.zip && jupyter nbextension install --py --sys-prefix ipyvolume && jupyter nbextension enable --py --sys-prefix ipyvolume\" " \
    \n    ], \
    \n    [ \
    \n      "instruction", \
    \n      "RUN bash -c \"source activate neuro3 && pip install --no-cache-dir git+https://github.com/data-8/gitautosync && jupyter serverextension enable --py nbgitautosync --sys-prefix\" " \
    \n    ], \
    \n    [ \
    \n      "instruction", \
    \n      "RUN bash -c \"source activate neuro3 && jupyter nbextension enable rubberband/main && jupyter nbextension enable exercise2/main && jupyter nbextension enable spellchecker/main && jupyter nbextension enable vega --py --sys-prefix\" " \
    \n    ], \
    \n    [ \
    \n      "instruction", \
    \n      "RUN bash -c \"source activate neuro3 && jupyter serverextension enable --sys-prefix --py nbserverproxy && jupyter serverextension enable --sys-prefix --py nbrsessionproxy && jupyter nbextension install --sys-prefix --py nbrsessionproxy && jupyter nbextension enable --sys-prefix --py nbrsessionproxy\" " \
    \n    ], \
    \n    [ \
    \n      "user", \
    \n      "root" \
    \n    ], \
    \n    [ \
    \n      "instruction", \
    \n      "RUN echo 'neuro:neuro' | chpasswd && usermod -aG sudo neuro" \
    \n    ], \
    \n    [ \
    \n      "instruction", \
    \n      "RUN mkdir /data && chown neuro /data && chmod 777 /data && mkdir /output && chown neuro /output && chmod 777 /output && mkdir /repos && chown neuro /repos && chmod 777 /repos" \
    \n    ], \
    \n    [ \
    \n      "user", \
    \n      "neuro" \
    \n    ], \
    \n    [ \
    \n      "instruction", \
    \n      "RUN cd /repos && git clone https://github.com/neuro-data-science/neuroviz.git && git clone https://github.com/neuro-data-science/neuroML.git && git clone https://github.com/ReproNim/reproducible-imaging.git && git clone https://github.com/miykael/nipype_tutorial.git && git clone https://github.com/jmumford/nhwEfficiency.git && git clone https://github.com/jmumford/R-tutorial.git" \
    \n    ], \
    \n    [ \
    \n      "instruction", \
    \n      "RUN bash -c \"source activate neuro3 && cd /data && datalad install -r ///workshops/nih-2017/ds000114 && datalad --on-failure ignore get -r -J4 ds000114/sub-01/ses-test/anat && datalad --on-failure ignore get -r -J4 ds000114/sub-01/ses-test/func/*fingerfootlips* && datalad --on-failure ignore get -r -J4 ds000114/derivatives/fmriprep/sub-01/anat && datalad --on-failure ignore get -r -J4 ds000114/derivatives/fmriprep/sub-01/ses-test/func/*fingerfootlips*\" " \
    \n    ], \
    \n    [ \
    \n      "instruction", \
    \n      "RUN curl -sSL https://osf.io/dhzv7/download?version=3 | tar zx -C /data/ds000114/derivatives/fmriprep" \
    \n    ], \
    \n    [ \
    \n      "instruction", \
    \n      "ENV LD_LIBRARY_PATH=\"/usr/lib/R/lib:${LD_LIBRARY_PATH}\" " \
    \n    ], \
    \n    [ \
    \n      "instruction", \
    \n      "RUN bash -c \"echo c.NotebookApp.ip = \\'0.0.0.0\\' > ~/.jupyter/jupyter_notebook_config.py\" " \
    \n    ], \
    \n    [ \
    \n      "workdir", \
    \n      "/repos" \
    \n    ] \
    \n  ], \
    \n  "generation_timestamp": "2017-09-06 14:26:38", \
    \n  "neurodocker_version": "0.2.0-30-g4b9bd64" \
    \n}' > /neurodocker/neurodocker_specs.json


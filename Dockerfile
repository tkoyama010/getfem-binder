FROM jupyter/minimal-notebook:65761486d5d3

LABEL Tetsuo Koyama <tkoyama010@gmail.com>

# Install core debian packages
USER root
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get -yq dist-upgrade \
    && apt-get install -yq --no-install-recommends \
    openssh-client \
    vim \
    curl \
    gcc \
    gmsh \
    && apt-get clean

# Xvfb
RUN apt-get install -yq --no-install-recommends \
    xvfb \
    x11-utils \
    libx11-dev \
    qt5-default \
    && apt-get clean

ENV DISPLAY=:99

# compile GetFEM
RUN apt-get install -yq --no-install-recommends \
    automake \
    libtool \
    make \
    g++ \
    libqd-dev \
    libqhull-dev \
    libmumps-seq-dev \
    liblapack-dev \
    libopenblas-dev \
    libpython3-dev \
    && apt-get clean

# Switch to notebook user
USER $NB_UID

# Upgrade the package managers
RUN pip install --upgrade pip
RUN npm i npm@latest -g

# Install Python packages
RUN pip install vtk && \
    pip install boto && \
    pip install h5py && \
    pip install nose && \
    pip install ipyevents && \
    pip install ipywidgets && \
    pip install mayavi && \
    pip install nibabel && \
    pip install numpy && \
    pip install pillow && \
    pip install pyqt5 && \
    pip install scikit-learn && \
    pip install scipy && \
    pip install xvfbwrapper &&\
    pip install matplotlib

# Compile GetFEM
RUN git clone https://github.com/getfem-doc/getfem.git && \
    cd getfem && \
    bash autogen.sh && \
    ./configure --with-pic --enable-python3 && \
    make -j8 && \
    make -j8 check \
    make install

RUN git clone https://github.com/tkoyama010/getfem-binder.git && \
    cd getfem-binder && \
    git checkout tkoyama010-patch-2

# Install Jupyter notebook extensions
RUN pip install RISE && \
    jupyter nbextension install rise --py --sys-prefix && \
    jupyter nbextension enable rise --py --sys-prefix && \
    jupyter nbextension install mayavi --py --sys-prefix && \
    jupyter nbextension enable mayavi --py --sys-prefix && \
    npm cache clean --force

# Try to decrease initial IPython kernel load times
RUN ipython -c "import matplotlib.pyplot as plt; print(plt)"

# Add an x-server to the entrypoint. This is needed by Mayavi
ENTRYPOINT ["tini", "-g", "--", "xvfb-run"]

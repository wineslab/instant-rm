# Use an official NVIDIA CUDA base image with Ubuntu 22.04
FROM nvidia/cuda:11.8.0-devel-ubuntu22.04

# Set environment variables for non-interactive installation
ENV DEBIAN_FRONTEND=noninteractive

# Install required system packages
RUN apt-get update && apt-get install -y \
    git \
    cmake \
    build-essential \
    ninja-build \
    libxi-dev \
    libxmu-dev \
    libglu1-mesa-dev \
    libgl-dev \
    libssl-dev \
    zlib1g-dev \
    curl \
    wget \
    python3.10 \
    python3.10-dev \
    python3.10-venv \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Set Python 3.10 as the default Python version
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1

# Upgrade pip and install JupyterLab
RUN python3.10 -m pip install --upgrade pip
RUN pip install jupyterlab

# Clone the required version of Mitsuba (v3.5.2) and ensure submodules are initialized
RUN git clone --recursive https://github.com/mitsuba-renderer/mitsuba3.git --branch v3.5.2 /opt/mitsuba3

# Set working directory to Mitsuba
WORKDIR /opt/mitsuba3

# Ensure submodules are initialized and updated
RUN git submodule update --init --recursive

# Configure Mitsuba with CMake to generate the mitsuba.conf file
RUN mkdir build && cd build && cmake -GNinja ..

# Modify the mitsuba.conf file to enable the 'cuda_ad_mono_polarized' variant
RUN sed -i 's/"enabled": \[/"enabled": \["cuda_ad_mono_polarized", /' build/mitsuba.conf

# Build Mitsuba with Ninja after modifying the configuration
RUN cd build && ninja

# Source the setpath.sh script to configure environment variables
RUN echo "source /opt/mitsuba3/build/setpath.sh" >> ~/.bashrc

# Set up environment for Mitsuba and Dr.Jit for running JupyterLab
ENV PYTHONPATH="/opt/mitsuba3/build/python:$PYTHONPATH"
ENV PATH="/opt/mitsuba3/build/bin:$PATH"

# Install Instant RM
WORKDIR /opt
RUN git clone https://github.com/NVlabs/instant-rm.git
WORKDIR /opt/instant-rm
RUN pip install -r requirements.txt
RUN pip install .

# Expose JupyterLab port
EXPOSE 8888

# Command to start JupyterLab
CMD ["bash", "-c", "source /opt/mitsuba3/build/setpath.sh && jupyter lab --ip=0.0.0.0 --allow-root"]

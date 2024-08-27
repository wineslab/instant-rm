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

# Upgrade pip
RUN python3.10 -m pip install --upgrade pip

# Set working directory
WORKDIR /opt

# Clone the required version of Mitsuba (v3.5.2) and Dr.Jit
RUN git clone --recursive https://github.com/mitsuba-renderer/mitsuba3.git --branch v3.5.2

# Set working directory to Mitsuba
WORKDIR /opt/mitsuba3

# Build Mitsuba with CMake using Ninja
RUN mkdir build && cd build && \
    cmake -GNinja -DPython_EXECUTABLE=/usr/bin/python3.10 -DPython_INCLUDE_DIR=/usr/include/python3.10 -DPython_LIBRARY=/usr/lib/x86_64-linux-gnu/libpython3.10.so .. && \
    ninja

# Configure Mitsuba with the correct variant
RUN sed -i 's/\"scalar_rgb\"/\"cuda_ad_mono_polarized\"/g' build/mitsuba.conf

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

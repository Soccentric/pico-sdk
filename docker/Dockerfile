FROM ubuntu:25.10

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Install essential build tools and dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    gcc-arm-none-eabi \
    libnewlib-arm-none-eabi \
    libstdc++-arm-none-eabi-newlib \
    git \
    python3 \
    python3-pip \
    wget \
    curl \
    pkg-config \
    libusb-1.0-0-dev \
    libudev-dev \
    gdb-multiarch \
    automake \
    autoconf \
    texinfo \
    libjim-dev \
    jimsh \
    pkg-config \
    libtool \
    libftdi-dev \
    libhidapi-dev \
    west \
    ninja-build \
    && rm -rf /var/lib/apt/lists/*

# Install west for Zephyr
RUN pip3 install west

# Set working directory
WORKDIR /workspace

# Clone Pico SDK
RUN git clone https://github.com/raspberrypi/pico-sdk.git --branch master --depth 1 /opt/pico-sdk && \
    cd /opt/pico-sdk && \
    git submodule update --init

# Clone Pico Examples (optional but useful)
RUN git clone https://github.com/raspberrypi/pico-examples.git --branch master --depth 1 /opt/pico-examples

# Clone Pico Extras (additional libraries)
RUN git clone https://github.com/raspberrypi/pico-extras.git --branch master --depth 1 /opt/pico-extras && \
    cd /opt/pico-extras && \
    git submodule update --init

# Clone Pico Playground (more examples and utilities)
RUN git clone https://github.com/raspberrypi/pico-playground.git --branch master --depth 1 /opt/pico-playground && \
    cd /opt/pico-playground && \
    git submodule update --init

# Clone Pico Zephyr (Zephyr RTOS support for Pico)
RUN git clone https://github.com/raspberrypi/pico-zephyr.git --branch main --depth 1 /opt/pico-zephyr

# Install picotool for managing Pico devices
RUN git clone https://github.com/raspberrypi/picotool.git --branch master --depth 1 /opt/picotool && \
    cd /opt/picotool && \
    mkdir build && cd build && \
    cmake -DPICO_SDK_PATH=/opt/pico-sdk .. && \
    make -j$(nproc) && \
    make install

# Build and install OpenOCD for debugging (Raspberry Pi fork with Pico support)
RUN git clone https://github.com/raspberrypi/openocd.git --branch master --depth 1 /opt/openocd && \
    cd /opt/openocd && \
    ./bootstrap && \
    ./configure --enable-picoprobe --enable-cmsis-dap && \
    make -j$(nproc) && \
    make install

# Set environment variables for Pico SDK
ENV PICO_SDK_PATH=/opt/pico-sdk
ENV PICO_EXTRAS_PATH=/opt/pico-extras
ENV PICO_PLAYGROUND_PATH=/opt/pico-playground
ENV PICO_ZEPHYR_PATH=/opt/pico-zephyr

# Add helpful aliases and setup script
RUN echo 'alias pico-sdk-update="cd /opt/pico-sdk && git pull && git submodule update"' >> /root/.bashrc && \
    echo 'alias pico-examples="cd /opt/pico-examples"' >> /root/.bashrc && \
    echo 'export PICO_SDK_PATH=/opt/pico-sdk' >> /root/.bashrc && \
    echo 'export PICO_EXTRAS_PATH=/opt/pico-extras' >> /root/.bashrc && \
    echo 'export PICO_PLAYGROUND_PATH=/opt/pico-playground' >> /root/.bashrc && \
    echo 'export PICO_ZEPHYR_PATH=/opt/pico-zephyr' >> /root/.bashrc

# Copy and install the pico-init script
COPY pico-init.sh /usr/local/bin/pico-init
RUN chmod +x /usr/local/bin/pico-init

# Copy and install the zephyr-init script
COPY zephyr-init.sh /usr/local/bin/zephyr-init
RUN chmod +x /usr/local/bin/zephyr-init

# Create a non-root user for building
RUN useradd -m -s /bin/bash pi && \
    mkdir -p /workspace && \
    chown pi:pi /workspace

# Switch to the pi user
USER pi

# Set the working directory to /workspace for user projects
WORKDIR /workspace

CMD ["/bin/bash"]

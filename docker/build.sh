#!/bin/bash

# Universal build script for FreeRTOS and Zephyr projects

set -e

PROJECT_TYPE=""
PROJECT=""
BOARD=""

# Parse command line options
while getopts "t:p:b:" opt; do
  case $opt in
    t) PROJECT_TYPE="$OPTARG" ;;
    p) PROJECT="$OPTARG" ;;
    b) BOARD="$OPTARG" ;;
    *) echo "Usage: $0 -t <freertos|zephyr> -p <project_path> -b <board>" >&2; exit 1 ;;
  esac
done

# Check if required parameters are provided
if [ -z "$PROJECT_TYPE" ] || [ -z "$PROJECT" ] || [ -z "$BOARD" ]; then
  echo "Error: -t <type>, -p <project_path> and -b <board> must be provided" >&2
  echo "Usage: $0 -t <freertos|zephyr> -p <project_path> -b <board>" >&2
  exit 1
fi

# Change to project directory
cd "$PROJECT" || { echo "Error: Cannot change to directory $PROJECT" >&2; exit 1; }

if [ "$PROJECT_TYPE" = "freertos" ]; then
    echo "Building FreeRTOS project for $BOARD..."
    
    # Initialize FreeRTOS submodule if needed
    if [ -d "FreeRTOS-Kernel" ] && [ ! -f "FreeRTOS-Kernel/CMakeLists.txt" ]; then
        echo "Initializing FreeRTOS-Kernel submodule..."
        git submodule update --init --recursive
    fi
    
    # Create build directory
    mkdir -p build
    cd build
    
    # Clean previous build
    rm -rf *
    
    # Select toolchain based on board
    TOOLCHAIN_FILE="/opt/pico-sdk/cmake/preload/toolchains/pico_arm_cortex_m0plus_gcc.cmake"
    if [[ "$BOARD" == *"pico2"* ]]; then
        TOOLCHAIN_FILE="/opt/pico-sdk/cmake/preload/toolchains/pico_arm_cortex_m33_gcc.cmake"
    fi

    # Configure and build
    cmake -DPICO_SDK_PATH=/opt/pico-sdk \
          -DPICO_BOARD="$BOARD" \
          -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN_FILE" \
          -DCMAKE_C_COMPILER=/usr/bin/arm-none-eabi-gcc \
          -DCMAKE_CXX_COMPILER=/usr/bin/arm-none-eabi-g++ \
          -DCMAKE_ASM_COMPILER=/usr/bin/arm-none-eabi-gcc \
          -DCMAKE_SYSTEM_NAME=Generic \
          -DFREERTOS_PORT=GCC_ARM_CM0 \
          ..
    make -j$(nproc)
    
    echo "Build complete! Output: $(pwd)/*.uf2"
    
elif [ "$PROJECT_TYPE" = "zephyr" ]; then
    echo "Building Zephyr project for $BOARD..."
    
    # Configure Zephyr toolchain
    export ZEPHYR_TOOLCHAIN_VARIANT=gnuarmemb
    export GNUARMEMB_TOOLCHAIN_PATH=/usr
    
    # Source Zephyr environment
    if [ -f "/workspace/firmware/zephyr/zephyr/zephyr-env.sh" ]; then
        source /workspace/firmware/zephyr/zephyr/zephyr-env.sh
    elif [ -f "/workspace/firmware/zephyr/zephyr-main/zephyr-env.sh" ]; then
        source /workspace/firmware/zephyr/zephyr-main/zephyr-env.sh
    elif [ -n "$ZEPHYR_BASE" ]; then
        source "$ZEPHYR_BASE/zephyr-env.sh"
    else
        echo "Error: Cannot find Zephyr environment" >&2
        echo "Please run 'make init-zephyr' first" >&2
        exit 1
    fi
    
    # Build the project (libc config is now in prj.conf)
    west build -b "$BOARD" -p auto .
    
    echo "Build complete! Output: $(pwd)/build/zephyr/zephyr.uf2"
else
    echo "Error: Unknown project type: $PROJECT_TYPE" >&2
    echo "Supported types: freertos, zephyr" >&2
    exit 1
fi
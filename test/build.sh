#!/bin/bash
set -e
mkdir -p build
cd build
cmake -DPICO_SDK_PATH=/opt/pico-sdk ..
make -j$(nproc)

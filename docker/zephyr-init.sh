#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: zephyr-init <project-name>"
    exit 1
fi

PROJECT_NAME=$1
mkdir -p $PROJECT_NAME
cd $PROJECT_NAME

# Initialize Zephyr workspace
west init zephyrproject

cd zephyrproject

# Configure to include pico-zephyr
west config manifest.project-filter -- +pico-zephyr

# Update modules
west update

# Create a sample project directory
mkdir -p ../$PROJECT_NAME-app
cd ../$PROJECT_NAME-app

# Copy a sample application
cp -r ../zephyrproject/zephyr/samples/basic/blinky .

# Build the sample for Pico
west build -p auto -b rpi_pico blinky

echo "Zephyr project ${PROJECT_NAME} created and built successfully!"
echo "UF2 file is in: ${PROJECT_NAME}-app/build/zephyr/zephyr.uf2"
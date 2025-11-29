#!/bin/bash

# Script to create firmware/zephyr directory and initialize a basic Zephyr project for Raspberry Pi Pico

set -e

echo "Creating firmware directory..."
mkdir -p firmware

echo "Creating firmware/zephyr directory..."
mkdir -p firmware/zephyr

echo "Initializing Zephyr project..."

cd firmware/zephyr

PROJECT_NAME="zephyr-project"

mkdir -p $PROJECT_NAME
cd $PROJECT_NAME

# Initialize Zephyr workspace
west init https://github.com/raspberrypi/pico-zephyr

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
#!/bin/bash

# Test script to build all supported Raspberry Pi Pico boards for FreeRTOS and Zephyr

set -e  # Exit on any error

echo "=========================================="
echo "Testing all Raspberry Pi Pico builds"
echo "=========================================="

# Clean previous builds
echo "Cleaning previous builds..."
make clean

# FreeRTOS boards
FREERTOS_BOARDS=("pico" "pico_w" "pico2" "pico2_w")

echo ""
echo "=========================================="
echo "Building FreeRTOS for all boards"
echo "=========================================="

for board in "${FREERTOS_BOARDS[@]}"; do
    echo ""
    echo "Building FreeRTOS for $board..."
    make freertos-all BOARD="$board"
    echo "✅ FreeRTOS build successful for $board"
done

# Zephyr boards
ZEPHYR_BOARDS=("rpi_pico" "rpi_pico/rp2040/w" "rpi_pico2" "rpi_pico2/rp2350a/m33/w")

echo ""
echo "=========================================="
echo "Building Zephyr for all boards"
echo "=========================================="

for board in "${ZEPHYR_BOARDS[@]}"; do
    echo ""
    echo "Building Zephyr for $board..."
    make zephyr-all BOARD="$board"
    echo "✅ Zephyr build successful for $board"
done

echo ""
echo "=========================================="
echo "🎉 All builds completed successfully!"
echo "=========================================="
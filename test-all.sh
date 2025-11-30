#!/bin/bash

# Test script to build all supported Raspberry Pi Pico boards for FreeRTOS and Zephyr

# set -e  # Don't exit on error, continue to test all

echo "=========================================="
echo "Testing all Raspberry Pi Pico builds"
echo "=========================================="

# Clean previous builds
echo "Cleaning previous builds..."
make clean

# Track failures
freertos_failures=()
zephyr_failures=()

# FreeRTOS boards
FREERTOS_BOARDS=("pico" "pico_w" "pico2" "pico2_w")

echo ""
echo "=========================================="
echo "Building FreeRTOS for all boards"
echo "=========================================="

for board in "${FREERTOS_BOARDS[@]}"; do
    echo ""
    echo "Building FreeRTOS for $board..."
    if make freertos-all BOARD="$board"; then
        echo "✅ FreeRTOS build successful for $board"
    else
        echo "❌ FreeRTOS build failed for $board"
        freertos_failures+=("$board")
    fi
done

# Zephyr boards
ZEPHYR_BOARDS=("rpi_pico" "rpi_pico/rp2040/w" "rpi_pico2/rp2350a/m33" "rpi_pico2/rp2350a/m33/w")

echo ""
echo "=========================================="
echo "Initializing Zephyr project"
echo "=========================================="

echo "Initializing Zephyr project..."
if make init-zephyr; then
    echo "✅ Zephyr initialization successful"
else
    echo "❌ Zephyr initialization failed"
    exit 1
fi

echo ""
echo "=========================================="
echo "Building Zephyr for all boards"
echo "=========================================="

for board in "${ZEPHYR_BOARDS[@]}"; do
    echo ""
    echo "Building Zephyr for $board..."
    if make zephyr-all BOARD="$board"; then
        echo "✅ Zephyr build successful for $board"
    else
        echo "❌ Zephyr build failed for $board"
        zephyr_failures+=("$board")
    fi
done

echo ""
echo "=========================================="
echo "Build Summary"
echo "=========================================="

if [ ${#freertos_failures[@]} -eq 0 ] && [ ${#zephyr_failures[@]} -eq 0 ]; then
    echo "🎉 All builds completed successfully!"
else
    echo "Some builds failed:"
    if [ ${#freertos_failures[@]} -gt 0 ]; then
        echo "FreeRTOS failures: ${freertos_failures[*]}"
    fi
    if [ ${#zephyr_failures[@]} -gt 0 ]; then
        echo "Zephyr failures: ${zephyr_failures[*]}"
    fi
    exit 1
fi
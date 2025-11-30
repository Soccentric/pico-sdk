#!/bin/bash

# Test script to build all supported Raspberry Pi Pico boards for FreeRTOS and Zephyr

# set -e  # Don't exit on error, continue to test all

echo "=========================================="
echo "Testing all Raspberry Pi Pico builds"
echo "=========================================="

# Clean previous builds
echo "Cleaning previous builds..."
make clean

# Track statistics
total_pass=0
total_fail=0
declare -a all_boards=()
declare -a all_statuses=()
declare -a all_durations=()

# FreeRTOS boards
FREERTOS_BOARDS=("pico" "pico_w" "pico2" "pico2_w")

echo ""
echo "=========================================="
echo "Building FreeRTOS for all boards"
echo "=========================================="

for board in "${FREERTOS_BOARDS[@]}"; do
    echo ""
    echo "Building FreeRTOS for $board..."
    start=$(date +%s)
    if make freertos-all BOARD="$board"; then
        echo "✅ FreeRTOS build successful for $board"
        status="PASS"
        ((total_pass++))
    else
        echo "❌ FreeRTOS build failed for $board"
        status="FAIL"
        ((total_fail++))
    fi
    end=$(date +%s)
    duration=$((end - start))
    all_boards+=("FreeRTOS-$board")
    all_statuses+=("$status")
    all_durations+=("$duration")
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
    start=$(date +%s)
    if make zephyr-all BOARD="$board"; then
        echo "✅ Zephyr build successful for $board"
        status="PASS"
        ((total_pass++))
    else
        echo "❌ Zephyr build failed for $board"
        status="FAIL"
        ((total_fail++))
    fi
    end=$(date +%s)
    duration=$((end - start))
    all_boards+=("Zephyr-$board")
    all_statuses+=("$status")
    all_durations+=("$duration")
done

echo ""
echo "=========================================="
echo "Build Summary"
echo "=========================================="

echo "Total builds: $((total_pass + total_fail))"
echo "Passed: $total_pass"
echo "Failed: $total_fail"
echo ""

printf "%-30s %-10s %-12s\n" "Board" "Status" "Duration(s)"
printf "%-30s %-10s %-12s\n" "-----" "------" "-----------"

for i in "${!all_boards[@]}"; do
    printf "%-30s %-10s %-12d\n" "${all_boards[$i]}" "${all_statuses[$i]}" "${all_durations[$i]}"
done

if [ $total_fail -eq 0 ]; then
    echo ""
    echo "🎉 All builds completed successfully!"
else
    echo ""
    echo "Some builds failed."
    exit 1
fi
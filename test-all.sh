#!/bin/bash
#==============================================================================
# Test Script for Raspberry Pi Pico RTOS Builds
# Tests all supported board configurations for FreeRTOS and Zephyr
#==============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[PASS]${NC} $1"; }
log_fail() { echo -e "${RED}[FAIL]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Raspberry Pi Pico RTOS Build Test Suite"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Clean previous builds
log_info "Cleaning previous builds..."
make clean 2>/dev/null || true

# Track statistics
total_pass=0
total_fail=0
declare -a all_boards=()
declare -a all_statuses=()
declare -a all_durations=()

# FreeRTOS boards
# Note: pico2/pico2_w (RP2350) not yet supported - requires FreeRTOS RP2350 port
FREERTOS_BOARDS=("pico" "pico_w")

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  FreeRTOS Builds"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

for board in "${FREERTOS_BOARDS[@]}"; do
    log_info "Building FreeRTOS for $board..."
    start=$(date +%s)
    
    if make freertos-all BOARD="$board" 2>&1 | tail -20; then
        log_success "FreeRTOS build for $board"
        status="PASS"
        ((++total_pass))
    else
        log_fail "FreeRTOS build for $board"
        status="FAIL"
        ((++total_fail))
    fi
    
    end=$(date +%s)
    duration=$((end - start))
    all_boards+=("FreeRTOS-$board")
    all_statuses+=("$status")
    all_durations+=("$duration")
    echo ""
done

# Zephyr boards
ZEPHYR_BOARDS=(
    "rpi_pico"
    "rpi_pico/rp2040/w"
    "rpi_pico2/rp2350a/m33"
    "rpi_pico2/rp2350a/m33/w"
)

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Zephyr Builds"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

for board in "${ZEPHYR_BOARDS[@]}"; do
    # Create a safe name for display
    safe_name=$(echo "$board" | tr '/' '-')
    log_info "Building Zephyr for $board..."
    start=$(date +%s)
    
    if make zephyr-all BOARD="$board" 2>&1 | tail -20; then
        log_success "Zephyr build for $board"
        status="PASS"
        ((++total_pass))
    else
        log_fail "Zephyr build for $board"
        status="FAIL"
        ((++total_fail))
    fi
    
    end=$(date +%s)
    duration=$((end - start))
    all_boards+=("Zephyr-$safe_name")
    all_statuses+=("$status")
    all_durations+=("$duration")
    echo ""
done

# Print summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Build Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Total builds: $((total_pass + total_fail))"
echo "Passed: $total_pass"
echo "Failed: $total_fail"
echo ""

printf "%-35s %-10s %-12s\n" "Configuration" "Status" "Duration"
printf "%-35s %-10s %-12s\n" "─────────────────────────────────" "────────" "──────────"

for i in "${!all_boards[@]}"; do
    if [[ "${all_statuses[$i]}" == "PASS" ]]; then
        printf "%-35s ${GREEN}%-10s${NC} %dm %ds\n" \
            "${all_boards[$i]}" "${all_statuses[$i]}" \
            "$((${all_durations[$i]} / 60))" "$((${all_durations[$i]} % 60))"
    else
        printf "%-35s ${RED}%-10s${NC} %dm %ds\n" \
            "${all_boards[$i]}" "${all_statuses[$i]}" \
            "$((${all_durations[$i]} / 60))" "$((${all_durations[$i]} % 60))"
    fi
done

echo ""

if [[ $total_fail -eq 0 ]]; then
    echo -e "${GREEN}🎉 All builds completed successfully!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some builds failed.${NC}"
    exit 1
fi
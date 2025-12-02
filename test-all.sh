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
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

# Unicode symbols
CHECK="✓"
CROSS="✗"
ARROW="➜"
GEAR="⚙"
ROCKET="🚀"
CLOCK="⏱"

# Terminal width
TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)

log_info() { echo -e "${BLUE}${ARROW}${NC} $1"; }
log_success() { echo -e "${GREEN}${CHECK}${NC} $1"; }
log_fail() { echo -e "${RED}${CROSS}${NC} $1"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $1"; }

# Clear screen and show header
clear_screen() {
    clear
    echo ""
}

# Draw a horizontal line
draw_line() {
    local char="${1:-─}"
    printf '%*s\n' "$TERM_WIDTH" '' | tr ' ' "$char"
}

# Draw a fancy box header
draw_header() {
    local title="$1"
    local subtitle="${2:-}"
    echo ""
    echo -e "${CYAN}╔$(printf '═%.0s' $(seq 1 $((TERM_WIDTH-2))))╗${NC}"
    printf "${CYAN}║${NC}${BOLD}%*s${NC}${CYAN}║${NC}\n" $(((${#title}+TERM_WIDTH-2)/2)) "$title"
    if [[ -n "$subtitle" ]]; then
        printf "${CYAN}║${NC}${DIM}%*s${NC}${CYAN}║${NC}\n" $(((${#subtitle}+TERM_WIDTH-2)/2)) "$subtitle"
    fi
    echo -e "${CYAN}╚$(printf '═%.0s' $(seq 1 $((TERM_WIDTH-2))))╝${NC}"
    echo ""
}

# Draw section header
draw_section() {
    local title="$1"
    echo ""
    echo -e "${MAGENTA}┌──${BOLD} $title ${NC}${MAGENTA}$(printf '─%.0s' $(seq 1 $((TERM_WIDTH-${#title}-6))))┐${NC}"
    echo ""
}

# Show progress bar
show_progress() {
    local current=$1
    local total=$2
    local board="$3"
    local width=$((TERM_WIDTH - 30))
    local percent=$((current * 100 / total))
    local filled=$((width * current / total))
    local empty=$((width - filled))
    
    printf "\r${DIM}[${NC}"
    printf "${GREEN}%*s${NC}" "$filled" '' | tr ' ' '█'
    printf "${DIM}%*s${NC}" "$empty" '' | tr ' ' '░'
    printf "${DIM}]${NC} ${BOLD}%3d%%${NC} ${CYAN}%s${NC}" "$percent" "$board"
}

# Show build status with animation
show_build_status() {
    local board="$1"
    local status="$2"
    local duration="$3"
    local mins=$((duration / 60))
    local secs=$((duration % 60))
    
    if [[ "$status" == "PASS" ]]; then
        printf "  ${GREEN}${CHECK}${NC} %-40s ${GREEN}PASSED${NC}  ${DIM}${CLOCK} %dm %02ds${NC}\n" "$board" "$mins" "$secs"
    else
        printf "  ${RED}${CROSS}${NC} %-40s ${RED}FAILED${NC}  ${DIM}${CLOCK} %dm %02ds${NC}\n" "$board" "$mins" "$secs"
    fi
}

# Show spinner while building
spin() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while ps -p "$pid" > /dev/null 2>&1; do
        for i in $(seq 0 9); do
            printf "\r  ${CYAN}${spinstr:$i:1}${NC} Building..."
            sleep $delay
        done
    done
    printf "\r"
}

clear_screen
draw_header "${ROCKET} Raspberry Pi Pico RTOS Build Test Suite" "Testing all board configurations"

# Clean previous builds
log_info "Cleaning previous builds..."
make clean 2>/dev/null || true

# Track statistics
total_pass=0
total_fail=0
declare -a all_boards=()
declare -a all_statuses=()
declare -a all_durations=()
build_start_time=$(date +%s)

# FreeRTOS boards
# Note: pico2/pico2_w (RP2350) not yet supported - requires FreeRTOS RP2350 port
FREERTOS_BOARDS=("pico" "pico_w" "pico2" "pico2_w")

# Zephyr boards
ZEPHYR_BOARDS=(
    "rpi_pico"
    "rpi_pico/rp2040/w"
    "rpi_pico2/rp2350a/m33"
    "rpi_pico2/rp2350a/m33/w"
)

# Calculate total builds
total_builds=$((${#FREERTOS_BOARDS[@]} + ${#ZEPHYR_BOARDS[@]}))
current_build=0

#==============================================================================
# FreeRTOS Builds
#==============================================================================
sleep 1
clear_screen
draw_header "${ROCKET} Raspberry Pi Pico RTOS Build Test Suite" "Building FreeRTOS configurations"
draw_section "${GEAR} FreeRTOS Builds (${#FREERTOS_BOARDS[@]} configurations)"

for board in "${FREERTOS_BOARDS[@]}"; do
    ((++current_build))
    show_progress $current_build $total_builds "FreeRTOS-$board"
    echo ""
    log_info "Building FreeRTOS for ${BOLD}$board${NC}..."
    start=$(date +%s)
    
    if make freertos-all BOARD="$board" PROJECT=test_freertos > /tmp/build_$$.log 2>&1; then
        status="PASS"
        ((++total_pass))
    else
        status="FAIL"
        ((++total_fail))
    fi
    
    end=$(date +%s)
    duration=$((end - start))
    all_boards+=("FreeRTOS-$board")
    all_statuses+=("$status")
    all_durations+=("$duration")
    
    show_build_status "FreeRTOS-$board" "$status" "$duration"
    echo ""
done

#==============================================================================
# Zephyr Builds
#==============================================================================
sleep 1
clear_screen
draw_header "${ROCKET} Raspberry Pi Pico RTOS Build Test Suite" "Building Zephyr configurations"

# Show FreeRTOS results summary
draw_section "${CHECK} FreeRTOS Results"
for i in $(seq 0 $((${#FREERTOS_BOARDS[@]}-1))); do
    show_build_status "${all_boards[$i]}" "${all_statuses[$i]}" "${all_durations[$i]}"
done

draw_section "${GEAR} Zephyr Builds (${#ZEPHYR_BOARDS[@]} configurations)"

for board in "${ZEPHYR_BOARDS[@]}"; do
    ((++current_build))
    # Create a safe name for display
    safe_name=$(echo "$board" | tr '/' '-')
    show_progress $current_build $total_builds "Zephyr-$safe_name"
    echo ""
    log_info "Building Zephyr for ${BOLD}$board${NC}..."
    start=$(date +%s)
    
    if make zephyr-all BOARD="$board" PROJECT=test_zephyr > /tmp/build_$$.log 2>&1; then
        status="PASS"
        ((++total_pass))
    else
        status="FAIL"
        ((++total_fail))
    fi
    
    end=$(date +%s)
    duration=$((end - start))
    all_boards+=("Zephyr-$safe_name")
    all_statuses+=("$status")
    all_durations+=("$duration")
    
    show_build_status "Zephyr-$safe_name" "$status" "$duration"
    echo ""
done

# Cleanup temp log
rm -f /tmp/build_$$.log

#==============================================================================
# Final Summary
#==============================================================================
build_end_time=$(date +%s)
total_duration=$((build_end_time - build_start_time))

sleep 1
clear_screen
draw_header "${ROCKET} Raspberry Pi Pico RTOS Build Test Suite" "Build Complete!"

# Summary box
echo -e "${CYAN}┌─────────────────────────────────────────────────────────────────────────┐${NC}"
echo -e "${CYAN}│${NC}                         ${BOLD}📊 BUILD SUMMARY${NC}                              ${CYAN}│${NC}"
echo -e "${CYAN}├─────────────────────────────────────────────────────────────────────────┤${NC}"
printf "${CYAN}│${NC}   Total Builds: ${BOLD}%-5d${NC}                                                  ${CYAN}│${NC}\n" "$((total_pass + total_fail))"
printf "${CYAN}│${NC}   ${GREEN}${CHECK} Passed:${NC}     ${GREEN}${BOLD}%-5d${NC}                                                  ${CYAN}│${NC}\n" "$total_pass"
printf "${CYAN}│${NC}   ${RED}${CROSS} Failed:${NC}     ${RED}${BOLD}%-5d${NC}                                                  ${CYAN}│${NC}\n" "$total_fail"
printf "${CYAN}│${NC}   ${CLOCK} Duration:   ${BOLD}%dm %02ds${NC}                                              ${CYAN}│${NC}\n" "$((total_duration / 60))" "$((total_duration % 60))"
echo -e "${CYAN}└─────────────────────────────────────────────────────────────────────────┘${NC}"

echo ""
draw_section "📋 Detailed Results"
echo ""
printf "  ${BOLD}%-40s %-12s %-12s${NC}\n" "Configuration" "Status" "Duration"
echo -e "  ${DIM}────────────────────────────────────────────────────────────────${NC}"

for i in "${!all_boards[@]}"; do
    mins=$((${all_durations[$i]} / 60))
    secs=$((${all_durations[$i]} % 60))
    if [[ "${all_statuses[$i]}" == "PASS" ]]; then
        printf "  ${GREEN}${CHECK}${NC} %-38s ${GREEN}%-12s${NC} ${DIM}%dm %02ds${NC}\n" \
            "${all_boards[$i]}" "PASSED" "$mins" "$secs"
    else
        printf "  ${RED}${CROSS}${NC} %-38s ${RED}%-12s${NC} ${DIM}%dm %02ds${NC}\n" \
            "${all_boards[$i]}" "FAILED" "$mins" "$secs"
    fi
done

echo ""
echo -e "${DIM}────────────────────────────────────────────────────────────────${NC}"

if [[ $total_fail -eq 0 ]]; then
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}                                                                       ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}          ${GREEN}${BOLD}🎉 ALL BUILDS COMPLETED SUCCESSFULLY! 🎉${NC}                   ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}                                                                       ${GREEN}║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    exit 0
else
    echo ""
    echo -e "${RED}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║${NC}                                                                       ${RED}║${NC}"
    echo -e "${RED}║${NC}              ${RED}${BOLD}❌ SOME BUILDS FAILED - CHECK LOGS ❌${NC}                   ${RED}║${NC}"
    echo -e "${RED}║${NC}                                                                       ${RED}║${NC}"
    echo -e "${RED}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    exit 1
fi
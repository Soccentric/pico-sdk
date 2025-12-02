#!/bin/bash
#==============================================================================
# Universal Build Script for FreeRTOS and Zephyr Projects
# Supports all Raspberry Pi Pico variants
#==============================================================================

set -euo pipefail

# Script version
SCRIPT_VERSION="2.0.0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
log_debug() { [[ "${VERBOSE:-0}" == "1" ]] && echo -e "${CYAN}[DEBUG]${NC} $1" || true; }

# Default configuration
PROJECT_TYPE=""
PROJECT=""
BOARD=""
BUILD_TYPE="Release"
CLEAN_BUILD=0
VERBOSE=0
JOBS=$(nproc)

#==============================================================================
# Help and Usage
#==============================================================================
show_help() {
    cat << EOF
Universal Build Script v${SCRIPT_VERSION}
Build FreeRTOS and Zephyr projects for Raspberry Pi Pico

USAGE:
    $0 -t <type> -p <project_path> -b <board> [OPTIONS]

REQUIRED ARGUMENTS:
    -t <type>       Project type: freertos | zephyr
    -p <path>       Path to project directory
    -b <board>      Target board

OPTIONAL ARGUMENTS:
    -d              Debug build (unoptimized, with symbols)
    -r              Release build (optimized, default)
    -c              Clean build (remove build directory first)
    -j <jobs>       Number of parallel jobs (default: $(nproc))
    -v              Verbose output
    -h              Show this help message

FREERTOS BOARDS:
    pico            Raspberry Pi Pico
    pico_w          Raspberry Pi Pico W
    pico2           Raspberry Pi Pico 2
    pico2_w         Raspberry Pi Pico 2 W

ZEPHYR BOARDS:
    rpi_pico                    Raspberry Pi Pico
    rpi_pico/rp2040/w           Raspberry Pi Pico W
    rpi_pico2/rp2350a/m33       Raspberry Pi Pico 2
    rpi_pico2/rp2350a/m33/w     Raspberry Pi Pico 2 W

EXAMPLES:
    $0 -t freertos -p /workspace/firmware/freeRTOS -b pico
    $0 -t zephyr -p /workspace/firmware/zephyr/app -b rpi_pico/rp2040/w
    $0 -t freertos -p /workspace/firmware/freeRTOS -b pico2 -d -c
EOF
}

#==============================================================================
# Parse Command Line Arguments
#==============================================================================
while getopts "t:p:b:j:drcvh" opt; do
    case $opt in
        t) PROJECT_TYPE="$OPTARG" ;;
        p) PROJECT="$OPTARG" ;;
        b) BOARD="$OPTARG" ;;
        d) BUILD_TYPE="Debug" ;;
        r) BUILD_TYPE="Release" ;;
        c) CLEAN_BUILD=1 ;;
        j) JOBS="$OPTARG" ;;
        v) VERBOSE=1 ;;
        h) show_help; exit 0 ;;
        *) show_help >&2; exit 1 ;;
    esac
done

#==============================================================================
# Validate Arguments
#==============================================================================
if [[ -z "$PROJECT_TYPE" || -z "$PROJECT" || -z "$BOARD" ]]; then
    log_error "Missing required arguments"
    echo ""
    show_help >&2
    exit 1
fi

if [[ "$PROJECT_TYPE" != "freertos" && "$PROJECT_TYPE" != "zephyr" ]]; then
    log_error "Invalid project type: $PROJECT_TYPE"
    log_error "Supported types: freertos, zephyr"
    exit 1
fi

# Validate project directory exists
if [[ ! -d "$PROJECT" ]]; then
    log_error "Project directory does not exist: $PROJECT"
    exit 1
fi

#==============================================================================
# Build Information Banner
#==============================================================================
print_banner() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Build Configuration"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Project Type: ${PROJECT_TYPE^^}"
    echo "  Project Path: $PROJECT"
    echo "  Target Board: $BOARD"
    echo "  Build Type:   $BUILD_TYPE"
    echo "  Parallel Jobs: $JOBS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

#==============================================================================
# FreeRTOS Build
#==============================================================================
build_freertos() {
    log_info "Building FreeRTOS project for $BOARD..."
    
    cd "$PROJECT" || { log_error "Cannot change to directory: $PROJECT"; exit 1; }
    
    # Initialize FreeRTOS submodule if needed
    if [[ -d "FreeRTOS-Kernel" && ! -f "FreeRTOS-Kernel/CMakeLists.txt" ]]; then
        log_info "Initializing FreeRTOS-Kernel submodule..."
        git submodule update --init --recursive
    fi
    
    # Clean build if requested
    if [[ "$CLEAN_BUILD" == "1" && -d "build" ]]; then
        log_info "Cleaning previous build..."
        rm -rf build
    fi
    
    # Check if we need to clean due to platform change
    if [[ -f "build/CMakeCache.txt" ]]; then
        local CACHED_BOARD=$(grep "PICO_BOARD:" build/CMakeCache.txt 2>/dev/null | cut -d= -f2 || echo "")
        if [[ -n "$CACHED_BOARD" && "$CACHED_BOARD" != "$BOARD" ]]; then
            log_info "Board changed from $CACHED_BOARD to $BOARD, cleaning build directory..."
            rm -rf build
        fi
    fi
    
    # Create build directory
    mkdir -p build
    cd build
    
    # Select toolchain and FreeRTOS port based on board
    local TOOLCHAIN_FILE="/opt/pico-sdk/cmake/preload/toolchains/pico_arm_cortex_m0plus_gcc.cmake"
    local EXTRA_DEFINES=""
    local FREERTOS_PORT="GCC_RP2040"
    
    if [[ "$BOARD" == *"pico2"* ]]; then
        TOOLCHAIN_FILE="/opt/pico-sdk/cmake/preload/toolchains/pico_arm_cortex_m33_gcc.cmake"
        EXTRA_DEFINES="-DPICO_RP2350=1"
        FREERTOS_PORT="GCC_ARM_CM33_NTZ_NONSECURE"
    fi
    
    log_debug "Toolchain: $TOOLCHAIN_FILE"
    log_debug "FreeRTOS Port: $FREERTOS_PORT"
    log_debug "Build type: $BUILD_TYPE"
    
    # Configure with CMake
    log_info "Configuring CMake..."
    cmake \
        -DPICO_SDK_PATH=/opt/pico-sdk \
        -DPICO_BOARD="$BOARD" \
        -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
        -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN_FILE" \
        -DCMAKE_C_COMPILER=/usr/bin/arm-none-eabi-gcc \
        -DCMAKE_CXX_COMPILER=/usr/bin/arm-none-eabi-g++ \
        -DCMAKE_ASM_COMPILER=/usr/bin/arm-none-eabi-gcc \
        -DCMAKE_SYSTEM_NAME=Generic \
        -DFREERTOS_PORT="$FREERTOS_PORT" \
        $EXTRA_DEFINES \
        .. || { log_error "CMake configuration failed"; exit 1; }
    
    # Build
    log_info "Building with $JOBS parallel jobs..."
    make -j"$JOBS" || { log_error "Build failed"; exit 1; }
    
    # Find and report output files
    local UF2_FILE=$(find . -name "*.uf2" -type f | head -1)
    if [[ -n "$UF2_FILE" ]]; then
        local SIZE=$(ls -lh "$UF2_FILE" | awk '{print $5}')
        log_success "Build complete!"
        echo ""
        echo "Output file: $(realpath "$UF2_FILE")"
        echo "Size: $SIZE"
    else
        log_warn "No .uf2 file found"
    fi
}

#==============================================================================
# Zephyr Build
#==============================================================================
build_zephyr() {
    log_info "Building Zephyr project for $BOARD..."
    
    cd "$PROJECT" || { log_error "Cannot change to directory: $PROJECT"; exit 1; }
    
    # Configure Zephyr toolchain
    export ZEPHYR_TOOLCHAIN_VARIANT=gnuarmemb
    export GNUARMEMB_TOOLCHAIN_PATH=/usr
    
    # Find and source Zephyr environment
    local ZEPHYR_ENV=""
    local PROJECT_PARENT=$(dirname "$PROJECT")
    local SEARCH_PATHS=(
        "${PROJECT_PARENT}/zephyr/zephyr-env.sh"
        "${PROJECT_PARENT}/../zephyr/zephyr-env.sh"
        "/workspace/firmware/zephyr/zephyr/zephyr-env.sh"
        "/workspace/firmware/*/zephyr/zephyr-env.sh"
        "${ZEPHYR_BASE:-}/zephyr-env.sh"
    )
    
    for path in "${SEARCH_PATHS[@]}"; do
        if [[ -f "$path" ]]; then
            ZEPHYR_ENV="$path"
            break
        fi
    done
    
    if [[ -z "$ZEPHYR_ENV" ]]; then
        log_error "Cannot find Zephyr environment"
        log_error "Please run 'make init-zephyr' first"
        exit 1
    fi
    
    log_debug "Sourcing Zephyr environment: $ZEPHYR_ENV"
    source "$ZEPHYR_ENV"
    
    # Determine pristine build option
    local PRISTINE="auto"
    if [[ "$CLEAN_BUILD" == "1" ]]; then
        PRISTINE="always"
        log_info "Forcing pristine build..."
    fi
    
    # Build with west
    log_info "Building with west..."
    west build \
        -b "$BOARD" \
        -p "$PRISTINE" \
        . || { log_error "Build failed"; exit 1; }
    
    # Report output files
    local UF2_FILE="build/zephyr/zephyr.uf2"
    if [[ -f "$UF2_FILE" ]]; then
        local SIZE=$(ls -lh "$UF2_FILE" | awk '{print $5}')
        log_success "Build complete!"
        echo ""
        echo "Output file: $(realpath "$UF2_FILE")"
        echo "Size: $SIZE"
    else
        log_warn "No .uf2 file found at expected location"
    fi
}

#==============================================================================
# Main Execution
#==============================================================================

# Record start time
START_TIME=$(date +%s)

print_banner

case "$PROJECT_TYPE" in
    freertos)
        build_freertos
        ;;
    zephyr)
        build_zephyr
        ;;
esac

# Calculate and display build time
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Build completed in ${MINUTES}m ${SECONDS}s"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
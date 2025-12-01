#!/bin/bash
#==============================================================================
# Custom Pico Project Initialization Script
# Creates a standalone, portable Pico project with git initialization
#==============================================================================

set -euo pipefail

if [ -z "$1" ]; then
    echo "Usage: pico-init <project-name>"
    exit 1
fi

PROJECT_NAME=$1

# Change to workspace directory
cd /workspace

if [ -d "$PROJECT_NAME" ]; then
    echo "[WARN] Project directory already exists: $PROJECT_NAME"
    echo "To reinitialize, remove the directory first: rm -rf $PROJECT_NAME"
    exit 0
fi

mkdir -p $PROJECT_NAME
cd $PROJECT_NAME

# Create CMakeLists.txt
cat > CMakeLists.txt << 'EOF'
#==============================================================================
# Pico Project CMake Configuration
# Standalone, portable project for Raspberry Pi Pico
#==============================================================================
cmake_minimum_required(VERSION 3.13)

# Project configuration
set(PROJECT_NAME "PROJECT_NAME_PLACEHOLDER" CACHE STRING "Project name")
set(PROJECT_VERSION "1.0.0" CACHE STRING "Project version")

# Build type configuration
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Release" CACHE STRING "Build type" FORCE)
endif()

# Pull in SDK (must be before project)
include(pico_sdk_import.cmake)

project(${PROJECT_NAME} 
    VERSION ${PROJECT_VERSION}
    LANGUAGES C CXX ASM
)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

# Compiler warnings
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    add_compile_options(-Wall -Wextra -g3 -O0)
    add_compile_definitions(DEBUG=1)
else()
    add_compile_options(-Wall -Wextra -Os)
    add_compile_definitions(NDEBUG=1)
endif()

# Initialize the SDK
pico_sdk_init()

# Create executable
add_executable(${PROJECT_NAME}
    main.c
)

# Pull in common dependencies
target_link_libraries(${PROJECT_NAME} 
    pico_stdlib
    hardware_gpio
)

# Add Pico W wireless support if needed
if(PICO_BOARD STREQUAL "pico_w" OR PICO_BOARD STREQUAL "pico2_w")
    target_link_libraries(${PROJECT_NAME}
        pico_cyw43_arch_none
    )
    target_compile_definitions(${PROJECT_NAME} PRIVATE
        PICO_CYW43_SUPPORTED=1
    )
endif()

# Enable USB output, disable UART output
pico_enable_stdio_usb(${PROJECT_NAME} 1)
pico_enable_stdio_uart(${PROJECT_NAME} 0)

# Create map/bin/hex/uf2 files
pico_add_extra_outputs(${PROJECT_NAME})

# Build information
message(STATUS "========================================")
message(STATUS "Project: ${PROJECT_NAME} v${PROJECT_VERSION}")
message(STATUS "Build Type: ${CMAKE_BUILD_TYPE}")
message(STATUS "Board: ${PICO_BOARD}")
message(STATUS "========================================")
EOF

# Replace placeholder with actual project name
sed -i "s/PROJECT_NAME_PLACEHOLDER/${PROJECT_NAME}/g" CMakeLists.txt

# Create pico_sdk_import.cmake
cat > pico_sdk_import.cmake << 'EOF'
# This is a copy of <PICO_SDK_PATH>/external/pico_sdk_import.cmake
# This can be dropped into an external project to help locate this SDK
# It should be include()ed prior to project()

if (DEFINED ENV{PICO_SDK_PATH} AND (NOT PICO_SDK_PATH))
    set(PICO_SDK_PATH $ENV{PICO_SDK_PATH})
    message("Using PICO_SDK_PATH from environment ('${PICO_SDK_PATH}')")
endif ()

if (DEFINED ENV{PICO_SDK_FETCH_FROM_GIT} AND (NOT PICO_SDK_FETCH_FROM_GIT))
    set(PICO_SDK_FETCH_FROM_GIT $ENV{PICO_SDK_FETCH_FROM_GIT})
    message("Using PICO_SDK_FETCH_FROM_GIT from environment ('${PICO_SDK_FETCH_FROM_GIT}')")
endif ()

if (DEFINED ENV{PICO_SDK_FETCH_FROM_GIT_PATH} AND (NOT PICO_SDK_FETCH_FROM_GIT_PATH))
    set(PICO_SDK_FETCH_FROM_GIT_PATH $ENV{PICO_SDK_FETCH_FROM_GIT_PATH})
    message("Using PICO_SDK_FETCH_FROM_GIT_PATH from environment ('${PICO_SDK_FETCH_FROM_GIT_PATH}')")
endif ()

set(PICO_SDK_PATH "${PICO_SDK_PATH}" CACHE PATH "Path to the Raspberry Pi Pico SDK")
set(PICO_SDK_FETCH_FROM_GIT "${PICO_SDK_FETCH_FROM_GIT}" CACHE BOOL "Set to ON to fetch copy of SDK from git if not otherwise locatable")
set(PICO_SDK_FETCH_FROM_GIT_PATH "${PICO_SDK_FETCH_FROM_GIT_PATH}" CACHE PATH "location to download SDK")

if (NOT PICO_SDK_PATH)
    if (PICO_SDK_FETCH_FROM_GIT)
        include(FetchContent)
        set(FETCHCONTENT_BASE_DIR_SAVE ${FETCHCONTENT_BASE_DIR})
        if (PICO_SDK_FETCH_FROM_GIT_PATH)
            get_filename_component(FETCHCONTENT_BASE_DIR "${PICO_SDK_FETCH_FROM_GIT_PATH}" REALPATH BASE_DIR "${CMAKE_SOURCE_DIR}")
        endif ()
        FetchContent_Declare(
                pico_sdk
                GIT_REPOSITORY https://github.com/raspberrypi/pico-sdk
                GIT_TAG master
        )
        if (NOT pico_sdk)
            message("Downloading Raspberry Pi Pico SDK")
            FetchContent_Populate(pico_sdk)
            set(PICO_SDK_PATH ${pico_sdk_SOURCE_DIR})
        endif ()
        set(FETCHCONTENT_BASE_DIR ${FETCHCONTENT_BASE_DIR_SAVE})
    else ()
        message(FATAL_ERROR
                "SDK location was not specified. Please set PICO_SDK_PATH or set PICO_SDK_FETCH_FROM_GIT to ON to fetch from git."
        )
    endif ()
endif ()

get_filename_component(PICO_SDK_PATH "${PICO_SDK_PATH}" REALPATH BASE_DIR "${CMAKE_BINARY_DIR}")
if (NOT EXISTS ${PICO_SDK_PATH})
    message(FATAL_ERROR "Directory '${PICO_SDK_PATH}' not found")
endif ()

set(PICO_SDK_INIT_CMAKE_FILE ${PICO_SDK_PATH}/pico_sdk_init.cmake)
if (NOT EXISTS ${PICO_SDK_INIT_CMAKE_FILE})
    message(FATAL_ERROR "Directory '${PICO_SDK_PATH}' does not appear to contain the Raspberry Pi Pico SDK")
endif ()

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${PICO_SDK_PATH}/cmake)
include(${PICO_SDK_INIT_CMAKE_FILE})
EOF

# Create main.c (simple blink example)
cat > main.c << 'EOF'
/**
 * @file main.c
 * @brief Simple Pico application - LED blink example
 * 
 * Demonstrates basic GPIO usage and USB serial output.
 * Works with Pico, Pico W, Pico 2, and Pico 2 W.
 */

#include <stdio.h>
#include "pico/stdlib.h"
#include "hardware/gpio.h"

#ifdef PICO_CYW43_SUPPORTED
#include "pico/cyw43_arch.h"
#endif

/* LED control functions for hardware abstraction */
static bool led_initialized = false;

static int led_init(void) {
    if (led_initialized) return 0;
    
#ifdef PICO_CYW43_SUPPORTED
    if (cyw43_arch_init() != 0) {
        return -1;
    }
#else
    gpio_init(PICO_DEFAULT_LED_PIN);
    gpio_set_dir(PICO_DEFAULT_LED_PIN, GPIO_OUT);
#endif
    
    led_initialized = true;
    return 0;
}

static void led_set(bool on) {
    if (!led_initialized) return;
    
#ifdef PICO_CYW43_SUPPORTED
    cyw43_arch_gpio_put(CYW43_WL_GPIO_LED_PIN, on ? 1 : 0);
#else
    gpio_put(PICO_DEFAULT_LED_PIN, on ? 1 : 0);
#endif
}

int main(void) {
    /* Initialize stdio for USB serial output */
    stdio_init_all();
    
    /* Wait for USB connection in debug builds */
#ifdef DEBUG
    sleep_ms(2000);
#endif
    
    printf("\n========================================\n");
    printf("  Pico Application Started\n");
    printf("  Board: %s\n", PICO_BOARD);
    printf("========================================\n\n");
    
    /* Initialize LED */
    if (led_init() != 0) {
        printf("[ERROR] Failed to initialize LED\n");
    }
    
    uint32_t count = 0;
    bool led_state = false;
    
    while (true) {
        /* Toggle LED */
        led_state = !led_state;
        led_set(led_state);
        
        /* Print status message */
        printf("Hello, Raspberry Pi Pico! Count: %lu\n", count++);
        
        /* Wait 500ms */
        sleep_ms(500);
    }
    
    return 0;
}
EOF

# Create standalone Makefile
cat > Makefile << 'EOF'
#==============================================================================
# Pico Standalone Project Makefile
# Portable build automation using Docker for Raspberry Pi Pico
#
# This project is self-contained and can be compiled independently.
# It uses the rpi-pico-dev Docker image which contains:
#   - Pico SDK
#   - ARM GCC toolchain
#   - CMake and build tools
#==============================================================================

# Default board
BOARD ?= pico

# Docker configuration
IMAGE_NAME := rpi-pico-dev
PROJECT_DIR := $(shell pwd)

# Build type: Debug or Release
BUILD_TYPE ?= Release

# Number of parallel jobs
JOBS ?= $(shell nproc 2>/dev/null || echo 4)

.PHONY: help build clean rebuild shell debug release check-docker

help:
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  Pico Standalone Project Build System"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "  Usage: make <target> [BOARD=<board>] [BUILD_TYPE=<type>]"
	@echo ""
	@echo "  TARGETS:"
	@echo "    build    - Build the project"
	@echo "    clean    - Clean build artifacts"
	@echo "    rebuild  - Clean and rebuild"
	@echo "    shell    - Open interactive development shell"
	@echo "    debug    - Build with debug symbols"
	@echo "    release  - Build optimized release"
	@echo ""
	@echo "  BOARDS:"
	@echo "    pico     - Raspberry Pi Pico (default)"
	@echo "    pico_w   - Raspberry Pi Pico W"
	@echo "    pico2    - Raspberry Pi Pico 2"
	@echo "    pico2_w  - Raspberry Pi Pico 2 W"
	@echo ""
	@echo "  EXAMPLES:"
	@echo "    make build BOARD=pico_w"
	@echo "    make debug BOARD=pico2"
	@echo "    make rebuild BOARD=pico BUILD_TYPE=Debug"
	@echo ""
	@echo "  REQUIREMENTS:"
	@echo "    - Docker installed and running"
	@echo "    - rpi-pico-dev Docker image"
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""

check-docker:
	@docker image inspect $(IMAGE_NAME) >/dev/null 2>&1 || \
		(echo "[ERROR] Docker image '$(IMAGE_NAME)' not found." && \
		 echo "Please build the Docker image first." && \
		 exit 1)

build: check-docker
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  Building for $(BOARD) ($(BUILD_TYPE))"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	docker run --rm \
		--user $$(id -u):$$(id -g) \
		-v $(PROJECT_DIR):/project \
		-w /project \
		$(IMAGE_NAME) \
		/bin/bash -c "\
			mkdir -p build && cd build && \
			cmake -DPICO_SDK_PATH=/opt/pico-sdk \
			      -DPICO_BOARD=$(BOARD) \
			      -DCMAKE_BUILD_TYPE=$(BUILD_TYPE) \
			      .. && \
			make -j$(JOBS)"
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  ✅ Build complete!"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "  Output: build/*.uf2"
	@echo ""
	@echo "  To flash:"
	@echo "    1. Hold BOOTSEL button while connecting Pico"
	@echo "    2. Copy .uf2 file to RPI-RP2 drive"
	@echo ""

debug: BUILD_TYPE=Debug
debug: build

release: BUILD_TYPE=Release
release: build

clean:
	@echo "[INFO] Cleaning build artifacts..."
	rm -rf build

rebuild: clean build

shell: check-docker
	@echo "[INFO] Starting interactive development shell..."
	docker run -it --rm \
		--user $$(id -u):$$(id -g) \
		-v $(PROJECT_DIR):/project \
		-w /project \
		$(IMAGE_NAME) \
		/bin/bash
EOF

# Create README.md
cat > README.md << EOF
# ${PROJECT_NAME}

A standalone Raspberry Pi Pico project.

## Project Structure

\`\`\`
${PROJECT_NAME}/
├── CMakeLists.txt          # CMake build configuration
├── Makefile                # Docker-based build automation
├── pico_sdk_import.cmake   # SDK integration
├── main.c                  # Application source
├── README.md               # This file
└── build/                  # Build output (generated)
\`\`\`

## Quick Start

### Build

\`\`\`bash
# Build for Pico
make build BOARD=pico

# Build for Pico W
make build BOARD=pico_w

# Build for Pico 2
make build BOARD=pico2

# Debug build
make debug BOARD=pico
\`\`\`

### Flash

1. Hold **BOOTSEL** button while connecting Pico to USB
2. Copy \`build/${PROJECT_NAME}.uf2\` to the RPI-RP2 drive

## Requirements

- Docker installed and running
- rpi-pico-dev Docker image

## Customization

Edit \`main.c\` to add your application logic.
Add new source files and update \`CMakeLists.txt\` as needed.

## License

MIT License
EOF

# Create .gitignore
cat > .gitignore << 'EOF'
# Build output
build/

# IDE files
.vscode/
.idea/
*.swp
*.swo
*~

# Backup files
*.bak
*.orig

# OS files
.DS_Store
Thumbs.db
EOF

# Initialize git repository and create initial commit
echo "[INFO] Initializing git repository..."

# Initialize new git repository
git init

# Configure git user for the commit (use generic values if not set)
git config user.email "developer@pico-project.local"
git config user.name "Pico Developer"

# Add all files
git add -A

# Create initial commit
git commit -m "initial commit"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ Project ${PROJECT_NAME} created successfully!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Location: /workspace/${PROJECT_NAME}"
echo ""
echo "  This is a standalone, portable project that can be compiled independently."
echo ""
echo "  Quick start:"
echo "    cd ${PROJECT_NAME}"
echo "    make build BOARD=pico"
echo ""
echo "  The project has been initialized as a git repository with an initial commit."
echo ""

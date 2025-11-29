#!/bin/bash

# Script to create firmware/freeRTOS directory and initialize a basic FreeRTOS project for Raspberry Pi Pico

set -e

echo "Creating firmware directory..."
mkdir -p firmware

echo "Creating firmware/freeRTOS directory..."
mkdir -p firmware/freeRTOS

echo "Creating FreeRTOS project files..."

cd firmware/freeRTOS

# Create CMakeLists.txt
cat > CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.13)

# Pull in SDK (must be before project)
include(pico_sdk_import.cmake)

project(freertos_project C CXX ASM)
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

# Initialize the SDK
pico_sdk_init()

# Add FreeRTOS
add_subdirectory(FreeRTOS-Kernel)

# Add executable
add_executable(${PROJECT_NAME}
    main.c
)

# Pull in our pico_stdlib which pulls in commonly used features
target_link_libraries(${PROJECT_NAME}
    pico_stdlib
    FreeRTOS-Kernel
    FreeRTOS-Kernel-Heap4
)

# Enable USB output, disable UART output
pico_enable_stdio_usb(${PROJECT_NAME} 1)
pico_enable_stdio_uart(${PROJECT_NAME} 0)

# Create map/bin/hex/uf2 file etc.
pico_add_extra_outputs(${PROJECT_NAME})

# Add URL via pico_set_program_url
example_auto_set_url(${PROJECT_NAME})
EOF

# Create main.c
cat > main.c << 'EOF'
#include <FreeRTOS.h>
#include <task.h>
#include <stdio.h>
#include "pico/stdlib.h"

void vTaskCode(void *pvParameters) {
    const char *pcTaskName = (char *)pvParameters;
    for (;;) {
        printf("%s is running\r\n", pcTaskName);
        gpio_put(PICO_DEFAULT_LED_PIN, 1);
        vTaskDelay(pdMS_TO_TICKS(500));
        gpio_put(PICO_DEFAULT_LED_PIN, 0);
        vTaskDelay(pdMS_TO_TICKS(500));
    }
}

int main() {
    stdio_init_all();

    gpio_init(PICO_DEFAULT_LED_PIN);
    gpio_set_dir(PICO_DEFAULT_LED_PIN, GPIO_OUT);

    xTaskCreate(
        vTaskCode,       /* Function that implements the task. */
        "LED Task",      /* Text name for the task. */
        256,             /* Stack size in words, not bytes. */
        (void*)"LED Task", /* Parameter passed into the task. */
        tskIDLE_PRIORITY+1, /* Priority at which the task is created. */
        NULL             /* Used to pass out the created task's handle. */
    );

    vTaskStartScheduler();

    while (1) {
        // Should never reach here
    }
}
EOF

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

# Create README.md
cat > README.md << 'EOF'
# FreeRTOS Project for Raspberry Pi Pico

This is a basic FreeRTOS project for the Raspberry Pi Pico.

## Prerequisites

- Raspberry Pi Pico SDK installed
- FreeRTOS-Kernel submodule (run `git submodule update --init --recursive` if cloned from git)
- CMake and a C/C++ compiler

## Building

1. Set the PICO_SDK_PATH environment variable to your SDK installation.
2. Create a build directory: `mkdir build && cd build`
3. Run CMake: `cmake ..`
4. Build: `make`

## Flashing

After building, flash the `freertos_project.uf2` file to your Pico.

The project creates a task that blinks the onboard LED.
EOF

# Create .gitignore
cat > .gitignore << 'EOF'
build/
.vscode/
*.swp
*.swo
EOF

echo "FreeRTOS project created successfully in firmware/freeRTOS/"
echo "To build: cd firmware/freeRTOS && mkdir build && cd build && cmake .. && make"
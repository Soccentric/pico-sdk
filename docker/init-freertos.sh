#!/bin/bash

# Script to create firmware/freeRTOS directory and initialize a basic FreeRTOS project for Raspberry Pi Pico

set -e

# Change to workspace directory
cd /workspace

# Check if project already exists
if [ -d "firmware/freeRTOS" ] && [ -f "firmware/freeRTOS/CMakeLists.txt" ]; then
    echo "FreeRTOS project already exists in firmware/freeRTOS/"
    echo "To reinitialize, remove the directory first: rm -rf firmware/freeRTOS"
    exit 0
fi

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

# Add FreeRTOS-Kernel with proper port configuration
set(FREERTOS_KERNEL_PATH ${CMAKE_CURRENT_SOURCE_DIR}/FreeRTOS-Kernel)

# Create config interface library for FreeRTOSConfig.h
add_library(freertos_config INTERFACE)
target_include_directories(freertos_config SYSTEM INTERFACE ${CMAKE_CURRENT_SOURCE_DIR})

# Set the FreeRTOS port for RP2040 (Cortex-M0+)
set(FREERTOS_PORT GCC_RP2040 CACHE STRING "FreeRTOS port")

# Set heap implementation (heap_4 is recommended for most applications)
set(FREERTOS_HEAP 4 CACHE STRING "FreeRTOS heap implementation")

# Add FreeRTOS kernel
add_subdirectory(${FREERTOS_KERNEL_PATH} FreeRTOS-Kernel)

# Add executable
add_executable(${PROJECT_NAME}
    main.c
)

# Include FreeRTOS headers
target_include_directories(${PROJECT_NAME} PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
)

# Link libraries - use freertos_kernel (the actual CMake target name)
target_link_libraries(${PROJECT_NAME}
    pico_stdlib
    freertos_kernel
)

# Add support for Pico W
if(PICO_BOARD STREQUAL "pico_w")
    target_link_libraries(${PROJECT_NAME}
        pico_cyw43_arch_none
    )
endif()

# Enable USB output, disable UART output
pico_enable_stdio_usb(${PROJECT_NAME} 1)
pico_enable_stdio_uart(${PROJECT_NAME} 0)

# Create map/bin/hex/uf2 file etc.
pico_add_extra_outputs(${PROJECT_NAME})
EOF

# Create main.c
cat > main.c << 'EOF'
#include "pico/stdlib.h"
#include <stdio.h>
#include <FreeRTOS.h>
#include <task.h>

// For Pico W, we need to use CYW43 for the LED
#if defined(CYW43_WL_GPIO_LED_PIN) && !defined(PICO_RP2350)
#include "pico/cyw43_arch.h"
#define LED_INIT() cyw43_arch_init()
#define LED_ON() cyw43_arch_gpio_put(CYW43_WL_GPIO_LED_PIN, 1)
#define LED_OFF() cyw43_arch_gpio_put(CYW43_WL_GPIO_LED_PIN, 0)
#else
#define LED_INIT() do { gpio_init(25); gpio_set_dir(25, GPIO_OUT); } while(0)
#define LED_ON() gpio_put(25, 1)
#define LED_OFF() gpio_put(25, 0)
#endif

void vTaskCode(void *pvParameters) {
    const char *pcTaskName = (char *)pvParameters;
    for (;;) {
        printf("%s is running\r\n", pcTaskName);
        LED_ON();
        vTaskDelay(pdMS_TO_TICKS(500));
        LED_OFF();
        vTaskDelay(pdMS_TO_TICKS(500));
    }
}

int main() {
    stdio_init_all();
    LED_INIT();

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

# Create FreeRTOSConfig.h
cat > FreeRTOSConfig.h << 'EOF'
#ifndef FREERTOS_CONFIG_H
#define FREERTOS_CONFIG_H

/* Scheduler Configuration */
#define configUSE_PREEMPTION                    1
#define configUSE_PORT_OPTIMISED_TASK_SELECTION 0
#define configUSE_TICKLESS_IDLE                 0
#define configCPU_CLOCK_HZ                      125000000
#define configTICK_RATE_HZ                      1000
#define configMAX_PRIORITIES                    5
#define configMINIMAL_STACK_SIZE                128
#define configMAX_TASK_NAME_LEN                 16
#define configUSE_16_BIT_TICKS                  0
#define configIDLE_SHOULD_YIELD                 1
#define configUSE_TASK_NOTIFICATIONS            1
#define configTASK_NOTIFICATION_ARRAY_ENTRIES   3
#define configUSE_MUTEXES                       1
#define configUSE_RECURSIVE_MUTEXES             0
#define configUSE_COUNTING_SEMAPHORES           1
#define configUSE_ALTERNATIVE_API               0
#define configQUEUE_REGISTRY_SIZE               10
#define configUSE_QUEUE_SETS                    0
#define configUSE_TIME_SLICING                  1
#define configUSE_NEWLIB_REENTRANT              0
#define configENABLE_BACKWARD_COMPATIBILITY     0
#define configNUM_THREAD_LOCAL_STORAGE_POINTERS 5
#define configSTACK_DEPTH_TYPE                  uint16_t
#define configMESSAGE_BUFFER_LENGTH_TYPE        size_t

/* Memory allocation */
#define configSUPPORT_STATIC_ALLOCATION         0
#define configSUPPORT_DYNAMIC_ALLOCATION        1
#define configTOTAL_HEAP_SIZE                   (128*1024)
#define configAPPLICATION_ALLOCATED_HEAP        0

/* Hook function configuration */
#define configUSE_IDLE_HOOK                     0
#define configUSE_TICK_HOOK                     0
#define configCHECK_FOR_STACK_OVERFLOW          0
#define configUSE_MALLOC_FAILED_HOOK            0
#define configUSE_DAEMON_TASK_STARTUP_HOOK      0

/* Run time and task stats */
#define configGENERATE_RUN_TIME_STATS           0
#define configUSE_TRACE_FACILITY                1
#define configUSE_STATS_FORMATTING_FUNCTIONS    0

/* Co-routine definitions */
#define configUSE_CO_ROUTINES                   0
#define configMAX_CO_ROUTINE_PRIORITIES         2

/* Software timer */
#define configUSE_TIMERS                        1
#define configTIMER_TASK_PRIORITY               (configMAX_PRIORITIES - 1)
#define configTIMER_QUEUE_LENGTH                10
#define configTIMER_TASK_STACK_DEPTH            configMINIMAL_STACK_SIZE

/* Interrupt nesting behaviour configuration */
#define configKERNEL_INTERRUPT_PRIORITY         255
#define configMAX_SYSCALL_INTERRUPT_PRIORITY    191
#define configMAX_API_CALL_INTERRUPT_PRIORITY   191

/* MPU configuration - disabled for RP2040 */
#define configENABLE_MPU                        0

/* RP2040 specific */
#define configSUPPORT_PICO_SYNC_INTEROP         1
#define configSUPPORT_PICO_TIME_INTEROP         1

/* Set the following definitions to 1 to include the API function */
#define INCLUDE_vTaskPrioritySet                1
#define INCLUDE_uxTaskPriorityGet               1
#define INCLUDE_vTaskDelete                     1
#define INCLUDE_vTaskSuspend                    1
#define INCLUDE_xResumeFromISR                  1
#define INCLUDE_vTaskDelayUntil                 1
#define INCLUDE_vTaskDelay                      1
#define INCLUDE_xTaskGetSchedulerState          1
#define INCLUDE_xTaskGetCurrentTaskHandle       1
#define INCLUDE_uxTaskGetStackHighWaterMark     1
#define INCLUDE_xTaskGetIdleTaskHandle          1
#define INCLUDE_eTaskGetState                   1
#define INCLUDE_xEventGroupSetBitFromISR        1
#define INCLUDE_xTimerPendFunctionCall          1
#define INCLUDE_xTaskAbortDelay                 1
#define INCLUDE_xTaskGetHandle                  1
#define INCLUDE_xTaskResumeFromISR              1

/* A header file that defines trace macro can be included here */

#endif /* FREERTOS_CONFIG_H */
EOF

# Create .gitignore
cat > .gitignore << 'EOF'
build/
.vscode/
*.swp
*.swo
EOF

# Clone FreeRTOS-Kernel (not as submodule since firmware/ is gitignored)
echo "Cloning FreeRTOS-Kernel..."
cd /workspace/firmware/freeRTOS
if [ ! -d "FreeRTOS-Kernel" ]; then
    git clone https://github.com/FreeRTOS/FreeRTOS-Kernel.git --depth 1
fi

echo "FreeRTOS project created successfully in firmware/freeRTOS/"
echo "To build: cd firmware/freeRTOS && mkdir build && cd build && cmake -DPICO_SDK_PATH=/opt/pico-sdk .. && make"
#!/bin/bash
#==============================================================================
# FreeRTOS Project Initialization Script for Raspberry Pi Pico
# Creates a production-ready FreeRTOS project template
#==============================================================================

set -euo pipefail

# Configuration
WORKSPACE_DIR="/workspace"
PROJECT_DIR="${WORKSPACE_DIR}/firmware/freeRTOS"
PROJECT_NAME="${PROJECT_NAME:-freertos_app}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Change to workspace directory
cd "${WORKSPACE_DIR}"

# Check if project already exists
if [ -d "${PROJECT_DIR}" ] && [ -f "${PROJECT_DIR}/CMakeLists.txt" ]; then
    log_warn "FreeRTOS project already exists in ${PROJECT_DIR}/"
    log_info "To reinitialize, remove the directory first: rm -rf ${PROJECT_DIR}"
    exit 0
fi

log_info "Creating FreeRTOS project structure..."

# Create directory structure
mkdir -p "${PROJECT_DIR}"/{src,include,drivers,config}

cd "${PROJECT_DIR}"

# Create CMakeLists.txt
log_info "Creating CMakeLists.txt..."
cat > CMakeLists.txt << 'EOF'
#==============================================================================
# FreeRTOS Project for Raspberry Pi Pico
# Production-ready CMake configuration
#==============================================================================
cmake_minimum_required(VERSION 3.13)

# Project configuration - customize these for your project
set(PROJECT_NAME "freertos_app" CACHE STRING "Project name")
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
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Compiler warnings for production code
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    add_compile_options(-Wall -Wextra -Wpedantic -g3 -O0)
    add_compile_definitions(DEBUG=1)
else()
    add_compile_options(-Wall -Wextra -Os)
    add_compile_definitions(NDEBUG=1)
endif()

# Initialize the SDK
pico_sdk_init()

#------------------------------------------------------------------------------
# FreeRTOS Configuration
#------------------------------------------------------------------------------
set(FREERTOS_KERNEL_PATH ${CMAKE_CURRENT_SOURCE_DIR}/FreeRTOS-Kernel)

# Create config interface library for FreeRTOSConfig.h
add_library(freertos_config INTERFACE)
target_include_directories(freertos_config SYSTEM INTERFACE 
    ${CMAKE_CURRENT_SOURCE_DIR}/config
)

# Set the FreeRTOS port based on the target platform
# RP2350 (Pico 2) uses ARM Cortex-M33, RP2040 uses ARM Cortex-M0+
if(PICO_PLATFORM MATCHES "rp2350")
    set(FREERTOS_PORT GCC_ARM_CM33_NTZ_NONSECURE CACHE STRING "FreeRTOS port" FORCE)
    # Pass RP2350 define to FreeRTOSConfig.h
    target_compile_definitions(freertos_config INTERFACE
        PICO_RP2350=1
    )
else()
    set(FREERTOS_PORT GCC_RP2040 CACHE STRING "FreeRTOS port")
endif()

# Heap implementation: heap_4 recommended for most applications
# heap_1: simplest, no free
# heap_2: best fit, no coalescing
# heap_3: wraps standard malloc/free
# heap_4: first fit with coalescing (recommended)
# heap_5: spans multiple non-contiguous memory regions
set(FREERTOS_HEAP 4 CACHE STRING "FreeRTOS heap implementation")

# Add FreeRTOS kernel
add_subdirectory(${FREERTOS_KERNEL_PATH} FreeRTOS-Kernel)

#------------------------------------------------------------------------------
# Application Sources
#------------------------------------------------------------------------------
set(APP_SOURCES
    src/main.c
    src/app_tasks.c
    src/app_hooks.c
    drivers/led_driver.c
)

set(APP_HEADERS
    include
    config
)

# Create executable
add_executable(${PROJECT_NAME} ${APP_SOURCES})

# Include directories
target_include_directories(${PROJECT_NAME} PRIVATE ${APP_HEADERS})

#------------------------------------------------------------------------------
# Link Libraries
#------------------------------------------------------------------------------
target_link_libraries(${PROJECT_NAME} PRIVATE
    pico_stdlib
    pico_multicore
    hardware_gpio
    hardware_timer
    hardware_watchdog
    freertos_kernel
)

# Add Pico W wireless support if needed
if(PICO_BOARD STREQUAL "pico_w" OR PICO_BOARD STREQUAL "pico2_w")
    target_link_libraries(${PROJECT_NAME} PRIVATE
        pico_cyw43_arch_none
    )
    target_compile_definitions(${PROJECT_NAME} PRIVATE
        PICO_CYW43_SUPPORTED=1
    )
endif()

#------------------------------------------------------------------------------
# STDIO Configuration
#------------------------------------------------------------------------------
# USB CDC for debug output (disable UART to save pins)
pico_enable_stdio_usb(${PROJECT_NAME} 1)
pico_enable_stdio_uart(${PROJECT_NAME} 0)

#------------------------------------------------------------------------------
# Output Files
#------------------------------------------------------------------------------
# Generate map/bin/hex/uf2/dis files
pico_add_extra_outputs(${PROJECT_NAME})

# Generate disassembly for debugging
add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
    COMMAND ${CMAKE_OBJDUMP} -h -S $<TARGET_FILE:${PROJECT_NAME}> > ${PROJECT_NAME}.dis
    COMMENT "Generating disassembly file"
)

#------------------------------------------------------------------------------
# Build Information
#------------------------------------------------------------------------------
message(STATUS "========================================")
message(STATUS "Project: ${PROJECT_NAME} v${PROJECT_VERSION}")
message(STATUS "Build Type: ${CMAKE_BUILD_TYPE}")
message(STATUS "Board: ${PICO_BOARD}")
message(STATUS "FreeRTOS Port: ${FREERTOS_PORT}")
message(STATUS "FreeRTOS Heap: heap_${FREERTOS_HEAP}")
message(STATUS "========================================")
EOF

# Create main.c in src directory
log_info "Creating application source files..."
cat > src/main.c << 'EOF'
/**
 * @file main.c
 * @brief Main application entry point for FreeRTOS on Raspberry Pi Pico
 * 
 * This is a production-ready template demonstrating:
 * - Proper FreeRTOS initialization
 * - Multiple task creation
 * - Hardware abstraction
 * - Debug output via USB CDC
 * 
 * @version 1.0.0
 */

#include <stdio.h>
#include <stdlib.h>
#include "pico/stdlib.h"
#include "hardware/watchdog.h"

#include "FreeRTOS.h"
#include "task.h"
#include "semphr.h"

#include "app_config.h"
#include "app_tasks.h"
#include "led_driver.h"

/*============================================================================*/
/* Version Information                                                         */
/*============================================================================*/
#define APP_VERSION_MAJOR   1
#define APP_VERSION_MINOR   0
#define APP_VERSION_PATCH   0

/*============================================================================*/
/* Private Function Prototypes                                                 */
/*============================================================================*/
static void prvSystemInit(void);
static void prvPrintBanner(void);

/*============================================================================*/
/* Main Entry Point                                                            */
/*============================================================================*/

/**
 * @brief Application entry point
 * 
 * Initializes hardware, creates FreeRTOS tasks, and starts the scheduler.
 * This function should never return.
 * 
 * @return int Never returns under normal operation
 */
int main(void)
{
    /* Initialize system hardware */
    prvSystemInit();
    
    /* Print startup banner */
    prvPrintBanner();
    
    /* Initialize LED driver */
    if (led_driver_init() != 0) {
        printf("[ERROR] LED driver initialization failed\n");
    }
    
    /* Create application tasks */
    if (app_tasks_create() != pdPASS) {
        printf("[ERROR] Failed to create application tasks\n");
        /* In production, you might want to enter a safe mode or reset */
        while (1) {
            tight_loop_contents();
        }
    }
    
    printf("[INFO] Starting FreeRTOS scheduler...\n");
    
    /* Start the FreeRTOS scheduler - this should never return */
    vTaskStartScheduler();
    
    /* 
     * If we get here, there was insufficient heap memory to create 
     * the idle task or timer task
     */
    printf("[FATAL] Scheduler failed to start - insufficient memory\n");
    
    while (1) {
        tight_loop_contents();
    }
    
    return 0; /* Never reached */
}

/*============================================================================*/
/* Private Functions                                                           */
/*============================================================================*/

/**
 * @brief Initialize system hardware
 */
static void prvSystemInit(void)
{
    /* Initialize stdio for USB CDC debug output */
    stdio_init_all();
    
    /* Wait for USB CDC connection in debug builds */
#ifdef DEBUG
    /* Give time for USB to enumerate */
    sleep_ms(2000);
#endif
    
#if APP_WATCHDOG_ENABLED
    /* Enable watchdog with configured timeout */
    if (watchdog_caused_reboot()) {
        printf("[WARN] System rebooted due to watchdog timeout\n");
    }
    watchdog_enable(APP_WATCHDOG_TIMEOUT_MS, true);
#endif
}

/**
 * @brief Print startup banner with version information
 */
static void prvPrintBanner(void)
{
    printf("\n");
    printf("========================================\n");
    printf("  FreeRTOS Application v%d.%d.%d\n", 
           APP_VERSION_MAJOR, APP_VERSION_MINOR, APP_VERSION_PATCH);
    printf("  Board: %s\n", PICO_BOARD);
    printf("  FreeRTOS: %s\n", tskKERNEL_VERSION_NUMBER);
    printf("========================================\n");
    printf("\n");
}
EOF

# Create app_tasks.c
cat > src/app_tasks.c << 'EOF'
/**
 * @file app_tasks.c
 * @brief Application task implementations
 */

#include <stdio.h>
#include "pico/stdlib.h"
#include "hardware/watchdog.h"

#include "FreeRTOS.h"
#include "task.h"
#include "semphr.h"
#include "timers.h"

#include "app_config.h"
#include "app_tasks.h"
#include "led_driver.h"

/*============================================================================*/
/* Task Handles                                                                */
/*============================================================================*/
static TaskHandle_t xHeartbeatTaskHandle = NULL;
static TaskHandle_t xMainTaskHandle = NULL;
static TaskHandle_t xMonitorTaskHandle = NULL;

/*============================================================================*/
/* Semaphores and Mutexes                                                      */
/*============================================================================*/
static SemaphoreHandle_t xPrintMutex = NULL;

/*============================================================================*/
/* Task Function Prototypes                                                    */
/*============================================================================*/
static void prvHeartbeatTask(void *pvParameters);
static void prvMainTask(void *pvParameters);
static void prvMonitorTask(void *pvParameters);

/*============================================================================*/
/* Public Functions                                                            */
/*============================================================================*/

/**
 * @brief Create all application tasks
 * 
 * @return BaseType_t pdPASS if all tasks created successfully
 */
BaseType_t app_tasks_create(void)
{
    BaseType_t xResult = pdPASS;
    
    /* Create print mutex for thread-safe printf */
    xPrintMutex = xSemaphoreCreateMutex();
    if (xPrintMutex == NULL) {
        return pdFAIL;
    }
    
    /* Create heartbeat task - LED blink for visual feedback */
    xResult = xTaskCreate(
        prvHeartbeatTask,
        "Heartbeat",
        TASK_HEARTBEAT_STACK_SIZE,
        NULL,
        TASK_HEARTBEAT_PRIORITY,
        &xHeartbeatTaskHandle
    );
    
    if (xResult != pdPASS) {
        return xResult;
    }
    
    /* Create main application task */
    xResult = xTaskCreate(
        prvMainTask,
        "Main",
        TASK_MAIN_STACK_SIZE,
        NULL,
        TASK_MAIN_PRIORITY,
        &xMainTaskHandle
    );
    
    if (xResult != pdPASS) {
        return xResult;
    }
    
    /* Create system monitor task */
    xResult = xTaskCreate(
        prvMonitorTask,
        "Monitor",
        TASK_MONITOR_STACK_SIZE,
        NULL,
        TASK_MONITOR_PRIORITY,
        &xMonitorTaskHandle
    );
    
    return xResult;
}

/**
 * @brief Thread-safe printf wrapper
 */
void app_printf(const char *format, ...)
{
    va_list args;
    
    if (xSemaphoreTake(xPrintMutex, pdMS_TO_TICKS(100)) == pdTRUE) {
        va_start(args, format);
        vprintf(format, args);
        va_end(args);
        xSemaphoreGive(xPrintMutex);
    }
}

/*============================================================================*/
/* Task Implementations                                                        */
/*============================================================================*/

/**
 * @brief Heartbeat task - blinks LED to indicate system is running
 */
static void prvHeartbeatTask(void *pvParameters)
{
    (void)pvParameters;
    
    TickType_t xLastWakeTime = xTaskGetTickCount();
    
    for (;;) {
        led_driver_toggle();
        
#if APP_WATCHDOG_ENABLED
        /* Kick the watchdog */
        watchdog_update();
#endif
        
        /* Use vTaskDelayUntil for precise timing */
        vTaskDelayUntil(&xLastWakeTime, pdMS_TO_TICKS(APP_HEARTBEAT_PERIOD_MS));
    }
}

/**
 * @brief Main application task
 * 
 * This is where your main application logic goes.
 * Expand this task to implement your production functionality.
 */
static void prvMainTask(void *pvParameters)
{
    (void)pvParameters;
    
    uint32_t ulLoopCount = 0;
    
    app_printf("[Main] Task started\n");
    
    for (;;) {
        /* 
         * TODO: Add your main application logic here
         * 
         * Example areas to expand:
         * - Sensor reading and processing
         * - Communication protocols (I2C, SPI, UART)
         * - State machine implementation
         * - Data logging
         * - Command processing
         */
        
        ulLoopCount++;
        
        /* Periodic status update */
        if ((ulLoopCount % 10) == 0) {
            app_printf("[Main] Loop iteration: %lu\n", ulLoopCount);
        }
        
        vTaskDelay(pdMS_TO_TICKS(1000));
    }
}

/**
 * @brief System monitor task - tracks system health
 */
static void prvMonitorTask(void *pvParameters)
{
    (void)pvParameters;
    
    app_printf("[Monitor] Task started\n");
    
    for (;;) {
        /* Report heap statistics */
        size_t xFreeHeap = xPortGetFreeHeapSize();
        size_t xMinFreeHeap = xPortGetMinimumEverFreeHeapSize();
        
        app_printf("[Monitor] Heap: %u free, %u min ever free\n", 
                   xFreeHeap, xMinFreeHeap);
        
        /* Check for low memory condition */
        if (xFreeHeap < APP_LOW_MEMORY_THRESHOLD) {
            app_printf("[WARN] Low memory condition detected!\n");
        }
        
        /* Report task stack high water marks */
#if configUSE_TRACE_FACILITY
        UBaseType_t uxHighWaterMark;
        
        uxHighWaterMark = uxTaskGetStackHighWaterMark(xHeartbeatTaskHandle);
        app_printf("[Monitor] Heartbeat stack HWM: %u words\n", uxHighWaterMark);
        
        uxHighWaterMark = uxTaskGetStackHighWaterMark(xMainTaskHandle);
        app_printf("[Monitor] Main stack HWM: %u words\n", uxHighWaterMark);
#endif
        
        vTaskDelay(pdMS_TO_TICKS(APP_MONITOR_PERIOD_MS));
    }
}
EOF

# Create app_hooks.c
cat > src/app_hooks.c << 'EOF'
/**
 * @file app_hooks.c
 * @brief FreeRTOS hook function implementations
 * 
 * These hooks are called by the FreeRTOS kernel at specific events.
 * Enable/disable via FreeRTOSConfig.h defines.
 */

#include <stdio.h>
#include "pico/stdlib.h"
#include "hardware/watchdog.h"

#include "FreeRTOS.h"
#include "task.h"

#include "app_config.h"

/*============================================================================*/
/* FreeRTOS Hook Implementations                                               */
/*============================================================================*/

#if configUSE_IDLE_HOOK
/**
 * @brief Idle hook - called during idle task execution
 * 
 * Use for low-priority background tasks or power management.
 * Must NOT block or call any blocking FreeRTOS functions.
 */
void vApplicationIdleHook(void)
{
    /* 
     * Optional: Put processor into low power mode
     * __wfi(); // Wait for interrupt
     */
}
#endif

#if configUSE_TICK_HOOK
/**
 * @brief Tick hook - called from each tick interrupt
 * 
 * Must be very fast - runs in ISR context.
 */
void vApplicationTickHook(void)
{
    /* Tick hook - keep minimal */
}
#endif

#if configCHECK_FOR_STACK_OVERFLOW
/**
 * @brief Stack overflow hook - called when stack overflow detected
 * 
 * @param xTask Handle of the offending task
 * @param pcTaskName Name of the offending task
 */
void vApplicationStackOverflowHook(TaskHandle_t xTask, char *pcTaskName)
{
    (void)xTask;
    
    printf("\n[FATAL] Stack overflow in task: %s\n", pcTaskName);
    
    /* Disable interrupts and halt */
    taskDISABLE_INTERRUPTS();
    
    /* In production, you might want to:
     * - Log the error to flash
     * - Perform a controlled reset
     * - Enter a safe mode
     */
    
    for (;;) {
        tight_loop_contents();
    }
}
#endif

#if configUSE_MALLOC_FAILED_HOOK
/**
 * @brief Malloc failed hook - called when pvPortMalloc fails
 */
void vApplicationMallocFailedHook(void)
{
    printf("\n[FATAL] Memory allocation failed!\n");
    
    /* Report remaining heap */
    printf("Free heap: %u bytes\n", xPortGetFreeHeapSize());
    
    taskDISABLE_INTERRUPTS();
    
    for (;;) {
        tight_loop_contents();
    }
}
#endif

#if configUSE_DAEMON_TASK_STARTUP_HOOK
/**
 * @brief Daemon task startup hook
 * 
 * Called once when the timer daemon task starts executing.
 */
void vApplicationDaemonTaskStartupHook(void)
{
    printf("[INFO] Timer daemon task started\n");
}
#endif

#if configSUPPORT_STATIC_ALLOCATION
/**
 * @brief Get idle task memory for static allocation
 */
void vApplicationGetIdleTaskMemory(StaticTask_t **ppxIdleTaskTCBBuffer,
                                    StackType_t **ppxIdleTaskStackBuffer,
                                    uint32_t *pulIdleTaskStackSize)
{
    static StaticTask_t xIdleTaskTCB;
    static StackType_t uxIdleTaskStack[configMINIMAL_STACK_SIZE];
    
    *ppxIdleTaskTCBBuffer = &xIdleTaskTCB;
    *ppxIdleTaskStackBuffer = uxIdleTaskStack;
    *pulIdleTaskStackSize = configMINIMAL_STACK_SIZE;
}

/**
 * @brief Get timer task memory for static allocation
 */
void vApplicationGetTimerTaskMemory(StaticTask_t **ppxTimerTaskTCBBuffer,
                                     StackType_t **ppxTimerTaskStackBuffer,
                                     uint32_t *pulTimerTaskStackSize)
{
    static StaticTask_t xTimerTaskTCB;
    static StackType_t uxTimerTaskStack[configTIMER_TASK_STACK_DEPTH];
    
    *ppxTimerTaskTCBBuffer = &xTimerTaskTCB;
    *ppxTimerTaskStackBuffer = uxTimerTaskStack;
    *pulTimerTaskStackSize = configTIMER_TASK_STACK_DEPTH;
}
#endif
EOF

# Create LED driver
log_info "Creating LED driver..."
cat > drivers/led_driver.c << 'EOF'
/**
 * @file led_driver.c
 * @brief LED driver abstraction for Raspberry Pi Pico
 * 
 * Handles differences between Pico (GPIO LED) and Pico W (CYW43 LED)
 */

#include "pico/stdlib.h"
#include "led_driver.h"

#ifdef PICO_CYW43_SUPPORTED
#include "pico/cyw43_arch.h"
#endif

/*============================================================================*/
/* Private Variables                                                           */
/*============================================================================*/
static bool s_led_state = false;
static bool s_initialized = false;

/*============================================================================*/
/* Public Functions                                                            */
/*============================================================================*/

/**
 * @brief Initialize LED hardware
 * 
 * @return 0 on success, -1 on failure
 */
int led_driver_init(void)
{
    if (s_initialized) {
        return 0;
    }
    
#ifdef PICO_CYW43_SUPPORTED
    /* Pico W uses CYW43 chip for LED */
    if (cyw43_arch_init() != 0) {
        return -1;
    }
#else
    /* Standard Pico uses GPIO 25 for LED */
    gpio_init(PICO_DEFAULT_LED_PIN);
    gpio_set_dir(PICO_DEFAULT_LED_PIN, GPIO_OUT);
#endif
    
    s_initialized = true;
    s_led_state = false;
    led_driver_set(false);
    
    return 0;
}

/**
 * @brief Set LED state
 * 
 * @param on true to turn on, false to turn off
 */
void led_driver_set(bool on)
{
    if (!s_initialized) {
        return;
    }
    
    s_led_state = on;
    
#ifdef PICO_CYW43_SUPPORTED
    cyw43_arch_gpio_put(CYW43_WL_GPIO_LED_PIN, on ? 1 : 0);
#else
    gpio_put(PICO_DEFAULT_LED_PIN, on ? 1 : 0);
#endif
}

/**
 * @brief Toggle LED state
 */
void led_driver_toggle(void)
{
    led_driver_set(!s_led_state);
}

/**
 * @brief Get current LED state
 * 
 * @return true if LED is on
 */
bool led_driver_get_state(void)
{
    return s_led_state;
}
EOF

# Create include headers
log_info "Creating header files..."
cat > include/led_driver.h << 'EOF'
/**
 * @file led_driver.h
 * @brief LED driver interface
 */

#ifndef LED_DRIVER_H
#define LED_DRIVER_H

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Initialize LED hardware
 * @return 0 on success, -1 on failure
 */
int led_driver_init(void);

/**
 * @brief Set LED state
 * @param on true to turn on, false to turn off
 */
void led_driver_set(bool on);

/**
 * @brief Toggle LED state
 */
void led_driver_toggle(void);

/**
 * @brief Get current LED state
 * @return true if LED is on
 */
bool led_driver_get_state(void);

#ifdef __cplusplus
}
#endif

#endif /* LED_DRIVER_H */
EOF

cat > include/app_tasks.h << 'EOF'
/**
 * @file app_tasks.h
 * @brief Application task interface
 */

#ifndef APP_TASKS_H
#define APP_TASKS_H

#include "FreeRTOS.h"
#include <stdarg.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Create all application tasks
 * @return pdPASS if all tasks created successfully
 */
BaseType_t app_tasks_create(void);

/**
 * @brief Thread-safe printf wrapper
 * @param format Printf format string
 * @param ... Variable arguments
 */
void app_printf(const char *format, ...);

#ifdef __cplusplus
}
#endif

#endif /* APP_TASKS_H */
EOF

cat > include/app_config.h << 'EOF'
/**
 * @file app_config.h
 * @brief Application configuration parameters
 * 
 * Centralized configuration for easy customization
 */

#ifndef APP_CONFIG_H
#define APP_CONFIG_H

/*============================================================================*/
/* Application Parameters                                                      */
/*============================================================================*/

/* LED heartbeat period in milliseconds */
#define APP_HEARTBEAT_PERIOD_MS         500

/* System monitor reporting period in milliseconds */
#define APP_MONITOR_PERIOD_MS           10000

/* Low memory warning threshold in bytes */
#define APP_LOW_MEMORY_THRESHOLD        4096

/*============================================================================*/
/* Watchdog Configuration                                                      */
/*============================================================================*/

/* Enable/disable watchdog timer */
#define APP_WATCHDOG_ENABLED            0

/* Watchdog timeout in milliseconds (max 8300ms) */
#define APP_WATCHDOG_TIMEOUT_MS         5000

/*============================================================================*/
/* Task Configuration                                                          */
/*============================================================================*/

/* Task priorities (higher number = higher priority) */
#define TASK_HEARTBEAT_PRIORITY         (tskIDLE_PRIORITY + 1)
#define TASK_MAIN_PRIORITY              (tskIDLE_PRIORITY + 2)
#define TASK_MONITOR_PRIORITY           (tskIDLE_PRIORITY + 1)

/* Task stack sizes in words (multiply by 4 for bytes) */
#define TASK_HEARTBEAT_STACK_SIZE       256
#define TASK_MAIN_STACK_SIZE            512
#define TASK_MONITOR_STACK_SIZE         512

/*============================================================================*/
/* Debug Configuration                                                         */
/*============================================================================*/

#ifndef DEBUG
#define DEBUG                           0
#endif

#endif /* APP_CONFIG_H */
EOF

# Create pico_sdk_import.cmake
log_info "Creating pico_sdk_import.cmake..."
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

# Create FreeRTOSConfig.h in config directory
log_info "Creating FreeRTOSConfig.h..."
cat > config/FreeRTOSConfig.h << 'EOF'
/**
 * @file FreeRTOSConfig.h
 * @brief FreeRTOS Kernel Configuration for Raspberry Pi Pico
 * 
 * Production-ready configuration with recommended settings.
 * Modify as needed for your specific application requirements.
 */

#ifndef FREERTOS_CONFIG_H
#define FREERTOS_CONFIG_H

/*============================================================================*/
/* Hardware Configuration                                                      */
/*============================================================================*/

/* RP2040 runs at 125MHz by default, RP2350 at 150MHz */
#ifdef PICO_RP2350
#define configCPU_CLOCK_HZ                      150000000
#else
#define configCPU_CLOCK_HZ                      125000000
#endif

/*============================================================================*/
/* Scheduler Configuration                                                     */
/*============================================================================*/

#define configUSE_PREEMPTION                    1
#define configUSE_PORT_OPTIMISED_TASK_SELECTION 0
#define configUSE_TICKLESS_IDLE                 0
#define configTICK_RATE_HZ                      1000
#define configMAX_PRIORITIES                    8
#define configMINIMAL_STACK_SIZE                256
#define configMAX_TASK_NAME_LEN                 32
#define configUSE_16_BIT_TICKS                  0
#define configIDLE_SHOULD_YIELD                 1
#define configUSE_TIME_SLICING                  1

/*============================================================================*/
/* Task Features                                                               */
/*============================================================================*/

#define configUSE_TASK_NOTIFICATIONS            1
#define configTASK_NOTIFICATION_ARRAY_ENTRIES   4
#define configUSE_MUTEXES                       1
#define configUSE_RECURSIVE_MUTEXES             1
#define configUSE_COUNTING_SEMAPHORES           1
#define configUSE_QUEUE_SETS                    1
#define configQUEUE_REGISTRY_SIZE               16
#define configUSE_NEWLIB_REENTRANT              0
#define configENABLE_BACKWARD_COMPATIBILITY     0
#define configNUM_THREAD_LOCAL_STORAGE_POINTERS 5
#define configSTACK_DEPTH_TYPE                  uint32_t
#define configMESSAGE_BUFFER_LENGTH_TYPE        size_t

/*============================================================================*/
/* Memory Configuration                                                        */
/*============================================================================*/

#define configSUPPORT_STATIC_ALLOCATION         1
#define configSUPPORT_DYNAMIC_ALLOCATION        1

/* Total heap size - adjust based on your application needs */
/* RP2040 has 264KB SRAM, RP2350 has 520KB SRAM */
#ifdef PICO_RP2350
#define configTOTAL_HEAP_SIZE                   (256 * 1024)
#else
#define configTOTAL_HEAP_SIZE                   (128 * 1024)
#endif

#define configAPPLICATION_ALLOCATED_HEAP        0

/*============================================================================*/
/* Hook Functions - Enable for debugging                                       */
/*============================================================================*/

#define configUSE_IDLE_HOOK                     0
#define configUSE_TICK_HOOK                     0
#define configCHECK_FOR_STACK_OVERFLOW          2  /* Method 2 is more thorough */
#define configUSE_MALLOC_FAILED_HOOK            1
#define configUSE_DAEMON_TASK_STARTUP_HOOK      0

/*============================================================================*/
/* Runtime Statistics                                                          */
/*============================================================================*/

#define configGENERATE_RUN_TIME_STATS           0
#define configUSE_TRACE_FACILITY                1
#define configUSE_STATS_FORMATTING_FUNCTIONS    1

/*============================================================================*/
/* Co-routine Configuration (deprecated, keep disabled)                        */
/*============================================================================*/

#define configUSE_CO_ROUTINES                   0
#define configMAX_CO_ROUTINE_PRIORITIES         2

/*============================================================================*/
/* Software Timer Configuration                                                */
/*============================================================================*/

#define configUSE_TIMERS                        1
#define configTIMER_TASK_PRIORITY               (configMAX_PRIORITIES - 1)
#define configTIMER_QUEUE_LENGTH                16
#define configTIMER_TASK_STACK_DEPTH            (configMINIMAL_STACK_SIZE * 2)

/*============================================================================*/
/* Interrupt Configuration                                                     */
/*============================================================================*/

#define configKERNEL_INTERRUPT_PRIORITY         255
#define configMAX_SYSCALL_INTERRUPT_PRIORITY    191
#define configMAX_API_CALL_INTERRUPT_PRIORITY   191

/*============================================================================*/
/* ARM Cortex-M33 Specific Configuration (RP2350/Pico 2)                       */
/* These must be defined BEFORE FreeRTOS headers are included                  */
/*============================================================================*/

#if defined(PICO_RP2350) || defined(PICO_PLATFORM_RP2350)
/* Enable FPU support - RP2350 has FPU */
#define configENABLE_FPU                        1

/* Disable TrustZone - using non-secure mode (NTZ port) */
#define configENABLE_TRUSTZONE                  0

/* Disable MPU for now */
#define configENABLE_MPU                        0

/* Required for ARM_CM33_NTZ port - run in non-secure mode only */
#define configRUN_FREERTOS_SECURE_ONLY          1
#endif

/*============================================================================*/
/* RP2040/RP2350 Specific - Pico SDK Integration                               */
/*============================================================================*/

#define configSUPPORT_PICO_SYNC_INTEROP         1
#define configSUPPORT_PICO_TIME_INTEROP         1

/*============================================================================*/
/* Optional Function Includes                                                  */
/*============================================================================*/

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
#define INCLUDE_uxTaskGetStackHighWaterMark2    1
#define INCLUDE_xTaskGetIdleTaskHandle          1
#define INCLUDE_eTaskGetState                   1
#define INCLUDE_xEventGroupSetBitFromISR        1
#define INCLUDE_xTimerPendFunctionCall          1
#define INCLUDE_xTaskAbortDelay                 1
#define INCLUDE_xTaskGetHandle                  1
#define INCLUDE_xTaskResumeFromISR              1
#define INCLUDE_xQueueGetMutexHolder            1

/*============================================================================*/
/* Assert Configuration                                                        */
/*============================================================================*/

/* Define configASSERT for debugging */
#ifdef DEBUG
#include <stdio.h>
#define configASSERT(x) do { \
    if (!(x)) { \
        printf("ASSERT FAILED: %s, line %d\n", __FILE__, __LINE__); \
        taskDISABLE_INTERRUPTS(); \
        for(;;); \
    } \
} while(0)
#else
#define configASSERT(x) ((void)0)
#endif

#endif /* FREERTOS_CONFIG_H */
EOF

# Create README.md
log_info "Creating README.md..."
cat > README.md << 'EOF'
# FreeRTOS Project for Raspberry Pi Pico

Production-ready FreeRTOS template for Raspberry Pi Pico/Pico W/Pico 2.

## Project Structure

```
firmware/freeRTOS/
├── CMakeLists.txt          # Build configuration
├── Makefile                # Docker-based build automation
├── pico_sdk_import.cmake   # SDK integration
├── FreeRTOS-Kernel/        # FreeRTOS kernel (cloned)
├── config/
│   └── FreeRTOSConfig.h    # FreeRTOS configuration
├── src/
│   ├── main.c              # Application entry point
│   ├── app_tasks.c         # Task implementations
│   └── app_hooks.c         # FreeRTOS hook functions
├── include/
│   ├── app_config.h        # Application configuration
│   ├── app_tasks.h         # Task interface
│   └── led_driver.h        # LED driver interface
├── drivers/
│   └── led_driver.c        # LED hardware abstraction
└── build/                  # Build output (generated)
```

## Quick Start

### Using the Makefile (Recommended)

```bash
# Build for Pico
make build BOARD=pico

# Build for Pico W
make build BOARD=pico_w

# Build for Pico 2
make build BOARD=pico2

# Clean build
make clean

# Rebuild from scratch
make rebuild BOARD=pico
```

### Manual Build

```bash
mkdir build && cd build
cmake -DPICO_SDK_PATH=/opt/pico-sdk -DPICO_BOARD=pico ..
make -j$(nproc)
```

## Flashing

1. Hold **BOOTSEL** button while connecting Pico to USB
2. Copy `build/freertos_app.uf2` to the RPI-RP2 drive
3. LED will start blinking when firmware is running

## Customization

### Application Logic

Modify `src/app_tasks.c` to implement your application:
- `prvMainTask()` - Main application logic
- `prvHeartbeatTask()` - LED heartbeat (modify period in `app_config.h`)
- `prvMonitorTask()` - System health monitoring

### Configuration

- `include/app_config.h` - Application parameters
- `config/FreeRTOSConfig.h` - FreeRTOS kernel settings

### Adding New Tasks

1. Define task function in `src/app_tasks.c`
2. Add task creation in `app_tasks_create()`
3. Add stack size and priority defines in `include/app_config.h`

### Adding Hardware Drivers

1. Create driver in `drivers/` directory
2. Add header in `include/` directory
3. Add source file to `CMakeLists.txt` APP_SOURCES

## Debug Output

Connect via USB serial (115200 baud) to see debug output:
```bash
minicom -D /dev/ttyACM0 -b 115200
```

## License

MIT License - See LICENSE file for details.
EOF

# Create project-level Makefile
log_info "Creating project Makefile..."
cat > Makefile << 'EOF'
#==============================================================================
# FreeRTOS Project Makefile
# Docker-based build automation for Raspberry Pi Pico
#==============================================================================

# Default board
BOARD ?= pico

# Docker configuration
IMAGE_NAME := rpi-pico-dev
PROJECT_ROOT := $(shell cd ../.. && pwd)
PROJECT_DIR := /workspace/firmware/freeRTOS

# Build type: Debug or Release
BUILD_TYPE ?= Release

.PHONY: help build clean rebuild shell debug release

help:
	@echo "FreeRTOS Project Build System"
	@echo ""
	@echo "Usage: make <target> [BOARD=<board>] [BUILD_TYPE=<type>]"
	@echo ""
	@echo "Targets:"
	@echo "  build    - Build the project"
	@echo "  clean    - Clean build artifacts"
	@echo "  rebuild  - Clean and rebuild"
	@echo "  shell    - Open interactive shell"
	@echo "  debug    - Build with debug symbols"
	@echo "  release  - Build optimized release"
	@echo ""
	@echo "Boards:"
	@echo "  pico     - Raspberry Pi Pico (default)"
	@echo "  pico_w   - Raspberry Pi Pico W"
	@echo "  pico2    - Raspberry Pi Pico 2"
	@echo "  pico2_w  - Raspberry Pi Pico 2 W"
	@echo ""
	@echo "Examples:"
	@echo "  make build BOARD=pico_w"
	@echo "  make debug BOARD=pico2"
	@echo "  make rebuild BOARD=pico BUILD_TYPE=Debug"

build:
	@echo "Building FreeRTOS for $(BOARD) ($(BUILD_TYPE))..."
	docker run --rm \
		--user ubuntu \
		-v $(PROJECT_ROOT):/workspace \
		$(IMAGE_NAME) \
		/bin/bash -c "\
			cd $(PROJECT_DIR) && \
			mkdir -p build && cd build && \
			cmake -DPICO_SDK_PATH=/opt/pico-sdk \
			      -DPICO_BOARD=$(BOARD) \
			      -DCMAKE_BUILD_TYPE=$(BUILD_TYPE) \
			      .. && \
			make -j\$$(nproc)"
	@echo ""
	@echo "Build complete! Output: build/freertos_app.uf2"

debug:
	$(MAKE) build BUILD_TYPE=Debug

release:
	$(MAKE) build BUILD_TYPE=Release

clean:
	@echo "Cleaning build artifacts..."
	rm -rf build

rebuild: clean build

shell:
	docker run -it --rm \
		--user ubuntu \
		-v $(PROJECT_ROOT):/workspace \
		-w $(PROJECT_DIR) \
		$(IMAGE_NAME) \
		/bin/bash
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

# Clone FreeRTOS-Kernel
log_info "Cloning FreeRTOS-Kernel..."
cd "${PROJECT_DIR}"
if [ ! -d "FreeRTOS-Kernel" ]; then
    git clone https://github.com/FreeRTOS/FreeRTOS-Kernel.git --depth 1
fi

log_success "FreeRTOS project created successfully!"
echo ""
echo "Project location: ${PROJECT_DIR}"
echo ""
echo "Quick start:"
echo "  cd ${PROJECT_DIR}"
echo "  make build BOARD=pico"
echo ""
echo "Or from project root:"
echo "  make build-freertos-pico"
echo ""
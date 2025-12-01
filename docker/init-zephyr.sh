#!/bin/bash
#==============================================================================
# Zephyr Project Initialization Script for Raspberry Pi Pico
# Creates a production-ready Zephyr project template
#==============================================================================

set -euo pipefail

# Configuration
WORKSPACE_DIR="/workspace"

# Get project name from argument or use default
if [ $# -ge 1 ]; then
    PROJECT_NAME="$1"
else
    echo "Usage: $0 <project_name>"
    echo "Example: $0 my_zephyr_app"
    exit 1
fi

PROJECT_DIR="${WORKSPACE_DIR}/firmware/${PROJECT_NAME}"
APP_NAME="${PROJECT_NAME}"

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
if [ -d "${PROJECT_DIR}" ] && [ -d "${PROJECT_DIR}/.west" ]; then
    log_warn "Zephyr project already exists in ${PROJECT_DIR}/"
    log_info "To reinitialize, remove the directory first: rm -rf ${PROJECT_DIR}"
    exit 0
fi

log_info "Creating Zephyr project structure..."

mkdir -p "${PROJECT_DIR}"
cd "${PROJECT_DIR}"

# Initialize Zephyr workspace with pico-zephyr manifest
log_info "Initializing west workspace with pico-zephyr..."
west init -m https://github.com/raspberrypi/pico-zephyr --mr main .

# Update modules
log_info "Updating Zephyr modules (this may take a while)..."
west update

# Create the production-ready application
log_info "Creating production application template..."
mkdir -p app
cd app

# Create directory structure
mkdir -p src include drivers

# Create main source file
log_info "Creating application source files..."
cat > src/main.c << 'EOF'
/**
 * @file main.c
 * @brief Main application entry point for Zephyr on Raspberry Pi Pico
 * 
 * Production-ready template demonstrating:
 * - Proper Zephyr initialization
 * - Multiple thread creation
 * - Logging subsystem
 * - Shell commands (optional)
 * - Hardware abstraction
 * 
 * @version 1.0.0
 */

#include <zephyr/kernel.h>
#include <zephyr/device.h>
#include <zephyr/drivers/gpio.h>
#include <zephyr/sys/printk.h>
#include <zephyr/logging/log.h>

#include "app_config.h"
#include "led_driver.h"

/* Register logging module */
LOG_MODULE_REGISTER(main, CONFIG_APP_LOG_LEVEL);

/*============================================================================*/
/* Version Information                                                         */
/*============================================================================*/
#define APP_VERSION_MAJOR   1
#define APP_VERSION_MINOR   0
#define APP_VERSION_PATCH   0

/*============================================================================*/
/* Thread Definitions                                                          */
/*============================================================================*/

/* Heartbeat thread */
K_THREAD_STACK_DEFINE(heartbeat_stack, CONFIG_HEARTBEAT_STACK_SIZE);
static struct k_thread heartbeat_thread_data;
static k_tid_t heartbeat_tid;

/* Main application thread */
K_THREAD_STACK_DEFINE(main_app_stack, CONFIG_MAIN_THREAD_STACK_SIZE);
static struct k_thread main_app_thread_data;
static k_tid_t main_app_tid;

/* Monitor thread */
K_THREAD_STACK_DEFINE(monitor_stack, CONFIG_MONITOR_STACK_SIZE);
static struct k_thread monitor_thread_data;
static k_tid_t monitor_tid;

/*============================================================================*/
/* Thread Entry Points                                                         */
/*============================================================================*/

/**
 * @brief Heartbeat thread - blinks LED to indicate system is running
 */
static void heartbeat_thread(void *p1, void *p2, void *p3)
{
    ARG_UNUSED(p1);
    ARG_UNUSED(p2);
    ARG_UNUSED(p3);
    
    LOG_INF("Heartbeat thread started");
    
    if (led_driver_init() != 0) {
        LOG_ERR("Failed to initialize LED driver");
        return;
    }
    
    while (1) {
        led_driver_toggle();
        k_msleep(CONFIG_HEARTBEAT_PERIOD_MS);
    }
}

/**
 * @brief Main application thread
 * 
 * This is where your main application logic goes.
 * Expand this thread to implement your production functionality.
 */
static void main_app_thread(void *p1, void *p2, void *p3)
{
    ARG_UNUSED(p1);
    ARG_UNUSED(p2);
    ARG_UNUSED(p3);
    
    uint32_t loop_count = 0;
    
    LOG_INF("Main application thread started");
    
    while (1) {
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
        
        loop_count++;
        
        /* Periodic status update */
        if ((loop_count % 10) == 0) {
            LOG_INF("Main loop iteration: %u", loop_count);
        }
        
        k_msleep(1000);
    }
}

/**
 * @brief System monitor thread - tracks system health
 */
static void monitor_thread(void *p1, void *p2, void *p3)
{
    ARG_UNUSED(p1);
    ARG_UNUSED(p2);
    ARG_UNUSED(p3);
    
    LOG_INF("Monitor thread started");
    
    while (1) {
        /* Report thread statistics */
#ifdef CONFIG_THREAD_RUNTIME_STATS
        k_thread_runtime_stats_t stats;
        
        if (k_thread_runtime_stats_get(heartbeat_tid, &stats) == 0) {
            LOG_DBG("Heartbeat thread cycles: %llu", stats.execution_cycles);
        }
#endif
        
        k_msleep(CONFIG_MONITOR_PERIOD_MS);
    }
}

/*============================================================================*/
/* Main Entry Point                                                            */
/*============================================================================*/

/**
 * @brief Application entry point
 */
int main(void)
{
    LOG_INF("========================================");
    LOG_INF("  Zephyr Application v%d.%d.%d", 
            APP_VERSION_MAJOR, APP_VERSION_MINOR, APP_VERSION_PATCH);
    LOG_INF("========================================");
    
    /* Create heartbeat thread */
    heartbeat_tid = k_thread_create(
        &heartbeat_thread_data,
        heartbeat_stack,
        K_THREAD_STACK_SIZEOF(heartbeat_stack),
        heartbeat_thread,
        NULL, NULL, NULL,
        CONFIG_HEARTBEAT_PRIORITY,
        0,
        K_NO_WAIT
    );
    k_thread_name_set(heartbeat_tid, "heartbeat");
    
    /* Create main application thread */
    main_app_tid = k_thread_create(
        &main_app_thread_data,
        main_app_stack,
        K_THREAD_STACK_SIZEOF(main_app_stack),
        main_app_thread,
        NULL, NULL, NULL,
        CONFIG_MAIN_THREAD_PRIORITY,
        0,
        K_NO_WAIT
    );
    k_thread_name_set(main_app_tid, "main_app");
    
    /* Create monitor thread */
    monitor_tid = k_thread_create(
        &monitor_thread_data,
        monitor_stack,
        K_THREAD_STACK_SIZEOF(monitor_stack),
        monitor_thread,
        NULL, NULL, NULL,
        CONFIG_MONITOR_PRIORITY,
        0,
        K_NO_WAIT
    );
    k_thread_name_set(monitor_tid, "monitor");
    
    LOG_INF("All threads started successfully");
    
    /* Main thread can exit - other threads will continue */
    return 0;
}
EOF

# Create LED driver
log_info "Creating LED driver..."
cat > drivers/led_driver.c << 'EOF'
/**
 * @file led_driver.c
 * @brief LED driver abstraction for Zephyr on Raspberry Pi Pico
 */

#include <zephyr/kernel.h>
#include <zephyr/device.h>
#include <zephyr/drivers/gpio.h>
#include <zephyr/logging/log.h>

#include "led_driver.h"

LOG_MODULE_REGISTER(led_driver, CONFIG_APP_LOG_LEVEL);

/*============================================================================*/
/* Private Variables                                                           */
/*============================================================================*/

#if DT_NODE_EXISTS(DT_ALIAS(led0))
static const struct gpio_dt_spec led = GPIO_DT_SPEC_GET(DT_ALIAS(led0), gpios);
static bool led_state = false;
static bool initialized = false;
#endif

/*============================================================================*/
/* Public Functions                                                            */
/*============================================================================*/

int led_driver_init(void)
{
#if DT_NODE_EXISTS(DT_ALIAS(led0))
    if (initialized) {
        return 0;
    }
    
    if (!gpio_is_ready_dt(&led)) {
        LOG_ERR("LED GPIO device not ready");
        return -ENODEV;
    }
    
    int ret = gpio_pin_configure_dt(&led, GPIO_OUTPUT_INACTIVE);
    if (ret < 0) {
        LOG_ERR("Failed to configure LED GPIO: %d", ret);
        return ret;
    }
    
    initialized = true;
    led_state = false;
    
    LOG_INF("LED driver initialized");
    return 0;
#else
    LOG_WRN("No LED available on this board");
    return -ENOTSUP;
#endif
}

void led_driver_set(bool on)
{
#if DT_NODE_EXISTS(DT_ALIAS(led0))
    if (!initialized) {
        return;
    }
    
    led_state = on;
    gpio_pin_set_dt(&led, on ? 1 : 0);
#endif
}

void led_driver_toggle(void)
{
#if DT_NODE_EXISTS(DT_ALIAS(led0))
    if (!initialized) {
        return;
    }
    
    led_state = !led_state;
    gpio_pin_toggle_dt(&led);
#endif
}

bool led_driver_get_state(void)
{
#if DT_NODE_EXISTS(DT_ALIAS(led0))
    return led_state;
#else
    return false;
#endif
}
EOF

# Create header files
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
 * @return 0 on success, negative error code on failure
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

cat > include/app_config.h << 'EOF'
/**
 * @file app_config.h
 * @brief Application configuration header
 * 
 * Note: Most configuration is done via Kconfig (prj.conf)
 * This header provides access to Kconfig values and any
 * additional compile-time configuration.
 */

#ifndef APP_CONFIG_H
#define APP_CONFIG_H

#include <zephyr/kernel.h>

/* Include autoconf.h for Kconfig values */
#include <autoconf.h>

/*============================================================================*/
/* Derived Configuration                                                       */
/*============================================================================*/

/* Thread priorities relative to preemptive threshold */
#ifndef CONFIG_HEARTBEAT_PRIORITY
#define CONFIG_HEARTBEAT_PRIORITY       7
#endif

#ifndef CONFIG_MAIN_THREAD_PRIORITY
#define CONFIG_MAIN_THREAD_PRIORITY     5
#endif

#ifndef CONFIG_MONITOR_PRIORITY
#define CONFIG_MONITOR_PRIORITY         8
#endif

/* Stack sizes */
#ifndef CONFIG_HEARTBEAT_STACK_SIZE
#define CONFIG_HEARTBEAT_STACK_SIZE     512
#endif

#ifndef CONFIG_MAIN_THREAD_STACK_SIZE
#define CONFIG_MAIN_THREAD_STACK_SIZE   1024
#endif

#ifndef CONFIG_MONITOR_STACK_SIZE
#define CONFIG_MONITOR_STACK_SIZE       768
#endif

/* Timing */
#ifndef CONFIG_HEARTBEAT_PERIOD_MS
#define CONFIG_HEARTBEAT_PERIOD_MS      500
#endif

#ifndef CONFIG_MONITOR_PERIOD_MS
#define CONFIG_MONITOR_PERIOD_MS        10000
#endif

#endif /* APP_CONFIG_H */
EOF

# Create CMakeLists.txt
log_info "Creating CMakeLists.txt..."
cat > CMakeLists.txt << 'EOF'
#==============================================================================
# Zephyr Application CMake Configuration
# Production-ready template for Raspberry Pi Pico
#==============================================================================
cmake_minimum_required(VERSION 3.20.0)

# Find Zephyr package
find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})

# Project definition
project(zephyr_app
    VERSION 1.0.0
    LANGUAGES C
)

# Source files
set(APP_SOURCES
    src/main.c
    drivers/led_driver.c
)

# Add application sources
target_sources(app PRIVATE ${APP_SOURCES})

# Include directories
target_include_directories(app PRIVATE
    include
)
EOF

# Create Kconfig
log_info "Creating Kconfig..."
cat > Kconfig << 'EOF'
#==============================================================================
# Application Kconfig
#==============================================================================

mainmenu "Zephyr Application Configuration"

# Source Zephyr Kconfig
source "Kconfig.zephyr"

menu "Application Configuration"

config APP_LOG_LEVEL
    int "Application log level"
    default 3
    range 0 4
    help
      Log level for application modules.
      0 = OFF, 1 = ERR, 2 = WRN, 3 = INF, 4 = DBG

config HEARTBEAT_PERIOD_MS
    int "Heartbeat LED period in milliseconds"
    default 500
    help
      Period for the heartbeat LED blink.

config HEARTBEAT_PRIORITY
    int "Heartbeat thread priority"
    default 7
    help
      Priority of the heartbeat thread.

config HEARTBEAT_STACK_SIZE
    int "Heartbeat thread stack size"
    default 512
    help
      Stack size for the heartbeat thread.

config MAIN_THREAD_PRIORITY
    int "Main application thread priority"
    default 5
    help
      Priority of the main application thread.

config MAIN_THREAD_STACK_SIZE
    int "Main application thread stack size"
    default 1024
    help
      Stack size for the main application thread.

config MONITOR_PRIORITY
    int "Monitor thread priority"
    default 8
    help
      Priority of the system monitor thread.

config MONITOR_STACK_SIZE
    int "Monitor thread stack size"
    default 768
    help
      Stack size for the monitor thread.

config MONITOR_PERIOD_MS
    int "Monitor reporting period in milliseconds"
    default 10000
    help
      Period for system health reporting.

endmenu
EOF

# Create prj.conf
log_info "Creating prj.conf..."
cat > prj.conf << 'EOF'
#==============================================================================
# Zephyr Application Configuration
# Production-ready settings for Raspberry Pi Pico
#==============================================================================

#------------------------------------------------------------------------------
# General Settings
#------------------------------------------------------------------------------
CONFIG_MAIN_STACK_SIZE=2048
CONFIG_HEAP_MEM_POOL_SIZE=8192

#------------------------------------------------------------------------------
# Drivers
#------------------------------------------------------------------------------
CONFIG_GPIO=y

#------------------------------------------------------------------------------
# C Library
#------------------------------------------------------------------------------
CONFIG_PICOLIBC=y

#------------------------------------------------------------------------------
# Logging
#------------------------------------------------------------------------------
CONFIG_LOG=y
CONFIG_LOG_MODE_IMMEDIATE=y
CONFIG_LOG_BACKEND_UART=y
CONFIG_LOG_DEFAULT_LEVEL=3

#------------------------------------------------------------------------------
# Console/Shell (optional - enable for debugging)
#------------------------------------------------------------------------------
CONFIG_CONSOLE=y
CONFIG_UART_CONSOLE=y
# CONFIG_SHELL=y
# CONFIG_SHELL_BACKEND_SERIAL=y

#------------------------------------------------------------------------------
# Debugging
#------------------------------------------------------------------------------
CONFIG_DEBUG_OPTIMIZATIONS=n
CONFIG_DEBUG_THREAD_INFO=y
CONFIG_THREAD_NAME=y
CONFIG_THREAD_RUNTIME_STATS=y

#------------------------------------------------------------------------------
# System
#------------------------------------------------------------------------------
CONFIG_PRINTK=y
CONFIG_EARLY_CONSOLE=y
CONFIG_ASSERT=y
CONFIG_ASSERT_LEVEL=2

#------------------------------------------------------------------------------
# Application Configuration
#------------------------------------------------------------------------------
CONFIG_APP_LOG_LEVEL=3
CONFIG_HEARTBEAT_PERIOD_MS=500
CONFIG_MONITOR_PERIOD_MS=10000
EOF

# Create README
log_info "Creating README.md..."
cat > README.md << 'EOF'
# Zephyr Standalone Application for Raspberry Pi Pico

A production-ready, standalone Zephyr template for Raspberry Pi Pico/Pico W/Pico 2.

This project is **portable** and can be compiled independently using Docker.

## Project Structure

```
.
├── CMakeLists.txt          # Build configuration
├── Makefile                # Docker-based build automation
├── Kconfig                 # Application Kconfig options
├── prj.conf                # Project configuration
├── src/
│   └── main.c              # Application entry point
├── include/
│   ├── app_config.h        # Configuration header
│   └── led_driver.h        # LED driver interface
├── drivers/
│   └── led_driver.c        # LED hardware abstraction
└── build/                  # Build output (generated)
```

## Requirements

- Docker installed and running
- `rpi-pico-dev` Docker image
- Zephyr workspace (parent directory with `zephyr/` or `zephyr-main/`)

## Quick Start

### Build

```bash
# Build for Pico (default)
make build BOARD=rpi_pico

# Build for Pico W
make build BOARD=rpi_pico/rp2040/w

# Build for Pico 2
make build BOARD=rpi_pico2

# Build for Pico 2 W
make build BOARD=rpi_pico2/rp2350a/m33/w

# Clean build
make clean

# Rebuild from scratch
make rebuild BOARD=rpi_pico
```

### Flash

1. Hold **BOOTSEL** button while connecting Pico to USB
2. Copy `build/zephyr/zephyr.uf2` to the RPI-RP2 drive
3. LED will start blinking when firmware is running

## Customization

### Application Logic

Modify `src/main.c` to implement your application:
- `main_app_thread()` - Main application logic
- `heartbeat_thread()` - LED heartbeat
- `monitor_thread()` - System health monitoring

### Configuration

- `prj.conf` - Zephyr kernel and driver settings
- `Kconfig` - Application-specific options
- `include/app_config.h` - Compile-time configuration

### Adding New Threads

1. Define thread stack with `K_THREAD_STACK_DEFINE`
2. Create thread data structure `struct k_thread`
3. Implement thread entry function
4. Create thread in `main()` with `k_thread_create()`
5. Add configuration to `Kconfig` and `prj.conf`

### Adding Hardware Drivers

1. Create driver in `drivers/` directory
2. Add header in `include/` directory
3. Add source file to `CMakeLists.txt`
4. Enable required Kconfig options in `prj.conf`

## Debug Output

Connect via USB serial (115200 baud) to see log output:
```bash
minicom -D /dev/ttyACM0 -b 115200
```

## Building the Docker Image

If you don't have the `rpi-pico-dev` Docker image, you can build it from the
pico-project repository or ensure your Docker image has:
- Ubuntu base with ARM GCC toolchain
- Zephyr SDK and west tool
- CMake and Ninja build tools

## Features

- **Multiple threads** with proper priority configuration
- **Logging subsystem** for debug output
- **LED driver** with hardware abstraction
- **System monitoring** for heap and runtime stats
- **Kconfig integration** for flexible configuration

## License

Apache 2.0 License (matching Zephyr RTOS)
EOF

# Create project-level Makefile
log_info "Creating project Makefile..."
cat > Makefile << 'EOF'
#==============================================================================
# Zephyr Project Makefile
#==============================================================================

# Docker configuration
IMAGE_NAME := rpi-pico-dev
PROJECT_DIR := $(shell pwd)
ZEPHYR_WORKSPACE := $(shell cd .. && pwd)

# Build configuration
BOARD ?= rpi_pico
PRISTINE ?= auto

.PHONY: help build clean rebuild shell menuconfig

help:
	@echo ""
	@echo "  Zephyr Project - Available targets:"
	@echo ""
	@echo "    make build      - Build the project"
	@echo "    make clean      - Clean build artifacts"
	@echo "    make rebuild    - Clean and rebuild"
	@echo "    make shell      - Open development shell"
	@echo "    make menuconfig - Open Kconfig menu"
	@echo ""

build:
	@docker image inspect $(IMAGE_NAME) >/dev/null 2>&1 || \
		(echo "[ERROR] Docker image '$(IMAGE_NAME)' not found. Run 'make build' in pico-project first." && exit 1)
	@echo "[INFO] Building Zephyr..."
	@docker run --rm \
		--user $$(id -u):$$(id -g) \
		-v $(ZEPHYR_WORKSPACE):/zephyr-workspace \
		-w /zephyr-workspace/app \
		$(IMAGE_NAME) \
		/bin/bash -c "export ZEPHYR_TOOLCHAIN_VARIANT=gnuarmemb && \
			export GNUARMEMB_TOOLCHAIN_PATH=/usr && \
			source /zephyr-workspace/zephyr/zephyr-env.sh 2>/dev/null || \
			source /zephyr-workspace/zephyr-main/zephyr-env.sh 2>/dev/null || true && \
			west build -b $(BOARD) -p $(PRISTINE) ."
	@echo "[SUCCESS] Build complete: build/zephyr/zephyr.uf2"

clean:
	@rm -rf build
	@echo "[INFO] Build artifacts cleaned"

rebuild: clean
	@$(MAKE) build PRISTINE=always

shell:
	@docker image inspect $(IMAGE_NAME) >/dev/null 2>&1 || \
		(echo "[ERROR] Docker image '$(IMAGE_NAME)' not found." && exit 1)
	@docker run -it --rm \
		--user $$(id -u):$$(id -g) \
		-v $(ZEPHYR_WORKSPACE):/zephyr-workspace \
		-w /zephyr-workspace/app \
		$(IMAGE_NAME) \
		/bin/bash -c "export ZEPHYR_TOOLCHAIN_VARIANT=gnuarmemb && \
			export GNUARMEMB_TOOLCHAIN_PATH=/usr && \
			source /zephyr-workspace/zephyr/zephyr-env.sh 2>/dev/null || \
			source /zephyr-workspace/zephyr-main/zephyr-env.sh 2>/dev/null || true && \
			/bin/bash"

menuconfig:
	@docker image inspect $(IMAGE_NAME) >/dev/null 2>&1 || \
		(echo "[ERROR] Docker image '$(IMAGE_NAME)' not found." && exit 1)
	@docker run -it --rm \
		--user $$(id -u):$$(id -g) \
		-v $(ZEPHYR_WORKSPACE):/zephyr-workspace \
		-w /zephyr-workspace/app \
		$(IMAGE_NAME) \
		/bin/bash -c "export ZEPHYR_TOOLCHAIN_VARIANT=gnuarmemb && \
			export GNUARMEMB_TOOLCHAIN_PATH=/usr && \
			source /zephyr-workspace/zephyr/zephyr-env.sh 2>/dev/null || \
			source /zephyr-workspace/zephyr-main/zephyr-env.sh 2>/dev/null || true && \
			west build -b $(BOARD) -t menuconfig"
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
log_info "Initializing git repository for the application..."
cd "${PROJECT_DIR}/app"

# Remove any existing git directory (in case of partial init)
rm -rf .git

# Initialize new git repository
git init

# Configure git user for the commit (use generic values if not set)
git config user.email "developer@pico-project.local"
git config user.name "Pico Developer"

# Add all files
git add -A

# Create initial commit
git commit -m "initial commit"

log_success "Zephyr project created successfully!"
echo ""
echo "Project location: ${PROJECT_DIR}/app"
echo ""
echo "This is a standalone, portable application that can be compiled independently."
echo ""
echo "Quick start (from the app directory):"
echo "  cd ${PROJECT_DIR}/app"
echo "  make build BOARD=rpi_pico"
echo ""
echo "Or from the parent pico-project directory:"
echo "  make build-zephyr-pico"
echo ""
echo "The application has been initialized as a git repository with an initial commit."
echo ""
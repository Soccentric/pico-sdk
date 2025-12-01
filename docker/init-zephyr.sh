#!/bin/bash

# Script to create firmware/zephyr directory and initialize a basic Zephyr project for Raspberry Pi Pico

set -e

# Change to workspace directory
cd /workspace

# Check if project already exists
if [ -d "firmware/zephyr" ] && [ -d "firmware/zephyr/.west" ]; then
    echo "Zephyr project already exists in firmware/zephyr/"
    echo "To reinitialize, remove the directory first: rm -rf firmware/zephyr"
    exit 0
fi

echo "Creating firmware directory..."
mkdir -p firmware

echo "Creating firmware/zephyr directory..."
mkdir -p firmware/zephyr

echo "Initializing Zephyr project..."

cd firmware/zephyr

# Initialize Zephyr workspace with pico-zephyr manifest
echo "Initializing west workspace with pico-zephyr..."
west init -m https://github.com/raspberrypi/pico-zephyr --mr main .

# Update modules
echo "Updating Zephyr modules..."
west update

# Create a sample blinky application
echo "Creating blinky application..."
mkdir -p blinky
cd blinky

# Create main source file
mkdir -p src
cat > src/main.c << 'EOF'
#include <zephyr/kernel.h>
#include <zephyr/drivers/gpio.h>

#define SLEEP_TIME_MS 1000

#if DT_NODE_EXISTS(DT_ALIAS(led0))
/* The devicetree node identifier for the "led0" alias */
#define LED0_NODE DT_ALIAS(led0)

static const struct gpio_dt_spec led = GPIO_DT_SPEC_GET(LED0_NODE, gpios);

#endif

int main(void)
{
#if DT_NODE_EXISTS(DT_ALIAS(led0))
    int ret;

    if (!gpio_is_ready_dt(&led)) {
        return 0;
    }

    ret = gpio_pin_configure_dt(&led, GPIO_OUTPUT_ACTIVE);
    if (ret < 0) {
        return 0;
    }

    while (1) {
        ret = gpio_pin_toggle_dt(&led);
        if (ret < 0) {
            return 0;
        }
        k_msleep(SLEEP_TIME_MS);
    }
#else
    /* No LED available, just sleep */
    while (1) {
        k_msleep(SLEEP_TIME_MS);
    }
#endif
    return 0;
}
EOF

# Create CMakeLists.txt
cat > CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.20.0)

find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})
project(blinky)

target_sources(app PRIVATE src/main.c)
EOF

# Create prj.conf
cat > prj.conf << 'EOF'
CONFIG_GPIO=y
CONFIG_PICOLIBC=y
EOF

# Create README
cat > README.md << 'EOF'
# Zephyr Blinky for Raspberry Pi Pico

A simple LED blinky application for the Raspberry Pi Pico using Zephyr RTOS.

## Building

```bash
# For Pico (H)
west build -b rpi_pico

# For Pico W
west build -b rpi_pico/rp2040/w

# For Pico 2
west build -b rpi_pico2
```

## Flashing

The UF2 file will be in `build/zephyr/zephyr.uf2`
EOF

echo "Zephyr project created successfully in firmware/zephyr/"
echo "To build: cd firmware/zephyr/blinky && west build -b rpi_pico"
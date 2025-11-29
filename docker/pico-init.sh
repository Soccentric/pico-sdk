#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: pico-init <project-name>"
    exit 1
fi

PROJECT_NAME=$1

# Change to workspace directory
cd /workspace

mkdir -p $PROJECT_NAME
cd $PROJECT_NAME

# Create CMakeLists.txt
cat > CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.13)

# Pull in SDK (must be before project)
include($ENV{PICO_SDK_PATH}/external/pico_sdk_import.cmake)

project(PROJECT_NAME_PLACEHOLDER C CXX ASM)
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

# Initialize the SDK
pico_sdk_init()

add_executable(PROJECT_NAME_PLACEHOLDER
    main.c
)

# Pull in common dependencies
target_link_libraries(PROJECT_NAME_PLACEHOLDER pico_stdlib)

# Enable USB output, disable UART output
pico_enable_stdio_usb(PROJECT_NAME_PLACEHOLDER 1)
pico_enable_stdio_uart(PROJECT_NAME_PLACEHOLDER 0)

# Create map/bin/hex/uf2 files
pico_add_extra_outputs(PROJECT_NAME_PLACEHOLDER)
EOF

# Replace placeholder with actual project name
sed -i "s/PROJECT_NAME_PLACEHOLDER/${PROJECT_NAME}/g" CMakeLists.txt

# Create main.c (simple blink example without FreeRTOS)
cat > main.c << 'EOF'
#include <stdio.h>
#include "pico/stdlib.h"

int main() {
    stdio_init_all();
    
    const uint LED_PIN = PICO_DEFAULT_LED_PIN;
    gpio_init(LED_PIN);
    gpio_set_dir(LED_PIN, GPIO_OUT);
    
    while (true) {
        printf("Hello, Raspberry Pi Pico!\n");
        gpio_put(LED_PIN, 1);
        sleep_ms(500);
        gpio_put(LED_PIN, 0);
        sleep_ms(500);
    }
    
    return 0;
}
EOF

# Create build script
cat > build.sh << 'EOF'
#!/bin/bash
set -e
mkdir -p build
cd build
cmake -DPICO_SDK_PATH=/opt/pico-sdk ..
make -j$(nproc)
EOF
chmod +x build.sh

echo "Project ${PROJECT_NAME} created successfully!"
echo "To build: cd ${PROJECT_NAME} && ./build.sh"
echo "Output file will be in: build/${PROJECT_NAME}.uf2"

# Raspberry Pi Pico RTOS Development Environment

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue)](https://www.docker.com/)

Production-ready Docker-based development environment for **Raspberry Pi Pico** projects using **FreeRTOS** or **Zephyr RTOS**. Supports all Pico variants: Pico, Pico W, Pico 2, and Pico 2 W.

## Features

- 🐳 **Docker-based** - Consistent build environment across all platforms
- 🚀 **Production-ready templates** - Well-structured boilerplate code
- 🔄 **Multi-RTOS support** - FreeRTOS and Zephyr RTOS
- 📱 **All Pico variants** - Pico, Pico W, Pico 2, Pico 2 W
- 🛠️ **Complete toolchain** - ARM GCC, CMake, West, picotool, OpenOCD
- 📦 **One-shot builds** - Build everything with a single command
- ✅ **Comprehensive testing** - Automated testing for all board configurations

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Project Templates](#project-templates)
- [Detailed Workflows](#detailed-workflows)
- [Available Make Targets](#available-make-targets)
- [Board Variants](#board-variants)
- [Project Architecture](#project-architecture)
- [Customization](#customization)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Prerequisites

- **Docker**: Version 20.10 or later
- **Make**: GNU Make utility
- **Git**: For version control
- **USB Cable**: For flashing firmware

### System Requirements

- Linux, macOS, or Windows with WSL2
- At least 8GB RAM (for Zephyr builds)
- 15GB free disk space
- **Build Times**: 
  - Docker image build: ~10-15 minutes (first time)
  - FreeRTOS project: ~2-3 minutes
  - Zephyr project: ~15-30 minutes (first time, downloads ~2GB)

### Build Dependencies

This project automatically downloads and builds:
- **Raspberry Pi Pico SDK** (official)
- **FreeRTOS Kernel** (latest stable)
- **Zephyr RTOS** (~2GB download on first use)
- **ARM GCC Toolchain** (cross-compiler)
- **Build tools**: CMake, Ninja, West, picotool, OpenOCD

## Quick Start

### One-Shot FreeRTOS Build

```bash
# Clone the repository
git clone https://github.com/Soccentric/pico-sdk.git
cd pico-sdk

# Build FreeRTOS for Pico (builds Docker image + initializes project + compiles)
make freertos PROJECT=my_freertos_app
```

**Note**: Default board is Pico 2 W. Use `BOARD=<board>` to specify a different board.

### One-Shot Zephyr Build

```bash
# Build Zephyr for Pico (first run takes longer to download Zephyr)
make zephyr PROJECT=my_zephyr_app BOARD=rpi_pico
```

### Flashing

1. Hold **BOOTSEL** button while connecting Pico to USB
2. Copy the `.uf2` file to the RPI-RP2 drive:

```bash
# FreeRTOS (replace <project_name> with your project name)
cp firmware/<project_name>/build/*.uf2 /media/$USER/RPI-RP2/

# Zephyr (replace <project_name> with your project name)
cp firmware/<project_name>/app/build/zephyr/zephyr.uf2 /media/$USER/RPI-RP2/
```

## Project Templates

### Standalone, Portable Projects

All generated projects are **standalone** and **portable**:

- Each project is a **git repository** with an "initial commit"
- Projects can be compiled **independently** using the Docker image
- Projects include a self-contained **Makefile** for easy builds
- No dependency on the parent pico-project directory structure

### FreeRTOS Template Features

The generated FreeRTOS project includes:

- **Multiple tasks** - Heartbeat, Main, and Monitor tasks
- **Error handling** - Stack overflow and malloc fail hooks
- **Watchdog support** - Optional hardware watchdog
- **LED abstraction** - Works with Pico and Pico W
- **Thread-safe printing** - Mutex-protected printf
- **Heap monitoring** - Runtime memory statistics
- **Configurable** - Easy customization via header files

```
firmware/<project_name>/
├── CMakeLists.txt          # Production CMake config
├── Makefile                # Local build automation
├── config/
│   └── FreeRTOSConfig.h    # RTOS configuration
├── src/
│   ├── main.c              # Application entry
│   ├── app_tasks.c         # Task implementations
│   └── app_hooks.c         # FreeRTOS hooks
├── include/
│   ├── app_config.h        # App configuration
│   ├── app_tasks.h         # Task API
│   └── led_driver.h        # LED driver API
└── drivers/
    └── led_driver.c        # Hardware abstraction
```

### Zephyr Template Features

The generated Zephyr project includes:

- **Kconfig integration** - Standard Zephyr configuration
- **Logging subsystem** - Debug output via LOG_*
- **Multiple threads** - Heartbeat, Main, and Monitor
- **Device tree support** - Portable LED driver
- **Shell support** - Optional interactive shell
- **Runtime stats** - Thread and memory monitoring

```
firmware/<project_name>/app/
├── CMakeLists.txt          # Zephyr CMake config
├── Makefile                # Local build automation
├── Kconfig                 # App Kconfig options
├── prj.conf                # Project configuration
├── src/
│   └── main.c              # Application entry
├── include/
│   ├── app_config.h        # Configuration header
│   └── led_driver.h        # LED driver API
└── drivers/
    └── led_driver.c        # Hardware abstraction
```

## Detailed Workflows

### FreeRTOS Development

```bash
# Step 1: Build Docker environment (one-time)
make build

# Step 2: Initialize FreeRTOS project with a name
make freertos PROJECT=my_freertos_app BOARD=pico

# Step 3: Build for your target board
make freertos PROJECT=my_freertos_app BOARD=pico         # Pico
make freertos PROJECT=my_freertos_app BOARD=pico_w       # Pico W
make freertos PROJECT=my_freertos_app BOARD=pico2        # Pico 2
make freertos PROJECT=my_freertos_app BOARD=pico2_w      # Pico 2 W

# Debug build (with symbols, no optimization)
make freertos PROJECT=my_freertos_app BUILD_TYPE=Debug
```

### Zephyr Development

```bash
# Step 1: Build Docker environment (one-time)
make build

# Step 2: Initialize Zephyr workspace with a name (downloads ~2GB)
make zephyr PROJECT=my_zephyr_app BOARD=rpi_pico

# Step 3: Build for your target board
make zephyr PROJECT=my_zephyr_app BOARD=rpi_pico                    # Pico
make zephyr PROJECT=my_zephyr_app BOARD=rpi_pico/rp2040/w           # Pico W
make zephyr PROJECT=my_zephyr_app BOARD=rpi_pico2/rp2350a/m33       # Pico 2
make zephyr PROJECT=my_zephyr_app BOARD=rpi_pico2/rp2350a/m33/w     # Pico 2 W
```

### Local Project Builds

Each generated project has its own simple Makefile for local builds:

```bash
# FreeRTOS local build (replace <project_name> with your project name)
cd firmware/<project_name>
make build      # Build (Release)
make debug      # Build with debug symbols
make release    # Build optimized release
make clean      # Clean build artifacts
make rebuild    # Clean and rebuild
make shell      # Open development shell

# Zephyr local build (replace <project_name> with your project name)
cd firmware/<project_name>/app
make build      # Build the project
make clean      # Clean build artifacts
make rebuild    # Clean and rebuild
make shell      # Open development shell
make menuconfig # Open Kconfig menu
```

## Available Make Targets

| Target | Description |
|--------|-------------|
| `make help` | Show all available targets |
| `make build` | Build Docker image |
| `make rebuild` | Force rebuild Docker image |
| `make shell` | Interactive development shell |
| `make clean` | Remove firmware artifacts |
| `make clean-all` | Remove everything including Docker image |
| `make test-all` | Test all board configurations |

### One-Shot Builds

| Target | Description |
|--------|-------------|
| `make freertos PROJECT=<name>` | Complete FreeRTOS build (Pico 2 W default) |
| `make freertos PROJECT=<name> BOARD=<board>` | Complete FreeRTOS build for specific board |
| `make zephyr PROJECT=<name> BOARD=<board>` | Complete Zephyr build |

### Individual Builds

| FreeRTOS | Zephyr |
|----------|--------|
| `make build-freertos-pico` | `make build-zephyr-pico` |
| `make build-freertos-pico-w` | `make build-zephyr-pico-w` |
| `make build-freertos-pico2` | `make build-zephyr-pico2` |
| `make build-freertos-pico2-w` | `make build-zephyr-pico2-w` |

## Board Variants

| Board | FreeRTOS BOARD | Zephyr BOARD |
|-------|----------------|--------------|
| Pico | `pico` | `rpi_pico` |
| Pico W | `pico_w` | `rpi_pico/rp2040/w` |
| Pico 2 | `pico2` | `rpi_pico2/rp2350a/m33` |
| Pico 2 W | `pico2_w` | `rpi_pico2/rp2350a/m33/w` |

## Project Architecture

```
pico-sdk/
├── Makefile                  # Main build orchestration
├── README.md                 # This file
├── test-all.sh              # CI test script
├── docker/
│   ├── Dockerfile           # Development environment
│   ├── build.sh             # Universal build script
│   ├── init-freertos.sh     # FreeRTOS project generator
│   └── init-zephyr.sh       # Zephyr project generator
└── firmware/                 # Generated projects (gitignored)
    └── <project_name>/      # Your named project (standalone git repo)
        └── app/             # Zephyr application directory (for Zephyr projects)
```

### What This Project Provides

This project is a **development environment wrapper** that:

1. **Docker Environment**: Provides a consistent, pre-configured build environment with all necessary tools
2. **Project Templates**: Generates production-ready FreeRTOS and Zephyr project templates
3. **Build Automation**: Simplifies the complex build process for Pico development
4. **Multi-Board Support**: Handles differences between Pico variants (RP2040 vs RP2350)
5. **Testing Framework**: Automated testing across all supported board configurations

### Relationship to Official SDK

- **Official Pico SDK**: This project uses the official Raspberry Pi Pico SDK inside Docker
- **Not a Replacement**: This is a convenience layer, not a fork of the official SDK
- **Compatible**: Generated projects work with the official SDK outside this environment

### Generated Project Features

Each generated project:
- Is initialized as a **standalone git repository**
- Has an **"initial commit"** with all template files
- Includes a **portable Makefile** that works with the Docker image
- Can be **moved anywhere** and built independently
- Contains all necessary configuration and source files

## Testing

The project includes comprehensive automated testing to ensure all board configurations build successfully.

### Run All Tests

```bash
# Test all FreeRTOS and Zephyr board configurations
make test-all
```

This will:
- Clean previous builds
- Build FreeRTOS for all supported boards (Pico, Pico W, Pico 2, Pico 2 W)
- Build Zephyr for all supported boards
- Report success/failure for each configuration
- Display total build time and summary

### Test Results

The test script provides:
- ✅ **Visual feedback** with progress bars and status indicators
- 📊 **Build statistics** including duration and success rates
- 🎯 **Detailed reporting** for each board configuration
- 🚨 **Clear failure indication** if any builds fail

## Troubleshooting

### Docker Image Not Found

```bash
make build
```

### Project Already Exists

```bash
# Remove and reinitialize (replace <project_name> with your project name)
rm -rf firmware/<project_name>
make freertos PROJECT=<project_name>

# Or for Zephyr
rm -rf firmware/<project_name>
make zephyr PROJECT=<project_name> BOARD=rpi_pico
```

### Build Errors

```bash
# Clean rebuild
make clean
make freertos PROJECT=my_app BOARD=pico
```

### Zephyr Download Issues

Zephyr builds require downloading ~2GB of dependencies on first use:

```bash
# Check available disk space
df -h

# If download fails, clean and retry
make clean
make zephyr PROJECT=my_app BOARD=rpi_pico
```

### Permission Issues

```bash
sudo usermod -a -G dialout,plugdev $USER
# Log out and back in
```

### Out of Memory (Zephyr Builds)

Zephyr builds require significant RAM. If you encounter memory issues:

```bash
# Reduce parallel jobs
export MAKEFLAGS="-j2"

# Or add swap space (Linux)
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

### Serial Monitor

```bash
# View debug output
minicom -D /dev/ttyACM0 -b 115200

# Or with screen
screen /dev/ttyACM0 115200
```

### Docker Issues

```bash
# Check Docker is running
docker info

# Clean Docker cache if builds fail
docker system prune -a

# Check Docker disk usage
docker system df
```

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Test with multiple board variants
4. Submit a pull request

## Resources

- [Pico SDK Documentation](https://www.raspberrypi.com/documentation/microcontrollers/c_sdk.html)
- [FreeRTOS Documentation](https://www.freertos.org/Documentation/RTOS_book.html)
- [Zephyr Documentation](https://docs.zephyrproject.org/)
- [RP2040 Datasheet](https://datasheets.raspberrypi.com/rp2040/rp2040-datasheet.pdf)
- [RP2350 Datasheet](https://datasheets.raspberrypi.com/rp2350/rp2350-datasheet.pdf)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

### Component Licenses

This project bundles or references several open-source components:

- **Raspberry Pi Pico SDK**: BSD 3-Clause License
- **FreeRTOS Kernel**: MIT License  
- **Zephyr RTOS**: Apache 2.0 License
- **ARM GCC Toolchain**: GNU GPL v3 (build tools)
- **Docker Environment**: MIT License (this project)

### Project Relationship

This project is **not affiliated with** or **endorsed by** Raspberry Pi Ltd. It provides a convenient Docker-based development environment that uses the official Raspberry Pi Pico SDK and other open-source components. All trademarks and copyrights belong to their respective owners.

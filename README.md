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

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Project Templates](#project-templates)
- [Detailed Workflows](#detailed-workflows)
- [Available Make Targets](#available-make-targets)
- [Board Variants](#board-variants)
- [Project Architecture](#project-architecture)
- [Customization](#customization)
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

## Quick Start

### One-Shot FreeRTOS Build

```bash
# Clone the repository
git clone https://github.com/Soccentric/pico-sdk.git
cd pico-project

# Build FreeRTOS for Pico (builds Docker image + initializes project + compiles)
make freertos-all BOARD=pico PROJECT=my_freertos_app
```

### One-Shot Zephyr Build

```bash
# Build Zephyr for Pico (first run takes longer to download Zephyr)
make zephyr-all BOARD=rpi_pico PROJECT=my_zephyr_app
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
make init-freertos PROJECT=my_freertos_app

# Step 3: Build for your target board
make build-freertos-pico       # Pico
make build-freertos-pico-w     # Pico W
make build-freertos-pico2      # Pico 2
make build-freertos-pico2-w    # Pico 2 W

# Debug build (with symbols, no optimization)
make build-freertos-pico BUILD_TYPE=Debug
```

### Zephyr Development

```bash
# Step 1: Build Docker environment (one-time)
make build

# Step 2: Initialize Zephyr workspace with a name (downloads ~2GB)
make init-zephyr PROJECT=my_zephyr_app

# Step 3: Build for your target board
make build-zephyr-pico         # Pico
make build-zephyr-pico-w       # Pico W
make build-zephyr-pico2        # Pico 2
make build-zephyr-pico2-w      # Pico 2 W
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
| `make freertos-all BOARD=<board> PROJECT=<name>` | Complete FreeRTOS build |
| `make zephyr-all BOARD=<board> PROJECT=<name>` | Complete Zephyr build |

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
| Pico 2 | `pico2` | `rpi_pico2` |
| Pico 2 W | `pico2_w` | `rpi_pico2/rp2350a/m33/w` |

## Project Architecture

```
pico-project/
├── Makefile                  # Main build orchestration
├── README.md                 # This file
├── QUICKSTART.md            # Quick start guide
├── test-all.sh              # CI test script
├── docker/
│   ├── Dockerfile           # Development environment
│   ├── build.sh             # Universal build script
│   ├── init-freertos.sh     # FreeRTOS project generator
│   ├── init-zephyr.sh       # Zephyr project generator
│   └── pico-init.sh         # Custom project generator
└── firmware/                 # Generated projects (gitignored)
    └── <project_name>/      # Your named project (standalone git repo)
        └── app/             # Zephyr application directory (for Zephyr projects)
```

### Generated Project Features

Each generated project:
- Is initialized as a **standalone git repository**
- Has an **"initial commit"** with all template files
- Includes a **portable Makefile** that works with the Docker image
- Can be **moved anywhere** and built independently
- Contains all necessary configuration and source files

## Customization

### FreeRTOS Configuration

1. **Task settings**: Edit `include/app_config.h`
   - Stack sizes, priorities, timing
   
2. **Kernel settings**: Edit `config/FreeRTOSConfig.h`
   - Heap size, tick rate, features

3. **Application logic**: Edit `src/app_tasks.c`
   - Implement your main application in `prvMainTask()`

### Zephyr Configuration

1. **Kconfig settings**: Edit `prj.conf`
   - Enable drivers, logging, shell

2. **App settings**: Edit `Kconfig`
   - Add custom configuration options

3. **Application logic**: Edit `src/main.c`
   - Implement your main application in `main_app_thread()`

## Troubleshooting

### Docker Image Not Found

```bash
make build
```

### Project Already Exists

```bash
# Remove and reinitialize (replace <project_name> with your project name)
rm -rf firmware/<project_name>
make init-freertos PROJECT=<project_name>

# Or for Zephyr
rm -rf firmware/<project_name>
make init-zephyr PROJECT=<project_name>
```

### Build Errors

```bash
# Clean rebuild
make clean
make freertos-all BOARD=pico PROJECT=my_app
```

### Permission Issues

```bash
sudo usermod -a -G dialout,plugdev $USER
# Log out and back in
```

### Serial Monitor

```bash
# View debug output
minicom -D /dev/ttyACM0 -b 115200

# Or with screen
screen /dev/ttyACM0 115200
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

- **Raspberry Pi Pico SDK**: BSD 3-Clause License
- **FreeRTOS Kernel**: MIT License
- **Zephyr RTOS**: Apache 2.0 License

# Raspberry Pi Pico RTOS Development Environment

Docker-based development environment for creating **Raspberry Pi Pico** projects using **FreeRTOS** or **Zephyr RTOS**. Supports all Pico variants: Pico, Pico W, Pico 2, and Pico 2 W.

## Quick Start

### One-Shot Commands

Build everything and create a working firmware in one command:

```bash
# FreeRTOS for Pico
make freertos-all BOARD=pico

# FreeRTOS for Pico W
make freertos-all BOARD=pico_w

# Zephyr for Pico
make zephyr-all BOARD=rpi_pico

# Zephyr for Pico W
make zephyr-all BOARD=rpi_pico/rp2040/w
```

The `.uf2` firmware file will be in:
- **FreeRTOS**: `firmware/freeRTOS/build/*.uf2`
- **Zephyr**: `firmware/zephyr/blinky/build/zephyr/zephyr.uf2`

### Flashing to Pico

1. Hold **BOOTSEL** button while connecting Pico to USB
2. Pico mounts as USB drive (RPI-RP2)
3. Copy the `.uf2` file to the drive:
   ```bash
   cp firmware/freeRTOS/build/*.uf2 /media/RPI-RP2/
   ```

## Detailed Workflows

### FreeRTOS Workflow

```bash
# 1. Build Docker image
make build

# 2. Initialize FreeRTOS project
make init-freertos

# 3. Build for your board
make build-freertos-pico       # Pico
make build-freertos-pico-w     # Pico W
make build-freertos-pico2      # Pico 2
make build-freertos-pico2-w    # Pico 2 W
```

**Project Structure:**
```
firmware/freeRTOS/
├── CMakeLists.txt
├── main.c                    # LED blink example
├── FreeRTOSConfig.h         # RTOS configuration
├── FreeRTOS-Kernel/         # Git submodule
└── build/
    └── freertos_project.uf2
```

### Zephyr Workflow

```bash
# 1. Build Docker image
make build

# 2. Initialize Zephyr project
make init-zephyr

# 3. Build for your board
make build-zephyr-pico         # Pico
make build-zephyr-pico-w       # Pico W
make build-zephyr-pico2        # Pico 2
make build-zephyr-pico2-w      # Pico 2 W
```

**Project Structure:**
```
firmware/zephyr/
├── .west/                    # West workspace
├── zephyr/                   # Zephyr RTOS
├── modules/                  # Zephyr modules
└── blinky/
    ├── src/main.c
    ├── CMakeLists.txt
    ├── prj.conf
    └── build/
        └── zephyr/zephyr.uf2
```

## Available Make Targets

### Quick Builds
- `make freertos-all BOARD=<board>` - Complete FreeRTOS workflow
- `make zephyr-all BOARD=<board>` - Complete Zephyr workflow

### Docker Management
- `make build` - Build Docker image
- `make rebuild` - Clean and rebuild Docker image
- `make shell` - Interactive shell in container
- `make clean` - Remove container and image

### Project Initialization
- `make init-freertos` - Initialize FreeRTOS project
- `make init-zephyr` - Initialize Zephyr project
- `make init PROJECT=name` - Create custom Pico project

### FreeRTOS Builds
- `make build-freertos-pico` - Build for Pico
- `make build-freertos-pico-w` - Build for Pico W
- `make build-freertos-pico2` - Build for Pico 2
- `make build-freertos-pico2-w` - Build for Pico 2 W

### Zephyr Builds
- `make build-zephyr-pico` - Build for Pico
- `make build-zephyr-pico-w` - Build for Pico W
- `make build-zephyr-pico2` - Build for Pico 2
- `make build-zephyr-pico2-w` - Build for Pico 2 W

### Custom Project Builds
```bash
make build-pico PROJECT=path/to/project TYPE=freertos
make build-pico-w PROJECT=path/to/project TYPE=zephyr
```

## What's Included

The Docker environment includes:

- **Pico SDK** - Official Raspberry Pi Pico SDK
- **FreeRTOS Kernel** - Real-time operating system
- **Zephyr RTOS** - Scalable RTOS with west build system
- **ARM GCC Toolchain** - Cross-compiler for ARM Cortex-M
- **CMake & Ninja** - Build system tools
- **picotool** - Pico device management
- **OpenOCD** - Debugging support
- **West** - Zephyr meta-tool

## Board Variants

| Board | FreeRTOS Target | Zephyr Target |
|-------|----------------|---------------|
| Pico | `pico` | `rpi_pico` |
| Pico W | `pico_w` | `rpi_pico/rp2040/w` |
| Pico 2 | `pico2` | `rpi_pico2` |
| Pico 2 W | `pico2_w` | `rpi_pico2/rp2350a/m33/w` |

## Troubleshooting

### "Docker image not found"
```bash
make build
```

### "FreeRTOS project already exists"
```bash
rm -rf firmware/freeRTOS
make init-freertos
```

### "Zephyr project already exists"
```bash
rm -rf firmware/zephyr
make init-zephyr
```

### Build errors
```bash
# Clean and rebuild
rm -rf firmware/
make rebuild
make freertos-all BOARD=pico
```

### Permission issues with USB
```bash
sudo usermod -a -G dialout,plugdev $USER
# Log out and back in
```

## Project Architecture

```
pico-project/
├── Makefile                  # Main build orchestration
├── docker/
│   ├── Dockerfile           # Development environment
│   ├── README.md            # Docker-specific docs
│   ├── build.sh             # Universal build script
│   ├── init-freertos.sh     # FreeRTOS initialization
│   ├── init-zephyr.sh       # Zephyr initialization
│   └── pico-init.sh         # Generic project init
└── firmware/                # Generated projects (gitignored)
    ├── freeRTOS/
    └── zephyr/
```
    └── zephyr/
```

## Advanced Usage

### Interactive Development

```bash
# Start interactive container
make shell

# Inside container
cd firmware/freeRTOS
mkdir build && cd build
cmake -DPICO_SDK_PATH=/opt/pico-sdk -DPICO_BOARD=pico ..
make -j$(nproc)
```

### Custom FreeRTOS Configuration

Edit `firmware/freeRTOS/FreeRTOSConfig.h` to customize:
- Heap size (`configTOTAL_HEAP_SIZE`)
- Task priorities (`configMAX_PRIORITIES`)
- SMP settings (`configNUM_CORES`)

### Custom Zephyr Configuration

Edit `firmware/zephyr/blinky/prj.conf` to enable features:
```
CONFIG_GPIO=y
CONFIG_NEWLIB_LIBC=y
CONFIG_NETWORKING=y
CONFIG_BLUETOOTH=y
```

## Resources

- [Pico SDK Documentation](https://www.raspberrypi.com/documentation/microcontrollers/c_sdk.html)
- [FreeRTOS Documentation](https://www.freertos.org/Documentation/RTOS_book.html)
- [Zephyr Documentation](https://docs.zephyrproject.org/)
- [Getting Started with Pico](https://datasheets.raspberrypi.com/pico/getting-started-with-pico.pdf)
- [RP2040 Datasheet](https://datasheets.raspberrypi.com/rp2040/rp2040-datasheet.pdf)

## License

This project structure is provided as-is for Raspberry Pi Pico development. Individual components (Pico SDK, FreeRTOS, Zephyr) have their own licenses.

# Raspberry Pi Pico Development Docker Environment

A complete Docker environment for Raspberry Pi Pico development with all necessary tools and SDKs.

## Features

This Docker image includes:

- **Pico SDK** - Official Raspberry Pi Pico SDK
- **Pico Examples** - Official example projects
- **Pico Extras** - Additional libraries and utilities
- **Pico Playground** - More examples and experimental features
- **ARM GCC Toolchain** - gcc-arm-none-eabi for cross-compilation
- **CMake & Ninja** - Build system tools
- **picotool** - Tool for interacting with RP2040 devices in BOOTSEL mode
- **OpenOCD** - Debugging support with Raspberry Pi fork
- **Python 3** - For SDK scripts and tools

## Quick Start

### 1. Build the Docker Image

```bash
cd docker
make build
```

This will take several minutes as it downloads and compiles all the tools.

### 2. Create a New Pico Project

```bash
make init PROJECT=my_pico_project
```

This creates a new project directory with:
- `CMakeLists.txt` - Pre-configured build file
- `main.c` - Simple blink example
- `build.sh` - Build script

### 3. Build Your Project

Enter the development environment:

```bash
make run
```

Inside the container:

```bash
cd my_pico_project
./build.sh
```

The compiled `.uf2` file will be in `my_pico_project/build/`.

### 4. Flash to Pico

1. Hold the BOOTSEL button on your Pico while connecting USB
2. The Pico will mount as a USB drive
3. Copy the `.uf2` file to the drive:
   ```bash
   cp build/my_pico_project.uf2 /media/RPI-RP2/
   ```

## Usage

### Available Make Commands

- `make build` - Build the Docker image
- `make run` - Run container with interactive shell
- `make shell` - Open additional shell in running container
- `make init PROJECT=name` - Create a new Pico project
- `make clean` - Remove container and image

### Inside the Container

#### Initialize a New Project
```bash
pico-init my_project_name
```

#### Build a Project
```bash
cd my_project_name
mkdir build && cd build
cmake ..
make -j$(nproc)
```

Or use the provided build script:
```bash
cd my_project_name
./build.sh
```

#### Update Pico SDK
```bash
pico-sdk-update
```

#### Access Examples
```bash
pico-examples  # Alias to cd /opt/pico-examples
```

### Environment Variables

- `PICO_SDK_PATH=/opt/pico-sdk`
- `PICO_EXTRAS_PATH=/opt/pico-extras`
- `PICO_PLAYGROUND_PATH=/opt/pico-playground`

## Project Structure

Your typical Pico project structure:

```
my_pico_project/
├── CMakeLists.txt
├── main.c
├── build.sh
└── build/
    ├── my_pico_project.elf
    ├── my_pico_project.uf2
    ├── my_pico_project.bin
    └── ...
```

## Adding Libraries

To use additional Pico libraries in your project, modify `CMakeLists.txt`:

```cmake
# Add more libraries
target_link_libraries(my_project 
    pico_stdlib
    hardware_i2c
    hardware_spi
    hardware_pwm
    hardware_adc
)
```

Common libraries:
- `hardware_gpio` - GPIO control
- `hardware_i2c` - I2C communication
- `hardware_spi` - SPI communication
- `hardware_uart` - UART communication
- `hardware_pwm` - PWM control
- `hardware_adc` - Analog to Digital Converter
- `pico_multicore` - Dual core support
- `pico_time` - Timing functions
- `pico_sync` - Synchronization primitives

## Debugging

The image includes OpenOCD for debugging with a Picoprobe or other debug probe:

```bash
# Start OpenOCD (in one terminal)
openocd -f interface/picoprobe.cfg -f target/rp2040.cfg

# Connect GDB (in another terminal)
gdb-multiarch build/my_project.elf
(gdb) target remote localhost:3333
(gdb) load
(gdb) monitor reset init
(gdb) continue
```

## USB Device Access

The container runs with `--privileged` and mounts `/dev` to allow direct USB access to the Pico.

## Troubleshooting

### Permission Issues
If you encounter permission issues with USB devices, ensure your user is in the `dialout` and `plugdev` groups on the host:
```bash
sudo usermod -a -G dialout,plugdev $USER
```

### Build Errors
- Ensure `PICO_SDK_PATH` is set correctly
- Update the SDK: `pico-sdk-update`
- Clean build directory: `rm -rf build && mkdir build`

## Resources

- [Pico SDK Documentation](https://www.raspberrypi.com/documentation/microcontrollers/c_sdk.html)
- [Getting Started Guide](https://datasheets.raspberrypi.com/pico/getting-started-with-pico.pdf)
- [Pico Datasheet](https://datasheets.raspberrypi.com/pico/pico-datasheet.pdf)
- [RP2040 Datasheet](https://datasheets.raspberrypi.com/rp2040/rp2040-datasheet.pdf)

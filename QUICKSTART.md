# Quick Start Guide

Get your Raspberry Pi Pico running with FreeRTOS or Zephyr in minutes!

## FreeRTOS Quick Start

### One Command Build

```bash
make freertos-all BOARD=pico
```

This single command will:
1. ✅ Build the Docker development environment
2. ✅ Initialize a FreeRTOS project with LED blink example
3. ✅ Compile the firmware for your board
4. ✅ Generate a `.uf2` file ready to flash

### Flash to Pico

1. **Hold BOOTSEL** button on your Pico
2. **Connect USB** cable (keep holding BOOTSEL)
3. **Release BOOTSEL** - Pico appears as USB drive (RPI-RP2)
4. **Copy firmware**:
   ```bash
   cp firmware/freeRTOS/build/*.uf2 /media/RPI-RP2/
   ```
5. **Done!** LED starts blinking

### Other Boards

```bash
make freertos-all BOARD=pico_w      # Pico W
make freertos-all BOARD=pico2       # Pico 2
make freertos-all BOARD=pico2_w     # Pico 2 W
```

---

## Zephyr Quick Start

### One Command Build

```bash
make zephyr-all BOARD=rpi_pico
```

This single command will:
1. ✅ Build the Docker development environment
2. ✅ Initialize a Zephyr workspace with west
3. ✅ Create a blinky application
4. ✅ Compile the firmware for your board
5. ✅ Generate a `.uf2` file ready to flash

### Flash to Pico

1. **Hold BOOTSEL** button on your Pico
2. **Connect USB** cable (keep holding BOOTSEL)
3. **Release BOOTSEL** - Pico appears as USB drive (RPI-RP2)
4. **Copy firmware**:
   ```bash
   cp firmware/zephyr/blinky/build/zephyr/zephyr.uf2 /media/RPI-RP2/
   ```
5. **Done!** LED starts blinking

### Other Boards

```bash
make zephyr-all BOARD=rpi_pico/rp2040/w           # Pico W
make zephyr-all BOARD=rpi_pico2                   # Pico 2
make zephyr-all BOARD=rpi_pico2/rp2350a/m33/w     # Pico 2 W
```

---

## What Just Happened?

### FreeRTOS Project Structure
```
firmware/freeRTOS/
├── main.c                    # Your application code
├── FreeRTOSConfig.h         # RTOS configuration
├── CMakeLists.txt           # Build configuration
├── FreeRTOS-Kernel/         # RTOS kernel (git submodule)
└── build/
    └── freertos_project.uf2 # 👈 Flash this file!
```

### Zephyr Project Structure
```
firmware/zephyr/
├── zephyr/                  # Zephyr RTOS
├── modules/                 # Zephyr modules
└── blinky/
    ├── src/main.c          # Your application code
    ├── prj.conf            # Project configuration
    └── build/
        └── zephyr/
            └── zephyr.uf2  # 👈 Flash this file!
```

---

## Next Steps

### Modify Your Code

**FreeRTOS:**
```bash
# Edit the main application
nano firmware/freeRTOS/main.c

# Rebuild
make build-freertos-pico
```

**Zephyr:**
```bash
# Edit the main application
nano firmware/zephyr/blinky/src/main.c

# Rebuild
make build-zephyr-pico
```

### Start Fresh

```bash
# Remove generated projects
rm -rf firmware/

# Run one-shot build again
make freertos-all BOARD=pico
```

### Get Help

```bash
# See all available commands
make help
```

---

## Troubleshooting

### "Docker image not found"
```bash
make build
```

### "Permission denied" on USB
```bash
sudo usermod -a -G dialout,plugdev $USER
# Log out and back in
```

### Build fails
```bash
# Clean everything and start over
rm -rf firmware/
make rebuild
make freertos-all BOARD=pico
```

---

## Learn More

- [Full README](README.md) - Complete documentation
- [FreeRTOS Docs](https://www.freertos.org/Documentation/RTOS_book.html)
- [Zephyr Docs](https://docs.zephyrproject.org/)
- [Pico SDK](https://www.raspberrypi.com/documentation/microcontrollers/c_sdk.html)

---

**That's it!** You now have a working RTOS project on your Raspberry Pi Pico. Happy coding! 🚀

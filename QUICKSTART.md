# Quick Start Guide

Get your Raspberry Pi Pico running with FreeRTOS or Zephyr in minutes!

## FreeRTOS Quick Start

### One Command Build

```bash
make freertos-all BOARD=pico
```

This single command will:
1. ✅ Build the Docker development environment
2. ✅ Initialize a production-ready FreeRTOS project
3. ✅ Compile the firmware for your board
4. ✅ Generate a `.uf2` file ready to flash

### Flash to Pico

1. **Hold BOOTSEL** button on your Pico
2. **Connect USB** cable (keep holding BOOTSEL)
3. **Release BOOTSEL** - Pico appears as USB drive (RPI-RP2)
4. **Copy firmware**:
   ```bash
   cp firmware/freeRTOS/build/*.uf2 /media/$USER/RPI-RP2/
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
3. ✅ Create a production-ready application
4. ✅ Compile the firmware for your board
5. ✅ Generate a `.uf2` file ready to flash

### Flash to Pico

1. **Hold BOOTSEL** button on your Pico
2. **Connect USB** cable (keep holding BOOTSEL)
3. **Release BOOTSEL** - Pico appears as USB drive (RPI-RP2)
4. **Copy firmware**:
   ```bash
   cp firmware/zephyr/app/build/zephyr/zephyr.uf2 /media/$USER/RPI-RP2/
   ```
5. **Done!** LED starts blinking

### Other Boards

```bash
make zephyr-all BOARD=rpi_pico/rp2040/w           # Pico W
make zephyr-all BOARD=rpi_pico2                   # Pico 2
make zephyr-all BOARD=rpi_pico2/rp2350a/m33/w     # Pico 2 W
```

---

## What Gets Created?

### FreeRTOS Project Structure

```
firmware/freeRTOS/
├── Makefile                # Local build automation
├── CMakeLists.txt          # CMake configuration
├── config/
│   └── FreeRTOSConfig.h    # RTOS kernel config
├── src/
│   ├── main.c              # Entry point
│   ├── app_tasks.c         # Your tasks go here
│   └── app_hooks.c         # Error handlers
├── include/
│   ├── app_config.h        # App settings
│   ├── app_tasks.h         # Task API
│   └── led_driver.h        # LED API
├── drivers/
│   └── led_driver.c        # LED abstraction
├── FreeRTOS-Kernel/        # RTOS kernel
└── build/
    └── *.uf2               # 👈 Flash this!
```

### Zephyr Project Structure

```
firmware/zephyr/
├── .west/                  # West workspace
├── zephyr/                 # Zephyr RTOS
├── modules/                # Zephyr modules
└── app/
    ├── Makefile            # Local build automation
    ├── CMakeLists.txt      # CMake configuration
    ├── Kconfig             # App Kconfig
    ├── prj.conf            # Project config
    ├── src/
    │   └── main.c          # Entry point + threads
    ├── include/
    │   ├── app_config.h    # Config header
    │   └── led_driver.h    # LED API
    ├── drivers/
    │   └── led_driver.c    # LED abstraction
    └── build/
        └── zephyr/
            └── zephyr.uf2  # 👈 Flash this!
```

---

## Next Steps

### Modify Your Code

**FreeRTOS:**
```bash
# Edit main application task
nano firmware/freeRTOS/src/app_tasks.c

# Rebuild
make build-freertos-pico
```

**Zephyr:**
```bash
# Edit main application
nano firmware/zephyr/app/src/main.c

# Rebuild
make build-zephyr-pico
```

### Use Local Makefiles

Each project has its own Makefile:

```bash
# FreeRTOS
cd firmware/freeRTOS
make build BOARD=pico_w
make clean
make rebuild BOARD=pico

# Zephyr
cd firmware/zephyr/app
make build BOARD=rpi_pico
make menuconfig  # Kconfig menu
```

### Debug Build

```bash
# Build with debug symbols
make build-freertos-pico BUILD_TYPE=Debug
```

### View Debug Output

```bash
# Connect via USB serial
minicom -D /dev/ttyACM0 -b 115200

# Or with screen
screen /dev/ttyACM0 115200
```

### Start Fresh

```bash
# Remove generated projects
rm -rf firmware/

# Run one-shot build again
make freertos-all BOARD=pico
```

---

## Production Code Guidelines

### FreeRTOS

1. **Add your logic** in `src/app_tasks.c` → `prvMainTask()`
2. **Configure tasks** in `include/app_config.h`
3. **Add drivers** in `drivers/` directory
4. **Enable watchdog** by setting `APP_WATCHDOG_ENABLED=1`

### Zephyr

1. **Add your logic** in `src/main.c` → `main_app_thread()`
2. **Configure features** in `prj.conf`
3. **Add drivers** in `drivers/` directory
4. **Enable shell** by uncommenting in `prj.conf`

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

## Get Help

```bash
# See all available commands
make help
```

---

**That's it!** You now have a production-ready RTOS project on your Raspberry Pi Pico. Happy coding! 🚀

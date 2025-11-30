IMAGE_NAME = rpi-pico-dev
CONTAINER_NAME = pico-dev
ROOT_DIR = $(shell pwd)

.PHONY: help run shell build rebuild build-pico build-pico-w build-pico2 build-pico2-w init init-freertos init-zephyr clean check-docker freertos-all zephyr-all test-all

help:
	@echo "Raspberry Pi Pico RTOS Development Environment"
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  QUICK START - One-Shot Commands"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "  FreeRTOS:"
	@echo "    make freertos-all BOARD=pico        - Build image, init, and compile for Pico"
	@echo "    make freertos-all BOARD=pico_w      - Build image, init, and compile for Pico W"
	@echo "    make freertos-all BOARD=pico2       - Build image, init, and compile for Pico 2"
	@echo "    make freertos-all BOARD=pico2_w     - Build image, init, and compile for Pico 2 W"
	@echo ""
	@echo "  Zephyr:"
	@echo "    make zephyr-all BOARD=rpi_pico              - Build image, init, and compile for Pico"
	@echo "    make zephyr-all BOARD=rpi_pico/rp2040/w     - Build image, init, and compile for Pico W"
	@echo "    make zephyr-all BOARD=rpi_pico2             - Build image, init, and compile for Pico 2"
	@echo "    make zephyr-all BOARD=rpi_pico2/rp2350a/m33/w - Build image, init, and compile for Pico 2 W"
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  DOCKER MANAGEMENT"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "  make build                - Build the Docker image"
	@echo "  make rebuild              - Clean and rebuild Docker image"
	@echo "  make shell                - Launch interactive shell in container"
	@echo "  make clean                - Remove container and firmware directory"
	@echo "  make test-all             - Test all supported board builds"
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  PROJECT INITIALIZATION"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "  make init-freertos        - Initialize FreeRTOS project"
	@echo "  make init-zephyr          - Initialize Zephyr project"
	@echo "  make init PROJECT=name    - Create custom Pico project"
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  FREERTOS BUILDS"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "  make build-freertos-pico       - Build FreeRTOS for Pico"
	@echo "  make build-freertos-pico-w     - Build FreeRTOS for Pico W"
	@echo "  make build-freertos-pico2      - Build FreeRTOS for Pico 2"
	@echo "  make build-freertos-pico2-w    - Build FreeRTOS for Pico 2 W"
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  ZEPHYR BUILDS"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "  make build-zephyr-pico         - Build Zephyr for Pico"
	@echo "  make build-zephyr-pico-w       - Build Zephyr for Pico W"
	@echo "  make build-zephyr-pico2        - Build Zephyr for Pico 2"
	@echo "  make build-zephyr-pico2-w      - Build Zephyr for Pico 2 W"
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  CUSTOM PROJECT BUILDS"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "  make build-pico PROJECT=path TYPE=freertos|zephyr"
	@echo "  make build-pico-w PROJECT=path TYPE=freertos|zephyr"
	@echo "  make build-pico2 PROJECT=path TYPE=freertos|zephyr"
	@echo "  make build-pico2-w PROJECT=path TYPE=freertos|zephyr"
	@echo ""

# Test all builds
test-all:
	@echo "Running comprehensive test of all supported boards..."
	./test-all.sh
check-docker:
	@docker image inspect $(IMAGE_NAME) >/dev/null 2>&1 || \
		(echo "Docker image '$(IMAGE_NAME)' not found. Building..." && $(MAKE) build)

# Build Docker image
build:
	@echo "Building Raspberry Pi Pico development image..."
	docker build -t $(IMAGE_NAME) -f docker/Dockerfile .

# Rebuild Docker image
rebuild: clean build

# Interactive shell
run:
	docker run -it --rm \
		--name $(CONTAINER_NAME) \
		--privileged \
		--user ubuntu \
		-v $(ROOT_DIR):/workspace \
		-v /dev:/dev \
		$(IMAGE_NAME)

shell:
	docker run -it --rm \
		--user ubuntu \
		-v $(ROOT_DIR):/workspace \
		$(IMAGE_NAME) \
		/bin/bash

# One-shot FreeRTOS build
freertos-all: check-docker
ifndef BOARD
	@echo "Error: BOARD parameter required"
	@echo "Usage: make freertos-all BOARD=pico|pico_w|pico2|pico2_w"
	@exit 1
endif
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  FreeRTOS One-Shot Build for $(BOARD)"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "Step 1/3: Initializing FreeRTOS project..."
	@$(MAKE) init-freertos
	@echo ""
	@echo "Step 2/3: Building for $(BOARD)..."
	@$(MAKE) build-freertos-$(subst _,-,$(BOARD))
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  ✅ SUCCESS! FreeRTOS firmware ready"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "Firmware location: firmware/freeRTOS/build/*.uf2"
	@echo ""
	@echo "To flash:"
	@echo "  1. Hold BOOTSEL button while connecting Pico"
	@echo "  2. Copy .uf2 file to RPI-RP2 drive"
	@echo ""

# One-shot Zephyr build
zephyr-all: check-docker
ifndef BOARD
	@echo "Error: BOARD parameter required"
	@echo "Usage: make zephyr-all BOARD=rpi_pico|rpi_pico/rp2040/w|rpi_pico2|rpi_pico2/rp2350a/m33/w"
	@exit 1
endif
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  Zephyr One-Shot Build for $(BOARD)"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "Step 1/3: Initializing Zephyr project..."
	@if [ ! -d "firmware/zephyr" ]; then \
		$(MAKE) init-zephyr; \
	else \
		echo "Zephyr project already initialized, skipping..."; \
	fi
	@echo ""
	@echo "Step 2/3: Building for $(BOARD)..."
	docker run --rm \
		--user ubuntu \
		-v $(ROOT_DIR):/workspace \
		$(IMAGE_NAME) \
		./docker/build.sh -t zephyr -p /workspace/firmware/zephyr/blinky -b $(BOARD)
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  ✅ SUCCESS! Zephyr firmware ready"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "Firmware location: firmware/zephyr/blinky/build/zephyr/zephyr.uf2"
	@echo ""
	@echo "To flash:"
	@echo "  1. Hold BOOTSEL button while connecting Pico"
	@echo "  2. Copy .uf2 file to RPI-RP2 drive"
	@echo ""

# Custom project builds
build-pico:
ifndef PROJECT
	@echo "Please provide PROJECT=path/to/project and TYPE=freertos|zephyr"
	@exit 1
endif
ifndef TYPE
	@echo "Please provide TYPE=freertos|zephyr"
	@exit 1
endif
	docker run --rm \
		--user ubuntu \
		-v $(ROOT_DIR):/workspace \
		$(IMAGE_NAME) \
		./docker/build.sh -t $(TYPE) -p $(PROJECT) -b pico

build-pico-w:
ifndef PROJECT
	@echo "Please provide PROJECT=path/to/project and TYPE=freertos|zephyr"
	@exit 1
endif
ifndef TYPE
	@echo "Please provide TYPE=freertos|zephyr"
	@exit 1
endif
	docker run --rm \
		--user ubuntu \
		-v $(ROOT_DIR):/workspace \
		$(IMAGE_NAME) \
		./docker/build.sh -t $(TYPE) -p $(PROJECT) -b pico_w

build-pico2:
ifndef PROJECT
	@echo "Please provide PROJECT=path/to/project and TYPE=freertos|zephyr"
	@exit 1
endif
ifndef TYPE
	@echo "Please provide TYPE=freertos|zephyr"
	@exit 1
endif
	docker run --rm \
		--user ubuntu \
		-v $(ROOT_DIR):/workspace \
		$(IMAGE_NAME) \
		./docker/build.sh -t $(TYPE) -p $(PROJECT) -b pico2

build-pico2-w:
ifndef PROJECT
	@echo "Please provide PROJECT=path/to/project and TYPE=freertos|zephyr"
	@exit 1
endif
ifndef TYPE
	@echo "Please provide TYPE=freertos|zephyr"
	@exit 1
endif
	docker run --rm \
		--user ubuntu \
		-v $(ROOT_DIR):/workspace \
		$(IMAGE_NAME) \
		./docker/build.sh -t $(TYPE) -p $(PROJECT) -b pico2_w

# FreeRTOS builds
build-freertos-pico:
	docker run --rm \
		--user ubuntu \
		-v $(ROOT_DIR):/workspace \
		$(IMAGE_NAME) \
		./docker/build.sh -t freertos -p /workspace/firmware/freeRTOS -b pico

build-freertos-pico-w:
	docker run --rm \
		--user ubuntu \
		-v $(ROOT_DIR):/workspace \
		$(IMAGE_NAME) \
		./docker/build.sh -t freertos -p /workspace/firmware/freeRTOS -b pico_w

build-freertos-pico2:
	docker run --rm \
		--user ubuntu \
		-v $(ROOT_DIR):/workspace \
		$(IMAGE_NAME) \
		./docker/build.sh -t freertos -p /workspace/firmware/freeRTOS -b pico2

build-freertos-pico2-w:
	docker run --rm \
		--user ubuntu \
		-v $(ROOT_DIR):/workspace \
		$(IMAGE_NAME) \
		./docker/build.sh -t freertos -p /workspace/firmware/freeRTOS -b pico2_w

# Zephyr builds
build-zephyr-pico:
	docker run --rm \
		--user ubuntu \
		-v $(ROOT_DIR):/workspace \
		$(IMAGE_NAME) \
		./docker/build.sh -t zephyr -p /workspace/firmware/zephyr/blinky -b rpi_pico

build-zephyr-pico-w:
	docker run --rm \
		--user ubuntu \
		-v $(ROOT_DIR):/workspace \
		$(IMAGE_NAME) \
		./docker/build.sh -t zephyr -p /workspace/firmware/zephyr/blinky -b rpi_pico/rp2040/w

build-zephyr-pico2:
	docker run --rm \
		--user ubuntu \
		-v $(ROOT_DIR):/workspace \
		$(IMAGE_NAME) \
		./docker/build.sh -t zephyr -p /workspace/firmware/zephyr/blinky -b rpi_pico2

build-zephyr-pico2-w:
	docker run --rm \
		--user ubuntu \
		-v $(ROOT_DIR):/workspace \
		$(IMAGE_NAME) \
		./docker/build.sh -t zephyr -p /workspace/firmware/zephyr/blinky -b rpi_pico2/rp2350a/m33/w

# Project initialization
init-freertos:
	docker run --rm \
		--user ubuntu \
		-v $(ROOT_DIR):/workspace \
		$(IMAGE_NAME) \
		./docker/init-freertos.sh

init-zephyr:
	docker run --rm \
		--user ubuntu \
		-v $(ROOT_DIR):/workspace \
		$(IMAGE_NAME) \
		./docker/init-zephyr.sh

init:
	@if [ -z "$(PROJECT)" ]; then \
		echo "Error: PROJECT name required. Usage: make init PROJECT=myproject"; \
		exit 1; \
	fi
	@echo "Creating new Pico project: $(PROJECT)"
	docker run --rm \
		--user ubuntu \
		-v $(ROOT_DIR):/workspace \
		$(IMAGE_NAME) \
		/bin/bash -c "cd /workspace && pico-init $(PROJECT)"

# Cleanup
clean:
	@echo "Cleaning up build artifacts..."
	rm -rf $(ROOT_DIR)/firmware

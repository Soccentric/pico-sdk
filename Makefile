#==============================================================================
# Raspberry Pi Pico RTOS Development Environment
# Docker-based build system for FreeRTOS and Zephyr projects
#==============================================================================

# Docker configuration
IMAGE_NAME := rpi-pico-dev
CONTAINER_NAME := pico-dev
ROOT_DIR := $(shell pwd)

# Build configuration
BUILD_TYPE ?= Release
JOBS ?= $(shell nproc)

# Default targets
.DEFAULT_GOAL := help

.PHONY: help \
	build rebuild shell clean clean-all \
	init-freertos init-zephyr init \
	freertos-all zephyr-all \
	build-freertos-pico build-freertos-pico-w build-freertos-pico2 build-freertos-pico2-w \
	build-zephyr-pico build-zephyr-pico-w build-zephyr-pico2 build-zephyr-pico2-w \
	build-pico build-pico-w build-pico2 build-pico2-w \
	test-all check-docker version

#==============================================================================
# Help Target
#==============================================================================
help:
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  Raspberry Pi Pico RTOS Development Environment"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "  QUICK START - One-Shot Commands"
	@echo "  ─────────────────────────────────────────────────────────────────────"
	@echo ""
	@echo "  FreeRTOS (pico, pico_w, pico2, pico2_w):"
	@echo "    make freertos-all BOARD=pico           Build for Pico"
	@echo "    make freertos-all BOARD=pico_w         Build for Pico W"
	@echo "    make freertos-all BOARD=pico2          Build for Pico 2"
	@echo "    make freertos-all BOARD=pico2_w        Build for Pico 2 W"
	@echo ""
	@echo "  Zephyr:"
	@echo "    make zephyr-all BOARD=rpi_pico         Build for Pico"
	@echo "    make zephyr-all BOARD=rpi_pico/rp2040/w     Build for Pico W"
	@echo "    make zephyr-all BOARD=rpi_pico2        Build for Pico 2"
	@echo "    make zephyr-all BOARD=rpi_pico2/rp2350a/m33/w Build for Pico 2 W"
	@echo ""
	@echo "  DOCKER MANAGEMENT"
	@echo "  ─────────────────────────────────────────────────────────────────────"
	@echo ""
	@echo "    make build                Build Docker image"
	@echo "    make rebuild              Force rebuild Docker image"
	@echo "    make shell                Interactive development shell"
	@echo "    make clean                Remove firmware build artifacts"
	@echo "    make clean-all            Remove everything (firmware + docker)"
	@echo ""
	@echo "  PROJECT INITIALIZATION"
	@echo "  ─────────────────────────────────────────────────────────────────────"
	@echo ""
	@echo "    make init-freertos        Initialize FreeRTOS project"
	@echo "    make init-zephyr          Initialize Zephyr project"
	@echo "    make init PROJECT=name    Create custom Pico project"
	@echo ""
	@echo "  INDIVIDUAL BUILDS"
	@echo "  ─────────────────────────────────────────────────────────────────────"
	@echo ""
	@echo "  FreeRTOS (RP2040 only):"
	@echo "    make build-freertos-pico          Pico"
	@echo "    make build-freertos-pico-w        Pico W"
	@echo "    (pico2/pico2_w: pending FreeRTOS RP2350 port)"
	@echo ""
	@echo "  Zephyr (all boards):"
	@echo "    make build-zephyr-pico            Pico"
	@echo "    make build-zephyr-pico-w          Pico W"
	@echo "    make build-zephyr-pico2           Pico 2"
	@echo "    make build-zephyr-pico2-w         Pico 2 W"
	@echo ""
	@echo "  OPTIONS"
	@echo "  ─────────────────────────────────────────────────────────────────────"
	@echo ""
	@echo "    BUILD_TYPE=Debug|Release  Build type (default: Release)"
	@echo "    JOBS=N                    Parallel jobs (default: $(JOBS))"
	@echo ""
	@echo "  TESTING"
	@echo "  ─────────────────────────────────────────────────────────────────────"
	@echo ""
	@echo "    make test-all             Test all supported board configurations"
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""

#==============================================================================
# Version Information
#==============================================================================
version:
	@echo "Pico RTOS Development Environment v2.0.0"
	@echo "Docker Image: $(IMAGE_NAME)"

#==============================================================================
# Docker Management
#==============================================================================
check-docker:
	@docker image inspect $(IMAGE_NAME) >/dev/null 2>&1 || \
		(echo "[INFO] Docker image '$(IMAGE_NAME)' not found. Building..." && $(MAKE) build)

build:
	@echo "[INFO] Building Docker development environment..."
	docker build -t $(IMAGE_NAME) -f docker/Dockerfile .

rebuild:
	@echo "[INFO] Rebuilding Docker development environment..."
	docker rmi -f $(IMAGE_NAME) 2>/dev/null || true
	$(MAKE) build

shell: check-docker
	@echo "[INFO] Starting interactive development shell..."
	docker run -it --rm \
		--name $(CONTAINER_NAME) \
		--user ubuntu \
		-v $(ROOT_DIR):/workspace \
		-w /workspace \
		$(IMAGE_NAME) \
		/bin/bash

run: check-docker
	docker run -it --rm \
		--name $(CONTAINER_NAME) \
		--privileged \
		--user ubuntu \
		-v $(ROOT_DIR):/workspace \
		-v /dev:/dev \
		$(IMAGE_NAME)

#==============================================================================
# One-Shot Builds (Build + Initialize + Compile)
#==============================================================================
freertos-all: check-docker
ifndef BOARD
	@echo "[ERROR] BOARD parameter required"
	@echo "Usage: make freertos-all BOARD=pico|pico_w|pico2|pico2_w"
	@exit 1
endif
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  FreeRTOS One-Shot Build for $(BOARD)"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "[STEP 1/2] Initializing FreeRTOS project..."
	@$(MAKE) init-freertos
	@echo ""
	@echo "[STEP 2/2] Building for $(BOARD)..."
	@$(MAKE) build-freertos-$(subst _,-,$(BOARD)) BUILD_TYPE=$(BUILD_TYPE)
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  ✅ SUCCESS! FreeRTOS firmware ready"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "Firmware: firmware/freeRTOS/build/*.uf2"
	@echo ""
	@echo "To flash:"
	@echo "  1. Hold BOOTSEL button while connecting Pico"
	@echo "  2. Copy .uf2 file to RPI-RP2 drive"
	@echo ""

zephyr-all: check-docker
ifndef BOARD
	@echo "[ERROR] BOARD parameter required"
	@echo "Usage: make zephyr-all BOARD=rpi_pico|rpi_pico/rp2040/w|rpi_pico2|..."
	@exit 1
endif
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  Zephyr One-Shot Build for $(BOARD)"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@if [ ! -d "firmware/zephyr/app" ]; then \
		echo "[STEP 1/2] Initializing Zephyr project..."; \
		$(MAKE) init-zephyr; \
	else \
		echo "[STEP 1/2] Zephyr already initialized, skipping..."; \
	fi
	@echo ""
	@echo "[STEP 2/2] Building for $(BOARD)..."
	docker run --rm \
		--user ubuntu \
		-v $(ROOT_DIR):/workspace \
		$(IMAGE_NAME) \
		./docker/build.sh -t zephyr -p /workspace/firmware/zephyr/app -b $(BOARD)
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  ✅ SUCCESS! Zephyr firmware ready"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "Firmware: firmware/zephyr/app/build/zephyr/zephyr.uf2"
	@echo ""
	@echo "To flash:"
	@echo "  1. Hold BOOTSEL button while connecting Pico"
	@echo "  2. Copy .uf2 file to RPI-RP2 drive"
	@echo ""

#==============================================================================
# Project Initialization
#==============================================================================
init-freertos: check-docker
	@echo "[INFO] Initializing FreeRTOS project..."
	docker run --rm \
		--user ubuntu \
		-v $(ROOT_DIR):/workspace \
		$(IMAGE_NAME) \
		./docker/init-freertos.sh

init-zephyr: check-docker
	@echo "[INFO] Initializing Zephyr project (this may take a while)..."
	docker run --rm \
		--user ubuntu \
		-v $(ROOT_DIR):/workspace \
		$(IMAGE_NAME) \
		./docker/init-zephyr.sh

init: check-docker
ifndef PROJECT
	@echo "[ERROR] PROJECT name required"
	@echo "Usage: make init PROJECT=myproject"
	@exit 1
endif
	@echo "[INFO] Creating new Pico project: $(PROJECT)"
	docker run --rm \
		--user ubuntu \
		-v $(ROOT_DIR):/workspace \
		$(IMAGE_NAME) \
		/bin/bash -c "cd /workspace && pico-init $(PROJECT)"

#==============================================================================
# FreeRTOS Individual Builds
#==============================================================================
build-freertos-pico: check-docker
	@echo "[INFO] Building FreeRTOS for Pico..."
	docker run --rm \
		--user ubuntu \
		-v $(ROOT_DIR):/workspace \
		$(IMAGE_NAME) \
		./docker/build.sh -t freertos -p /workspace/firmware/freeRTOS -b pico \
			$(if $(filter Debug,$(BUILD_TYPE)),-d,-r)

build-freertos-pico-w: check-docker
	@echo "[INFO] Building FreeRTOS for Pico W..."
	docker run --rm \
		--user ubuntu \
		-v $(ROOT_DIR):/workspace \
		$(IMAGE_NAME) \
		./docker/build.sh -t freertos -p /workspace/firmware/freeRTOS -b pico_w \
			$(if $(filter Debug,$(BUILD_TYPE)),-d,-r)

build-freertos-pico2: check-docker
	@echo "[INFO] Building FreeRTOS for Pico 2..."
	docker run --rm \
		--user ubuntu \
		-v $(ROOT_DIR):/workspace \
		$(IMAGE_NAME) \
		./docker/build.sh -t freertos -p /workspace/firmware/freeRTOS -b pico2 \
			$(if $(filter Debug,$(BUILD_TYPE)),-d,-r)

build-freertos-pico2-w: check-docker
	@echo "[INFO] Building FreeRTOS for Pico 2 W..."
	docker run --rm \
		--user ubuntu \
		-v $(ROOT_DIR):/workspace \
		$(IMAGE_NAME) \
		./docker/build.sh -t freertos -p /workspace/firmware/freeRTOS -b pico2_w \
			$(if $(filter Debug,$(BUILD_TYPE)),-d,-r)

#==============================================================================
# Zephyr Individual Builds
#==============================================================================
build-zephyr-pico: check-docker
	@echo "[INFO] Building Zephyr for Pico..."
	docker run --rm \
		--user ubuntu \
		-v $(ROOT_DIR):/workspace \
		$(IMAGE_NAME) \
		./docker/build.sh -t zephyr -p /workspace/firmware/zephyr/app -b rpi_pico

build-zephyr-pico-w: check-docker
	@echo "[INFO] Building Zephyr for Pico W..."
	docker run --rm \
		--user ubuntu \
		-v $(ROOT_DIR):/workspace \
		$(IMAGE_NAME) \
		./docker/build.sh -t zephyr -p /workspace/firmware/zephyr/app -b rpi_pico/rp2040/w

build-zephyr-pico2: check-docker
	@echo "[INFO] Building Zephyr for Pico 2..."
	docker run --rm \
		--user ubuntu \
		-v $(ROOT_DIR):/workspace \
		$(IMAGE_NAME) \
		./docker/build.sh -t zephyr -p /workspace/firmware/zephyr/app -b rpi_pico2

build-zephyr-pico2-w: check-docker
	@echo "[INFO] Building Zephyr for Pico 2 W..."
	docker run --rm \
		--user ubuntu \
		-v $(ROOT_DIR):/workspace \
		$(IMAGE_NAME) \
		./docker/build.sh -t zephyr -p /workspace/firmware/zephyr/app -b rpi_pico2/rp2350a/m33/w

#==============================================================================
# Custom Project Builds
#==============================================================================
build-pico: check-docker
ifndef PROJECT
	@echo "[ERROR] PROJECT path required"
	@echo "Usage: make build-pico PROJECT=/path/to/project TYPE=freertos|zephyr"
	@exit 1
endif
ifndef TYPE
	@echo "[ERROR] TYPE required"
	@echo "Usage: make build-pico PROJECT=/path/to/project TYPE=freertos|zephyr"
	@exit 1
endif
	docker run --rm \
		--user ubuntu \
		-v $(ROOT_DIR):/workspace \
		$(IMAGE_NAME) \
		./docker/build.sh -t $(TYPE) -p $(PROJECT) -b pico

build-pico-w: check-docker
ifndef PROJECT
	@echo "[ERROR] PROJECT path required"
	@exit 1
endif
ifndef TYPE
	@echo "[ERROR] TYPE required"
	@exit 1
endif
	docker run --rm \
		--user ubuntu \
		-v $(ROOT_DIR):/workspace \
		$(IMAGE_NAME) \
		./docker/build.sh -t $(TYPE) -p $(PROJECT) -b pico_w

build-pico2: check-docker
ifndef PROJECT
	@echo "[ERROR] PROJECT path required"
	@exit 1
endif
ifndef TYPE
	@echo "[ERROR] TYPE required"
	@exit 1
endif
	docker run --rm \
		--user ubuntu \
		-v $(ROOT_DIR):/workspace \
		$(IMAGE_NAME) \
		./docker/build.sh -t $(TYPE) -p $(PROJECT) -b pico2

build-pico2-w: check-docker
ifndef PROJECT
	@echo "[ERROR] PROJECT path required"
	@exit 1
endif
ifndef TYPE
	@echo "[ERROR] TYPE required"
	@exit 1
endif
	docker run --rm \
		--user ubuntu \
		-v $(ROOT_DIR):/workspace \
		$(IMAGE_NAME) \
		./docker/build.sh -t $(TYPE) -p $(PROJECT) -b pico2_w

#==============================================================================
# Testing
#==============================================================================
test-all:
	@echo "[INFO] Running comprehensive test of all supported boards..."
	./test-all.sh

#==============================================================================
# Cleanup
#==============================================================================
clean:
	@echo "[INFO] Cleaning firmware build artifacts..."
	rm -rf $(ROOT_DIR)/firmware

clean-all: clean
	@echo "[INFO] Removing Docker image..."
	docker rmi -f $(IMAGE_NAME) 2>/dev/null || true

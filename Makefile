#==============================================================================
# Raspberry Pi Pico RTOS Development Environment (Simplified)
#==============================================================================

IMAGE_NAME := rpi-pico-dev
CONTAINER_NAME := pico-dev
ROOT_DIR := $(shell pwd)
BUILD_TYPE ?= Release
BOARD ?= pico2_w

.DEFAULT_GOAL := help
.PHONY: help freertos zephyr shell clean clean-all rebuild test-all

# Docker run command template
DOCKER_RUN = docker run --rm --user ubuntu -v $(ROOT_DIR):/workspace $(IMAGE_NAME)

#==============================================================================
# Help
#==============================================================================
help:
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  Raspberry Pi Pico RTOS Development Environment"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "  ONE-COMMAND BUILD (creates project if needed, then builds):"
	@echo "  ─────────────────────────────────────────────────────────────────────"
	@echo ""
	@echo "  FreeRTOS:"
	@echo "    make freertos PROJECT=myapp                    # Pico 2 W (default)"
	@echo "    make freertos PROJECT=myapp BOARD=pico         # Pico"
	@echo "    make freertos PROJECT=myapp BOARD=pico_w       # Pico W"
	@echo "    make freertos PROJECT=myapp BOARD=pico2        # Pico 2"
	@echo ""
	@echo "  Zephyr:"
	@echo "    make zephyr PROJECT=myapp BOARD=rpi_pico                    # Pico"
	@echo "    make zephyr PROJECT=myapp BOARD=rpi_pico/rp2040/w           # Pico W"
	@echo "    make zephyr PROJECT=myapp BOARD=rpi_pico2/rp2350a/m33       # Pico 2"
	@echo "    make zephyr PROJECT=myapp BOARD=rpi_pico2/rp2350a/m33/w     # Pico 2 W"
	@echo ""
	@echo "  OTHER COMMANDS:"
	@echo "  ─────────────────────────────────────────────────────────────────────"
	@echo "    make shell       # Interactive dev shell"
	@echo "    make rebuild     # Rebuild Docker image"
	@echo "    make clean       # Remove firmware builds"
	@echo "    make clean-all   # Remove everything"
	@echo "    make test-all    # Test all board configurations"
	@echo ""
	@echo "  OPTIONS: BUILD_TYPE=Debug|Release (default: Release)"
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""

#==============================================================================
# Docker Setup (auto-builds if needed)
#==============================================================================
.docker-image:
	@docker image inspect $(IMAGE_NAME) >/dev/null 2>&1 || \
		(echo "[INFO] Building Docker image..." && \
		docker build -t $(IMAGE_NAME) -f docker/Dockerfile docker/)

rebuild:
	@echo "[INFO] Rebuilding Docker image..."
	@docker rmi -f $(IMAGE_NAME) 2>/dev/null || true
	docker build -t $(IMAGE_NAME) -f docker/Dockerfile docker/

#==============================================================================
# One-Command Builds (auto-init + build)
#==============================================================================
freertos: .docker-image
ifndef PROJECT
	$(error PROJECT required. Usage: make freertos PROJECT=myapp [BOARD=pico|pico_w|pico2|pico2_w])
endif
	@echo ""
	@echo "━━━ FreeRTOS Build: $(PROJECT) for $(BOARD) ━━━"
	@if [ ! -d "firmware/$(PROJECT)" ]; then \
		echo "[1/2] Creating project..."; \
		$(DOCKER_RUN) ./docker/init-freertos.sh $(PROJECT); \
	else \
		echo "[1/2] Project exists, skipping init..."; \
	fi
	@echo "[2/2] Building..."
	@$(DOCKER_RUN) ./docker/build.sh -t freertos -p /workspace/firmware/$(PROJECT) -b $(BOARD) \
		$(if $(filter Debug,$(BUILD_TYPE)),-d,-r)
	@echo ""
	@echo "✅ Done! Firmware: firmware/$(PROJECT)/build/*.uf2"
	@echo "   Flash: Hold BOOTSEL, connect Pico, copy .uf2 to RPI-RP2"
	@echo ""

zephyr: .docker-image
ifndef PROJECT
	$(error PROJECT required. Usage: make zephyr PROJECT=myapp BOARD=<board>)
endif
ifndef BOARD
	$(error BOARD required. Options: rpi_pico, rpi_pico/rp2040/w, rpi_pico2/rp2350a/m33, rpi_pico2/rp2350a/m33/w)
endif
	@echo ""
	@echo "━━━ Zephyr Build: $(PROJECT) for $(BOARD) ━━━"
	@if [ ! -d "firmware/$(PROJECT)/app" ]; then \
		echo "[1/2] Creating project..."; \
		$(DOCKER_RUN) ./docker/init-zephyr.sh $(PROJECT); \
	else \
		echo "[1/2] Project exists, skipping init..."; \
	fi
	@echo "[2/2] Building..."
	@$(DOCKER_RUN) ./docker/build.sh -t zephyr -p /workspace/firmware/$(PROJECT)/app -b $(BOARD)
	@echo ""
	@echo "✅ Done! Firmware: firmware/$(PROJECT)/app/build/zephyr/zephyr.uf2"
	@echo "   Flash: Hold BOOTSEL, connect Pico, copy .uf2 to RPI-RP2"
	@echo ""

#==============================================================================
# Development Shell
#==============================================================================
shell: .docker-image
	@echo "[INFO] Starting dev shell..."
	docker run -it --rm --name $(CONTAINER_NAME) --user ubuntu \
		-v $(ROOT_DIR):/workspace -w /workspace $(IMAGE_NAME) /bin/bash

#==============================================================================
# Testing & Cleanup
#==============================================================================
test-all:
	./test-all.sh

clean:
	@echo "[INFO] Cleaning firmware..."
	rm -rf $(ROOT_DIR)/firmware

clean-all: clean
	@echo "[INFO] Removing Docker image..."
	@docker rmi -f $(IMAGE_NAME) 2>/dev/null || true

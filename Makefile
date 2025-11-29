IMAGE_NAME = rpi-pico-dev
CONTAINER_NAME = pico-dev
ROOT_DIR = $(shell pwd)

.PHONY: help run shell build build-pico build-pico-w build-pico2 build-pico2-w init init-freertos init-zephyr clean

help:
	@echo "Raspberry Pi Pico Development Makefile"
	@echo ""
	@echo "Usage: make <target> PROJECT=<path/to/project>"
	@echo ""
	@echo "Available targets:"
	@echo "  build         - Build the Docker image"
	@echo "  run           - Run the Docker container interactively"
	@echo "  shell         - Launch a shell in the Docker container"
	@echo "  build-pico    - Build for Pico (H)"
	@echo "  build-pico-w  - Build for Pico W (H)"
	@echo "  build-pico2   - Build for Pico 2 (H)"
	@echo "  build-pico2-w - Build for Pico 2 W (H)"
	@echo "  init          - Initialize a new Pico project (usage: make init PROJECT=myproject)"
	@echo "  init-freertos - Initialize a FreeRTOS project"
	@echo "  init-zephyr   - Initialize a Zephyr project"
	@echo "  clean         - Remove container and image"
	@echo ""

build:
	@echo "Building Raspberry Pi Pico development image..."
	docker build --build-arg USER_ID=$(shell id -u) --build-arg GROUP_ID=$(shell id -g) -t $(IMAGE_NAME) docker/

run:
	docker run -it --rm \
		--name $(CONTAINER_NAME) \
		--privileged \
		--user pi \
		-v $(ROOT_DIR):/workspace \
		-v /dev:/dev \
		$(IMAGE_NAME)

shell:
	docker run -it --rm \
		--user pi \
		-v $(ROOT_DIR):/workspace \
		$(IMAGE_NAME) \
		/bin/bash

build-pico:
ifndef PROJECT
	@echo "Please provide PROJECT=path/to/project"
	@exit 1
endif
	docker run --rm \
		--user pi \
		-v $(ROOT_DIR):/workspace \
		$(IMAGE_NAME) \
		./scripts/build.sh -p $(PROJECT) -b rpi_pico

build-pico-w:
ifndef PROJECT
	@echo "Please provide PROJECT=path/to/project"
	@exit 1
endif
	docker run --rm \
		--user pi \
		-v $(ROOT_DIR):/workspace \
		$(IMAGE_NAME) \
		./scripts/build.sh -p $(PROJECT) -b rpi_pico/rp2040/w

build-pico2:
ifndef PROJECT
	@echo "Please provide PROJECT=path/to/project"
	@exit 1
endif
	docker run --rm \
		--user pi \
		-v $(ROOT_DIR):/workspace \
		$(IMAGE_NAME) \
		./scripts/build.sh -p $(PROJECT) -b rpi_pico2/rp2350a/m33

build-pico2-w:
ifndef PROJECT
	@echo "Please provide PROJECT=path/to/project"
	@exit 1
endif
	docker run --rm \
		--user pi \
		-v $(ROOT_DIR):/workspace \
		$(IMAGE_NAME) \
		./scripts/build.sh -p $(PROJECT) -b rpi_pico2/rp2350a/m33/w

init-freertos:
	docker run --rm \
		--user pi \
		-v $(ROOT_DIR):/workspace \
		$(IMAGE_NAME) \
		./scripts/init-freertos.sh

init-zephyr:
	docker run --rm \
		--user pi \
		-v $(ROOT_DIR):/workspace \
		$(IMAGE_NAME) \
		./scripts/init-zephyr.sh

init:
	@if [ -z "$(PROJECT)" ]; then \
		echo "Error: PROJECT name required. Usage: make init PROJECT=myproject"; \
		exit 1; \
	fi
	@echo "Creating new Pico project: $(PROJECT)"
	docker run --rm \
		-v $(ROOT_DIR):/workspace \
		$(IMAGE_NAME) \
		/bin/bash -c "cd /workspace && pico-init $(PROJECT)"

clean:
	@echo "Cleaning up containers and images..."
	-docker stop $(CONTAINER_NAME) 2>/dev/null || true
	-docker rm $(CONTAINER_NAME) 2>/dev/null || true
	-docker rmi $(IMAGE_NAME) 2>/dev/null || true

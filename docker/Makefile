.PHONY: build run shell clean help

IMAGE_NAME = rpi-pico-dev
CONTAINER_NAME = pico-dev
WORKSPACE_DIR = $(shell pwd)/..

help:
	@echo "Raspberry Pi Pico Development Docker"
	@echo ""
	@echo "Available commands:"
	@echo "  make build     - Build the Docker image"
	@echo "  make run       - Run container and start bash shell"
	@echo "  make shell     - Open a shell in running container"
	@echo "  make clean     - Remove container and image"
	@echo "  make init      - Initialize a new Pico project (usage: make init PROJECT=myproject)"
	@echo ""

build:
	@echo "Building Raspberry Pi Pico development image..."
	docker build -t $(IMAGE_NAME) .

run:
	@echo "Starting Pico development container..."
	docker run -it --rm \
		--name $(CONTAINER_NAME) \
		--privileged \
		-v $(WORKSPACE_DIR):/workspace \
		-v /dev:/dev \
		$(IMAGE_NAME)

shell:
	@echo "Opening shell in running container..."
	docker exec -it $(CONTAINER_NAME) /bin/bash

init:
	@if [ -z "$(PROJECT)" ]; then \
		echo "Error: PROJECT name required. Usage: make init PROJECT=myproject"; \
		exit 1; \
	fi
	@echo "Creating new Pico project: $(PROJECT)"
	docker run --rm \
		-v $(WORKSPACE_DIR):/workspace \
		$(IMAGE_NAME) \
		/bin/bash -c "cd /workspace && pico-init $(PROJECT)"

clean:
	@echo "Cleaning up containers and images..."
	-docker stop $(CONTAINER_NAME) 2>/dev/null || true
	-docker rm $(CONTAINER_NAME) 2>/dev/null || true
	-docker rmi $(IMAGE_NAME) 2>/dev/null || true
	@echo "Cleanup complete!"

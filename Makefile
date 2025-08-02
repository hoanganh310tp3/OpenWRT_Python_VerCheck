# Makefile for managing OpenWRT build inside Docker

IMAGE_NAME = openwrt-builder
CONTAINER_NAME = openwrt-container
OUTPUT_DIR = $(CURDIR)/output

.PHONY: build run package clean default

default: build

# Build the Docker image
build:
	sudo docker build -t $(IMAGE_NAME) .

# Run the container interactively with volume mounted
run:
	sudo docker run --rm -it \
		-v $(OUTPUT_DIR):/home/builder/openwrt/bin \
		--name $(CONTAINER_NAME) \
		$(IMAGE_NAME)

# Extract .ipk and firmware images to host output/
package:
	@echo "Copying .ipk and firmware files to output/..."
	mkdir -p $(OUTPUT_DIR)
	sudo docker run --rm \
		-v $(OUTPUT_DIR):/home/builder/openwrt/bin \
		--entrypoint /bin/bash \
		$(IMAGE_NAME) -c 'cp -r /home/builder/openwrt/bin/targets/*/*/*.img /home/builder/openwrt/bin/ 2>/dev/null || true && \
		  find /home/builder/openwrt/bin/packages/ -name "*.ipk" -exec cp {} /home/builder/openwrt/bin/ \; 2>/dev/null || true'

# Clean up Docker image and output folder
clean:
	sudo docker image rm $(IMAGE_NAME) || true
	sudo rm -rf $(OUTPUT_DIR) || true

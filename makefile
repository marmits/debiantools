.PHONY: run help

# Default target
run:
	@echo "Running run.sh with optional SSH_KEY parameter..."
	@if [ -n "$(SSH_KEY)" ]; then \
	./run.sh --ssh-key $(SSH_KEY); \
	else \
	./run.sh; \
	fi

# Update target : rebuild image and restart container
update:
	@echo "Updating Docker image and container..."
	@if [ ! -x ./update_docker_images.sh ]; then \
		echo "Error: update_docker_images.sh not found or not executable."; \
		exit 1; \
	fi
	@./update_docker_images.sh

# Display help
help:
	@echo "Usage: make [target]"
	@echo "Targets:"
	@echo "  help             Display this help message"
	@echo "  run              Execute run.sh with optional SSH_KEY parameter"
	@echo "  update           Rebuild Docker image with latest base and restart container"

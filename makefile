.PHONY: run help

# Default target
run:
	@echo "Running run.sh with optional SSH_KEY parameter..."
	@if [ -n "$(SSH_KEY)" ]; then \
	./run.sh --ssh-key $(SSH_KEY); \
	else \
	./run.sh; \
	fi

# Display help
help:
	@echo "Usage: make [target]"
	@echo "Targets:"
	@echo "  help             Display this help message"
	@echo "  run              Execute run.sh with optional SSH_KEY parameter"

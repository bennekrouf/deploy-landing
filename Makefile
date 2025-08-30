# api0 Deployment Makefile

# Variables
SHELL := /bin/bash
SERVICE ?= all

# Colors
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m

# Directories
SCRIPT_DIR := ./scripts
BACKUP_DIR := ./backups

.PHONY: setup build deploy update monitor backup logs status restart stop clean help

# Default target
help:
	@echo -e "$(GREEN)api0 Deployment System$(NC)"
	@echo -e "$(YELLOW)Available commands:$(NC)"
	@echo "  make setup      - Initial setup of repositories and dependencies"
	@echo "  make build      - Build all Rust and Node.js projects"
	@echo "  make deploy     - Deploy all services"
	@echo "  make update     - Update all services to latest version"
	@echo "  make monitor    - Monitor running services"
	@echo "  make backup     - Create a backup of data and configurations"
	@echo "  make logs       - View logs for a specific service (use SERVICE=name)"
	@echo "  make status     - Show status of all services"
	@echo "  make restart    - Restart services (use SERVICE=name for specific service)"
	@echo "  make stop       - Stop services (use SERVICE=name for specific service)"
	@echo "  make clean      - Clean up temporary files and caches"

# Initial setup
setup:
	@echo -e "$(YELLOW)Setting up api0 deployment system...$(NC)"
	@mkdir -p $(SCRIPT_DIR) $(BACKUP_DIR)
	@if [ ! -f $(SCRIPT_DIR)/setup.sh ]; then \
		echo -e "$(RED)Error: $(SCRIPT_DIR)/setup.sh not found.$(NC)"; \
		echo -e "Please create the setup script first."; \
		exit 1; \
	fi
	@chmod +x $(SCRIPT_DIR)/*.sh
	@$(SCRIPT_DIR)/setup.sh
	@echo -e "$(GREEN)Setup complete.$(NC)"

# Build all projects
build:
	@echo -e "$(YELLOW)Building api0 services...$(NC)"
	@if [ ! -f $(SCRIPT_DIR)/build.sh ]; then \
		echo -e "$(RED)Error: $(SCRIPT_DIR)/build.sh not found.$(NC)"; \
		echo -e "Please create the build script first."; \
		exit 1; \
	fi
	@chmod +x $(SCRIPT_DIR)/build.sh
	@$(SCRIPT_DIR)/build.sh
	@echo -e "$(GREEN)Build complete.$(NC)"

# Deploy all services
deploy:
	@echo -e "$(YELLOW)Deploying api0 services...$(NC)"
	@if [ ! -f $(SCRIPT_DIR)/deploy.sh ]; then \
		echo -e "$(RED)Error: $(SCRIPT_DIR)/deploy.sh not found.$(NC)"; \
		echo -e "Please create the deploy script first."; \
		exit 1; \
	fi
	@$(SCRIPT_DIR)/deploy.sh
	@echo -e "$(GREEN)Deployment complete.$(NC)"

# Update all services
update:
	@echo -e "$(YELLOW)Updating api0 services...$(NC)"
	@for repo in store dashboard landing grpc-logger semantic mayorana gateway; do \
		echo -e "$(YELLOW)Updating $repo...$(NC)"; \
		(cd $repo && git pull && [ -f Cargo.toml ] && cargo build --release || true); \
		(cd $repo && [ -f package.json ] && yarn install --frozen-lockfile || true); \
	done
	@pm2 reload all
	@echo -e "$(GREEN)Update complete.$(NC)"

# Monitor services
monitor:
	@echo -e "$(YELLOW)Monitoring api0 services...$(NC)"
	@pm2 monit

# Backup data and configurations
backup:
	@echo -e "$(YELLOW)Creating backup...$(NC)"
	@mkdir -p $(BACKUP_DIR)
	@TIMESTAMP=$(date +"%Y%m%d_%H%M%S"); \
	for repo in store dashboard landing grpc-logger semantic mayorana gateway; do \
		if [ -f $repo/config.yaml ]; then \
			echo -e "$(YELLOW)Backing up $repo/config.yaml...$(NC)"; \
			cp $repo/config.yaml $(BACKUP_DIR)/$repo-config-$TIMESTAMP.yaml; \
		fi; \
	done
	@echo -e "$(GREEN)Backup complete.$(NC)"

# View logs for a service
logs:
	@if [ "$(SERVICE)" = "all" ]; then \
		echo -e "$(YELLOW)Viewing logs for all services...$(NC)"; \
		pm2 logs; \
	else \
		echo -e "$(YELLOW)Viewing logs for $(SERVICE)...$(NC)"; \
		pm2 logs $(SERVICE); \
	fi

# Show status
status:
	@echo -e "$(YELLOW)api0 services status:$(NC)"
	@pm2 status

# Restart services
restart:
	@if [ "$(SERVICE)" = "all" ]; then \
		echo -e "$(YELLOW)Restarting all services...$(NC)"; \
		pm2 restart all; \
	else \
		echo -e "$(YELLOW)Restarting $(SERVICE)...$(NC)"; \
		pm2 restart $(SERVICE); \
	fi
	@echo -e "$(GREEN)Restart complete.$(NC)"

# Stop services
stop:
	@if [ "$(SERVICE)" = "all" ]; then \
		echo -e "$(YELLOW)Stopping all services...$(NC)"; \
		pm2 stop all; \
	else \
		echo -e "$(YELLOW)Stopping $(SERVICE)...$(NC)"; \
		pm2 stop $(SERVICE); \
	fi
	@echo -e "$(GREEN)Stop complete.$(NC)"

# Clean up
clean:
	@echo -e "$(YELLOW)Cleaning up...$(NC)"
	@find . -name "*.log" -type f -delete
	@find . -name "*.tmp" -type f -delete
	@echo -e "$(GREEN)Clean complete.$(NC)"

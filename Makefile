# api0 Deployment Makefile - Linux Standard with /opt

# Variables
SHELL := /bin/bash
SERVICE ?= all
APP_DIR := /opt/app
SERVICE_USER := app

# Colors
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m

# Repository information
REPOS := api0-landing mayorana

.PHONY: deploy setup-user setup-dirs logs status restart stop clean help install

# Default target
help:
	@echo -e "$(GREEN)App Deployment System$(NC)"
	@echo -e "$(YELLOW)Available commands:$(NC)"
	@echo "  make deploy     - One-command deploy (clone/pull + build + restart)"
	@echo "  make setup-user - Create app service user"
	@echo "  make setup-dirs - Create /opt/app directories"
	@echo "  make logs       - View logs for service (use SERVICE=name)"
	@echo "  make status     - Show status of all services"
	@echo "  make restart    - Restart services (use SERVICE=name for specific)"
	@echo "  make stop       - Stop services"
	@echo "  make clean      - Clean up temporary files"
	@echo "  make install    - Full system installation (user + dirs + deploy)"

# Full installation
install: setup-user setup-dirs deploy
	@echo -e "$(GREEN)Full installation complete.$(NC)"

# Create service user
setup-user:
	@echo -e "$(YELLOW)Creating app service user...$(NC)"
	@if ! id -u $(SERVICE_USER) >/dev/null 2>&1; then \
		sudo useradd --system --home-dir $(APP_DIR) --shell /bin/bash $(SERVICE_USER); \
		echo -e "$(GREEN)Created user $(SERVICE_USER)$(NC)"; \
	else \
		echo -e "$(YELLOW)User $(SERVICE_USER) already exists$(NC)"; \
	fi

# Setup directories
setup-dirs:
	@echo -e "$(YELLOW)Setting up directories in /opt/app...$(NC)"
	@sudo mkdir -p $(APP_DIR)/logs
	@sudo mkdir -p $(APP_DIR)/config
	@sudo mkdir -p $(APP_DIR)/backups
	@sudo chown -R $(SERVICE_USER):$(SERVICE_USER) $(APP_DIR)
	@sudo chmod 755 $(APP_DIR)
	@echo -e "$(GREEN)Directory created: $(APP_DIR)$(NC)"

# Main deploy command - handles everything
deploy:
	@echo -e "$(GREEN)Starting unified deployment...$(NC)"
	@sudo cp $(CURDIR)/Makefile $(APP_DIR)/
	@sudo cp $(CURDIR)/ecosystem.config.js $(APP_DIR)/
	@sudo cp $(CURDIR)/server.js $(APP_DIR)/
	@sudo chown $(SERVICE_USER):$(SERVICE_USER) $(APP_DIR)/Makefile $(APP_DIR)/ecosystem.config.js $(APP_DIR)/server.js
	@sudo -u $(SERVICE_USER) bash -c 'cd $(APP_DIR) && make _deploy_as_service_user'
	@echo -e "$(GREEN)Deployment complete!$(NC)"

# Internal target run as service user
_deploy_as_service_user:
	@echo -e "$(YELLOW)Running as $(SERVICE_USER) in $(DEPLOY_DIR)...$(NC)"
	@$(MAKE) -f $(CURDIR)/Makefile _check_dependencies
	@$(MAKE) -f $(CURDIR)/Makefile _clone_or_update
	@$(MAKE) -f $(CURDIR)/Makefile _build_all
	@$(MAKE) -f $(CURDIR)/Makefile _setup_configs
	@$(MAKE) -f $(CURDIR)/Makefile _restart_services

# Check dependencies
_check_dependencies:
	@echo -e "$(YELLOW)Checking dependencies...$(NC)"
	@command -v git >/dev/null 2>&1 || { echo -e "$(RED)git not found$(NC)"; exit 1; }
	@command -v node >/dev/null 2>&1 || { echo -e "$(RED)node not found$(NC)"; exit 1; }
	@command -v yarn >/dev/null 2>&1 || { echo -e "$(RED)yarn not found$(NC)"; exit 1; }
	@command -v pm2 >/dev/null 2>&1 || { echo -e "$(RED)pm2 not found$(NC)"; exit 1; }
	@echo -e "$(GREEN)All dependencies satisfied$(NC)"

# Clone or update repositories
_clone_or_update:
	@echo -e "$(YELLOW)Updating repositories...$(NC)"
	@for repo in $(REPOS); do \
		echo -e "$(YELLOW)Processing $$repo...$(NC)"; \
		if [ -d "$$repo" ]; then \
			echo -e "$(YELLOW)Updating $$repo...$(NC)"; \
			(cd $$repo && git pull); \
		else \
			echo -e "$(YELLOW)Cloning $$repo...$(NC)"; \
			git clone git@github.com:bennekrouf/$$repo.git $$repo; \
		fi; \
	done

# Build all projects
_build_all:
	@echo -e "$(YELLOW)Building all projects...$(NC)"
	@# Build Node.js projects
	@for repo in landing mayorana; do \
		if [ -d "$repo" ]; then \
			echo -e "$(YELLOW)Building Node.js project: $repo...$(NC)"; \
			(cd $repo && yarn install --frozen-lockfile && yarn build); \
		fi; \
	done
	@# Special handling for mayorana
	@if [ -d "mayorana" ]; then \
		echo -e "$(YELLOW)Setting up mayorana server.js...$(NC)"; \
		if [ ! -f "mayorana/server.js" ]; then \
			cp $(CURDIR)/server.js mayorana/server.js; \
		fi; \
	fi

# Setup configuration files
_setup_configs:
	@echo -e "$(YELLOW)Setting up configurations...$(NC)"
	@for repo in $(REPOS); do \
		if [ -d "$repo" ] && [ ! -f "$repo/config.yaml" ]; then \
			echo -e "$(YELLOW)Creating config for $repo...$(NC)"; \
			echo "service:" > $repo/config.yaml; \
			echo "  name: $repo" >> $repo/config.yaml; \
			echo "  version: 1.0.0" >> $repo/config.yaml; \
		fi; \
	done

# Check dependencies
_check_dependencies:
	@echo -e "$(YELLOW)Checking dependencies...$(NC)"
	@command -v git >/dev/null 2>&1 || { echo -e "$(RED)git not found$(NC)"; exit 1; }
	@command -v node >/dev/null 2>&1 || { echo -e "$(RED)node not found$(NC)"; exit 1; }
	@command -v yarn >/dev/null 2>&1 || { echo -e "$(RED)yarn not found$(NC)"; exit 1; }
	@command -v pm2 >/dev/null 2>&1 || { echo -e "$(RED)pm2 not found$(NC)"; exit 1; }
	@echo -e "$(GREEN)All dependencies satisfied$(NC)"
	@# Copy ecosystem config
	@cp $(CURDIR)/ecosystem.config.js .

# Restart services with PM2
_restart_services:
	@echo -e "$(YELLOW)Restarting services with PM2...$(NC)"
	@if pm2 list | grep -q "landing\|mayorana"; then \
		pm2 reload ecosystem.config.js; \
	else \
		pm2 start ecosystem.config.js; \
	fi
	@pm2 save

# View logs
logs:
	@if [ "$(SERVICE)" = "all" ]; then \
		sudo -u $(SERVICE_USER) pm2 logs; \
	else \
		sudo -u $(SERVICE_USER) pm2 logs $(SERVICE); \
	fi

# Show status
status:
	@echo -e "$(YELLOW)api0 services status:$(NC)"
	@sudo -u $(SERVICE_USER) pm2 status

# Restart services
restart:
	@if [ "$(SERVICE)" = "all" ]; then \
		echo -e "$(YELLOW)Restarting all services...$(NC)"; \
		sudo -u $(SERVICE_USER) pm2 restart all; \
	else \
		echo -e "$(YELLOW)Restarting $(SERVICE)...$(NC)"; \
		sudo -u $(SERVICE_USER) pm2 restart $(SERVICE); \
	fi

# Stop services
stop:
	@echo -e "$(YELLOW)Stopping services...$(NC)"
	@if [ "$(SERVICE)" = "all" ]; then \
		sudo -u $(SERVICE_USER) pm2 stop all; \
	else \
		sudo -u $(SERVICE_USER) pm2 stop $(SERVICE); \
	fi

# Clean up
clean:
	@echo -e "$(YELLOW)Cleaning up...$(NC)"
	@sudo -u $(SERVICE_USER) find $(DEPLOY_DIR) -name "*.log" -type f -delete 2>/dev/null || true
	@sudo -u $(SERVICE_USER) find $(DEPLOY_DIR) -name "*.tmp" -type f -delete 2>/dev/null || true
	@for repo in $(REPOS); do \
		if [ -d "$(DEPLOY_DIR)/$$repo/target" ]; then \
			sudo -u $(SERVICE_USER) rm -rf $(DEPLOY_DIR)/$$repo/target/debug; \
		fi; \
	done

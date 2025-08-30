#!/bin/bash
set -e

# Define colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Repository information
REPOS=(
  "store:git@github.com:bennekrouf/store.git"
  "dashboard:git@github.com:bennekrouf/dashboard.git"
  "landing:git@github.com:bennekrouf/landing.git"
  "grpc-logger:git@github.com:bennekrouf/grpc-logger.git"
  "semantic:git@github.com:bennekrouf/semantic.git"
  "mayorana:git@github.com:bennekrouf/mayorana.git"
  "gateway:git@github.com:bennekrouf/gateway.git"
)

# Function to display banner
show_banner() {
  echo -e "${GREEN}"
  echo "======================================================"
  echo "  api0 Deployment System - Setup"
  echo "  $(date)"
  echo "======================================================"
  echo -e "${NC}"
}

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function to check dependencies
check_dependencies() {
  echo -e "${YELLOW}Checking dependencies...${NC}"

  local deps=("git" "pm2" "node" "rustc" "cargo" "yarn")
  local missing=()

  for dep in "${deps[@]}"; do
    if ! command_exists "$dep"; then
      missing+=("$dep")
    fi
  done

  if [ ${#missing[@]} -ne 0 ]; then
    echo -e "${RED}Error: Missing dependencies: ${missing[*]}${NC}"
    echo "Please install the required dependencies and run the script again."
    exit 1
  fi

  echo -e "${GREEN}All dependencies satisfied.${NC}"
}

# Function to clone repositories
clone_repositories() {
  echo -e "${YELLOW}Cloning repositories...${NC}"

  for repo_info in "${REPOS[@]}"; do
    IFS=':' read -r repo_name repo_url <<<"$repo_info"

    if [ -d "$repo_name" ]; then
      echo -e "${YELLOW}$repo_name directory already exists, skipping...${NC}"
    else
      echo -e "${YELLOW}Cloning $repo_name...${NC}"
      git clone "$repo_url" "$repo_name"
    fi
  done

  echo -e "${GREEN}All repositories cloned successfully.${NC}"
}

# Function to setup configuration files
setup_config() {
  echo -e "${YELLOW}Setting up configuration files...${NC}"

  # Create default config.yaml in each project directory
  for repo_info in "${REPOS[@]}"; do
    IFS=':' read -r repo_name repo_url <<<"$repo_info"

    if [ ! -f "$repo_name/config.yaml" ]; then
      echo -e "${YELLOW}Creating default configuration for $repo_name...${NC}"

      # Create a minimal configuration file
      cat >"$repo_name/config.yaml" <<EOF
# Default configuration for $repo_name
service:
  name: $repo_name
  version: 1.0.0
EOF
    else
      echo -e "${YELLOW}Configuration for $repo_name already exists, skipping...${NC}"
    fi
  done

  echo -e "${GREEN}Configuration setup complete.${NC}"
}

# Function to create backup directory
setup_backup_dir() {
  echo -e "${YELLOW}Setting up backup directory...${NC}"
  mkdir -p ./backups
  echo -e "${GREEN}Backup directory created.${NC}"
}

# Main function
main() {
  show_banner
  check_dependencies
  clone_repositories
  setup_config
  setup_backup_dir

  echo -e "${GREEN}"
  echo "======================================================"
  echo "  api0 Setup Complete!"
  echo "  Next steps:"
  echo "  1. Run 'make deploy' to deploy all services"
  echo "  2. Run 'make status' to check service status"
  echo "======================================================"
  echo -e "${NC}"
}

# Run the main function
main

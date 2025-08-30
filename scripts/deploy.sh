#!/bin/bash
set -e

# Define colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Load environment variables
if [ -f .env ]; then
  echo -e "${YELLOW}Loading environment variables...${NC}"
  source .env
fi

# Repository information
REPOS=(
  "store:git@github.com:bennekrouf/store.git"
  "dashboard:git@github.com:bennekrouf/dashboard.git"
  "landing:git@github.com:bennekrouf/landing.git"
  "grpc-logger:git@github.com:bennekrouf/grpc-logger.git"
  "semantic:git@github.com:bennekrouf/semantic.git"
  "mayorana:git@github.com:bennekrouf/mayorana.git"
  "gateway:git@github.com:bennekrouf/gateway.git"
  "ai-uploader:git@github.com:bennekrouf/ai-uploader.git"
)

# Detect platform and set target directory path
detect_platform() {
  local project=$1

  if [[ "$(uname)" == "Darwin" ]]; then
    # macOS
    if [[ "$(uname -m)" == "arm64" ]]; then
      # Apple Silicon (M1/M2/M3)
      echo "$project/target/aarch64-apple-darwin/release/$project"
    else
      # Intel Mac
      echo "$project/target/release/$project"
    fi
  else
    # Linux and others
    echo "$project/target/release/$project"
  fi
}

# Function to display banner
show_banner() {
  echo -e "${GREEN}"
  echo "======================================================"
  echo "  api0 Deployment System"
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

# Function to clone or update repositories
setup_repositories() {
  echo -e "${YELLOW}Setting up repositories...${NC}"

  for repo_info in "${REPOS[@]}"; do
    IFS=':' read -r repo_name repo_url <<<"$repo_info"

    if [ -d "$repo_name" ]; then
      echo -e "${YELLOW}Updating $repo_name...${NC}"
      (cd "$repo_name" && git pull)
    else
      echo -e "${YELLOW}Cloning $repo_name...${NC}"
      git clone "$repo_url" "$repo_name"
    fi
  done

  echo -e "${GREEN}All repositories set up successfully.${NC}"
}

# Function to verify Rust projects are built
verify_rust_projects() {
  echo -e "${YELLOW}Verifying Rust projects are built...${NC}"

  local rust_projects=("store" "grpc-logger" "semantic" "gateway" "ai-uploader")

  for project in "${rust_projects[@]}"; do
    echo -e "${YELLOW}Checking $project binary...${NC}"

    # Get the expected binary path for this platform
    local binary_path=$(detect_platform "$project")

    # Try multiple possible locations
    if [ -f "$binary_path" ]; then
      echo -e "${GREEN}Found binary at: $binary_path${NC}"
    elif [ -f "$project/target/release/$project" ]; then
      echo -e "${GREEN}Found binary at: $project/target/release/$project${NC}"
    elif [[ "$(uname)" == "Darwin" && "$(uname -m)" == "arm64" && -f "$project/target/aarch64-apple-darwin/release/$project" ]]; then
      echo -e "${GREEN}Found binary at: $project/target/aarch64-apple-darwin/release/$project${NC}"
    else
      # Look for the binary anywhere in the target directory
      local found_binary=$(find "$project/target" -name "$project" -type f -executable | grep -v "\.d" | head -n 1)

      if [[ -n "$found_binary" ]]; then
        echo -e "${GREEN}Found binary at alternate location: $found_binary${NC}"
      else
        echo -e "${RED}Error: Binary for $project not found!${NC}"
        echo -e "${YELLOW}Please run 'make build' first to build all projects.${NC}"
        echo -e "${YELLOW}Expected location: $binary_path${NC}"
        exit 1
      fi
    fi
  done

  echo -e "${GREEN}All Rust projects verified.${NC}"
}

# Function to verify Node.js projects are set up
verify_node_projects() {
  echo -e "${YELLOW}Verifying Node.js projects are set up...${NC}"

  local node_projects=("dashboard" "landing" "mayorana")

  for project in "${node_projects[@]}"; do
    echo -e "${YELLOW}Checking $project...${NC}"
    if [ ! -d "$project/node_modules" ]; then
      echo -e "${RED}Error: Node modules for $project not found!${NC}"
      echo -e "${YELLOW}Please run 'make build' first to build all projects.${NC}"
      exit 1
    fi
  done

  echo -e "${GREEN}All Node.js projects verified.${NC}"
}

# Function to setup configuration files
setup_config() {
  echo -e "${YELLOW}Setting up configuration files...${NC}"

  # Create default config.yaml in each project directory if it doesn't exist
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

# Function to generate PM2 ecosystem file
generate_ecosystem_file() {
  echo -e "${YELLOW}Generating PM2 ecosystem file...${NC}"

  # Start the ecosystem file
  cat >ecosystem.config.js <<EOF
module.exports = {
  apps: [
EOF

  # Add Rust services
  local rust_projects=("store" "grpc-logger" "semantic" "gateway")
  local ports=(3000 3001 3002 3003)

  for i in "${!rust_projects[@]}"; do
    local project="${rust_projects[$i]}"
    local port="${ports[$i]}"
    local binary_path=$(detect_platform "$project")

    # Find the actual binary if the expected path doesn't exist
    if [ ! -f "$binary_path" ]; then
      local found_binary=$(find "$project/target" -name "$project" -type f -executable | grep -v "\.d" | head -n 1)
      if [[ -n "$found_binary" ]]; then
        binary_path="$found_binary"
      fi
    fi

    cat >>ecosystem.config.js <<EOF
    {
      name: "${project}",
      script: "${binary_path}",
      instances: 1,
      exec_mode: "fork",
      env: {
        NODE_ENV: "production",
        PORT: ${port},
        CONFIG_PATH: "./${project}/config.yaml"
      },
      watch: false,
      time: true
    },
EOF
  done

  # Add Node.js services
  local node_projects=("dashboard" "landing")
  local node_ports=(3004 3005)

  for i in "${!node_projects[@]}"; do
    local project="${node_projects[$i]}"
    local port="${node_ports[$i]}"

    cat >>ecosystem.config.js <<EOF
    {
      name: "${project}",
      cwd: "./${project}",
      script: "npm",
      args: "start",
      instances: 1,
      exec_mode: "fork",
      env: {
        NODE_ENV: "production",
        PORT: ${port},
        CONFIG_PATH: "./config.yaml"
      },
      watch: false,
      time: true
    },
EOF
  done

  # Add Mayorana with server.js for SSR
  cat >>ecosystem.config.js <<EOF
    {
      name: "mayorana",
      cwd: "./mayorana",
      script: "node",
      args: "server.js",
      instances: 1,
      exec_mode: "fork",
      env: {
        NODE_ENV: "production",
        PORT: 3006,
        CONFIG_PATH: "./config.yaml"
      },
      watch: false,
      time: true
    }
  ]
};
EOF

  echo -e "${GREEN}PM2 ecosystem file generated.${NC}"
}

# Function to setup server.js for Mayorana
setup_mayorana_server() {
  echo -e "${YELLOW}Setting up server.js for Mayorana...${NC}"

  # Check if mayorana directory exists
  if [ ! -d "mayorana" ]; then
    echo -e "${RED}Error: Mayorana directory not found!${NC}"
    exit 1
  fi

  # Create server.js if it doesn't exist
  if [ ! -f "mayorana/server.js" ]; then
    echo -e "${YELLOW}Creating server.js for Mayorana...${NC}"

    cat >"mayorana/server.js" <<EOF
const { createServer } = require('http');
const { parse } = require('url');
const next = require('next');

const dev = process.env.NODE_ENV !== 'production';
const hostname = 'localhost';
const port = process.env.PORT || 3006;

// Prepare the Next.js app
const app = next({ dev, hostname, port });
const handle = app.getRequestHandler();

app.prepare().then(() => {
  createServer(async (req, res) => {
    try {
      // Parse the URL
      const parsedUrl = parse(req.url, true);
      
      // Let Next.js handle the request
      await handle(req, res, parsedUrl);
    } catch (err) {
      console.error('Error occurred handling request:', req.url, err);
      res.statusCode = 500;
      res.end('Internal Server Error');
    }
  }).listen(port, (err) => {
    if (err) throw err;
    console.log(\`> Ready on http://\${hostname}:\${port}\`);
  });
});
EOF

    echo -e "${GREEN}Created server.js for Mayorana.${NC}"
  else
    echo -e "${YELLOW}server.js for Mayorana already exists, skipping...${NC}"
  fi

  # Update package.json if needed
  if [ -f "mayorana/package.json" ]; then
    # Check if we need to update the start script
    if grep -q "\"start\": \"next start\"" "mayorana/package.json"; then
      echo -e "${YELLOW}Updating start script in package.json...${NC}"

      # Use sed to replace the start script (compatible with both MacOS and Linux)
      if [[ "$(uname)" == "Darwin" ]]; then
        # MacOS version of sed
        sed -i '' 's/"start": "next start"/"start": "node server.js"/' "mayorana/package.json"
      else
        # Linux version of sed
        sed -i 's/"start": "next start"/"start": "node server.js"/' "mayorana/package.json"
      fi

      echo -e "${GREEN}Updated start script in package.json.${NC}"
    fi
  fi
}

# Function to start services with PM2
start_services() {
  echo -e "${YELLOW}Starting services with PM2...${NC}"

  # Generate the ecosystem file first
  generate_ecosystem_file

  # Setup Mayorana server.js
  setup_mayorana_server

  # Start or reload PM2 processes
  if pm2 list | grep -q "semantic"; then
    echo -e "${YELLOW}Reloading existing PM2 processes...${NC}"
    pm2 reload ecosystem.config.js
  else
    echo -e "${YELLOW}Starting PM2 processes...${NC}"
    pm2 start ecosystem.config.js
  fi

  # Save PM2 configuration
  pm2 save

  echo -e "${GREEN}Services started successfully.${NC}"
}

# Main function
main() {
  show_banner
  check_dependencies
  setup_repositories
  verify_rust_projects
  verify_node_projects
  setup_config
  start_services

  echo -e "${GREEN}"
  echo "======================================================"
  echo "  api0 Deployment Complete!"
  echo "  Check status with: pm2 status"
  echo "======================================================"
  echo -e "${NC}"
}

# Run the main function
main

#!/bin/bash
set -e
# Define colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Check if cargo exists
if ! command_exists cargo; then
  echo -e "${RED}Error: Rust toolchain not found. Please install Rust first.${NC}"
  exit 1
fi

# Check if yarn exists
if ! command_exists yarn; then
  echo -e "${RED}Error: Yarn not found. Please install Yarn first.${NC}"
  exit 1
fi

# Function to display banner
show_banner() {
  echo -e "${GREEN}"
  echo "======================================================"
  echo "  api0 Build System"
  echo "  $(date)"
  echo "======================================================"
  echo -e "${NC}"
}

# Build Rust projects
build_rust_projects() {
  echo -e "${YELLOW}Building Rust projects...${NC}"
  local rust_projects=("store" "grpc-logger" "semantic" "gateway" "ai-uploader")

  # Detect platform
  local platform="unknown"
  local target_dir="release"

  if [[ "$(uname)" == "Darwin" ]]; then
    # Check if M1/M2 Mac (Apple Silicon)
    if [[ "$(uname -m)" == "arm64" ]]; then
      platform="macos-arm"
      target_dir="aarch64-apple-darwin/release"
    else
      # Intel Mac
      platform="macos-intel"
      target_dir="x86_64-apple-darwin/release"
    fi
  elif [[ "$(uname)" == "Linux" ]]; then
    # Check Linux architecture
    if [[ "$(uname -m)" == "x86_64" ]]; then
      platform="linux-x86_64"
      target_dir="release"
    elif [[ "$(uname -m)" == "aarch64" ]]; then
      platform="linux-arm64"
      target_dir="aarch64-unknown-linux-gnu/release"
    fi
  fi

  echo -e "${YELLOW}Detected platform: $platform${NC}"
  echo -e "${YELLOW}Using target directory: target/$target_dir${NC}"

  for project in "${rust_projects[@]}"; do
    if [ -d "$project" ]; then
      echo -e "${YELLOW}Building $project...${NC}"

      # Build the project
      (cd "$project" && cargo build --release)

      # Verify binary was created - using multiple possible paths
      if [[ -f "$project/target/$target_dir/$project" ]]; then
        echo -e "${GREEN}Binary found at: $project/target/$target_dir/$project${NC}"
      elif [[ -f "$project/target/release/$project" ]]; then
        echo -e "${GREEN}Binary found at: $project/target/release/$project${NC}"
        # Copy to expected target_dir if different from release
        if [[ "$target_dir" != "release" ]]; then
          mkdir -p "$project/target/$target_dir"
          cp "$project/target/release/$project" "$project/target/$target_dir/"
          echo -e "${YELLOW}Copied binary to: $project/target/$target_dir/$project${NC}"
        fi
      else
        # Try to find the binary with find command as fallback
        local found_binary=$(find "$project/target" -name "$project" -type f -executable | grep -v "\.d" | head -n 1)

        if [[ -n "$found_binary" ]]; then
          echo -e "${YELLOW}Binary found at non-standard location: $found_binary${NC}"
          # Copy to expected target_dir
          mkdir -p "$project/target/$target_dir"
          cp "$found_binary" "$project/target/$target_dir/"
          echo -e "${YELLOW}Copied binary to: $project/target/$target_dir/$project${NC}"
        else
          echo -e "${RED}Error: Build failed for $project. Binary not found.${NC}"
          echo -e "${YELLOW}Searched in:${NC}"
          echo -e "${YELLOW}- $project/target/$target_dir/$project${NC}"
          echo -e "${YELLOW}- $project/target/release/$project${NC}"
          exit 1
        fi
      fi
    else
      echo -e "${RED}Error: Directory for $project not found.${NC}"
      echo -e "${YELLOW}Make sure to run setup.sh first to clone all repositories.${NC}"
      exit 1
    fi
  done

  echo -e "${GREEN}All Rust projects built successfully.${NC}"
  echo -e "${YELLOW}Build artifacts can be found in the target directories of each project.${NC}"
}

# Create custom server.js for mayorana
create_server_js() {
  local project="mayorana"
  if [ -d "$project" ]; then
    echo -e "${YELLOW}Creating custom server.js for $project...${NC}"

    # Create server.js only if it doesn't exist
    if [ ! -f "$project/server.js" ]; then
      cat >"$project/server.js" <<'EOF'
const { createServer } = require('http');
const { parse } = require('url');
const next = require('next');

const dev = process.env.NODE_ENV !== 'production';
const hostname = 'localhost';
const port = process.env.PORT || 3000;

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
    console.log(`> Ready on http://${hostname}:${port}`);
  });
});
EOF
      echo -e "${GREEN}Created server.js for server-side rendering${NC}"
    else
      echo -e "${YELLOW}server.js already exists, skipping creation${NC}"
    fi

    # Update package.json start script if needed
    if [ -f "$project/package.json" ]; then
      # Check if the start script needs to be updated
      if grep -q "\"start\": \"next start\"" "$project/package.json"; then
        echo -e "${YELLOW}Updating start script in package.json...${NC}"
        # Use sed to replace the start script
        sed -i.bak 's/"start": "next start"/"start": "node server.js"/' "$project/package.json" && rm "$project/package.json.bak"
        echo -e "${GREEN}Updated start script in package.json${NC}"
      fi
    fi
  else
    echo -e "${RED}Error: Directory for $project not found.${NC}"
    echo -e "${YELLOW}Make sure to run setup.sh first to clone all repositories.${NC}"
    exit 1
  fi
}

# Build Node.js projects
build_node_projects() {
  echo -e "${YELLOW}Building Node.js projects...${NC}"
  local node_projects=("dashboard" "landing" "mayorana")
  for project in "${node_projects[@]}"; do
    if [ -d "$project" ]; then
      echo -e "${YELLOW}Building $project...${NC}"

      # Special handling for mayorana - generate blog data first
      if [ "$project" == "mayorana" ]; then
        echo -e "${YELLOW}Generating blog data for mayorana...${NC}"
        (cd "$project" && node scripts/generate-blog-data.js)

        # Create server.js for mayorana
        create_server_js
      fi

      # Build the project
      (cd "$project" && yarn install --frozen-lockfile && yarn build)
    else
      echo -e "${RED}Error: Directory for $project not found.${NC}"
      echo -e "${YELLOW}Make sure to run setup.sh first to clone all repositories.${NC}"
      exit 1
    fi
  done
  echo -e "${GREEN}All Node.js projects built successfully.${NC}"
}

# Main function
main() {
  show_banner
  build_rust_projects
  build_node_projects
  echo -e "${GREEN}"
  echo "======================================================"
  echo "  api0 Build Complete!"
  echo "  All projects have been built successfully."
  echo "  You can now run 'make deploy' to deploy the services."
  echo "======================================================"
  echo -e "${NC}"
}

# Run the main function
main

// ecosystem.config.js - Cross-platform PM2 configuration

// Detect platform and architecture for binary paths
const os = require('os');
const platform = os.platform();
const arch = os.arch();

// Determine the target directory based on platform and architecture
let targetDir;
if (platform === 'darwin') {
  // macOS
  if (arch === 'arm64') {
    targetDir = 'target/aarch64-apple-darwin/release';
  } else {
    targetDir = 'target/release';  // x86_64 macOS
  }
} else if (platform === 'linux') {
  // Linux
  if (arch === 'arm64' || arch === 'aarch64') {
    targetDir = 'target/aarch64-unknown-linux-gnu/release';
  } else {
    targetDir = 'target/release';  // x86_64 Linux
  }
} else {
  // Default fallback
  targetDir = 'target/release';
}

console.log(`Detected platform: ${platform}, architecture: ${arch}`);
console.log(`Using binary path: ${targetDir}`);

module.exports = {
  apps: [
    {
      name: "ai-uploader",
      script: `ai-uploader/${targetDir}/ai-uploader`,
      instances: 1,
      exec_mode: "fork",
      env: {
        NODE_ENV: "production",
        PORT: 8080,
        CONFIG_PATH: "./ai-uploader/config.yaml"
      },
      watch: false,
      time: true,
      max_memory_restart: "500M"
    },
    {
      name: "store",
      script: `store/${targetDir}/store`,
      instances: 1,
      exec_mode: "fork",
      env: {
        NODE_ENV: "production",
        PORT: 3000,
        CONFIG_PATH: "./store/config.yaml"
      },
      watch: false,
      time: true,
      max_memory_restart: "500M"
    },
    {
      name: "grpc-logger",
      script: `grpc-logger/${targetDir}/grpc-logger`,
      instances: 1,
      exec_mode: "fork",
      env: {
        NODE_ENV: "production",
        PORT: 3001,
        CONFIG_PATH: "./grpc-logger/config.yaml"
      },
      watch: false,
      time: true,
      max_memory_restart: "500M"
    },
    {
      name: "semantic",
      script: `semantic/${targetDir}/semantic`,
      args: "--provider cohere --api http://127.0.0.1:50057",
      instances: 1,
      exec_mode: "fork",
      env: {
        NODE_ENV: "production",
        PORT: 3002,
        CONFIG_PATH: "./semantic/config.yaml",
        PROVIDER: "cohere",
        API_URL: "http://127.0.0.1:50057"
      },
      watch: false,
      time: true,
      max_memory_restart: "500M"
    },
    {
      name: "gateway",
      script: `gateway/${targetDir}/gateway`,
      instances: 1,
      exec_mode: "fork",
      env: {
        NODE_ENV: "production",
        PORT: 3003,
        CONFIG_PATH: "./gateway/config.yaml"
      },
      watch: false,
      time: true,
      max_memory_restart: "500M"
    },
    {
      name: "dashboard",
      cwd: "./dashboard",
      script: "npm",
      args: "start",
      instances: 1,
      exec_mode: "fork",
      env: {
        NODE_ENV: "production",
        PORT: 3004,
        CONFIG_PATH: "./config.yaml"
      },
      watch: false,
      time: true,
      max_memory_restart: "500M"
    },
    {
      name: "landing",
      cwd: "./landing",
      script: "npm",
      args: "start",
      instances: 1,
      exec_mode: "fork",
      env: {
        NODE_ENV: "production",
        PORT: 3005,
        CONFIG_PATH: "./config.yaml"
      },
      watch: false,
      time: true,
      max_memory_restart: "500M"
    },
    {
      name: "mayorana",
      cwd: "./mayorana",
      script: "node_modules/.bin/next",
      args: "start -p 3006",
      instances: 1,
      exec_mode: "fork",
      env: {
        NODE_ENV: "production",
        PORT: 3006,
        CONFIG_PATH: "./config.yaml"
      },
      watch: false,
      time: true,
      max_memory_restart: "500M",
      env_production: {
        NODE_ENV: "production"
      }
    }
  ]
};

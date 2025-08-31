// ecosystem.config.js - Linux Standard with /opt deployment

const path = require('path');

// Base directory is /opt/api0
const BASE_DIR = '/opt/api0';

console.log(`Base directory: ${BASE_DIR}`);

module.exports = {
  apps: [
    {
      name: "landing",
      cwd: path.join(BASE_DIR, 'landing'),
      script: "npm",
      args: "start",
      instances: 1,
      exec_mode: "fork",
      env: {
        NODE_ENV: "production",
        PORT: 3005,
        CONFIG_PATH: "./config.yaml"
      },
      error_file: path.join(BASE_DIR, 'logs/landing.error.log'),
      out_file: path.join(BASE_DIR, 'logs/landing.out.log'),
      log_file: path.join(BASE_DIR, 'logs/landing.log'),
      time: true,
      max_memory_restart: "500M"
    },
    {
      name: "mayorana",
      cwd: path.join(BASE_DIR, 'mayorana'),
      script: "node",
      args: "server.js",
      instances: 1,
      exec_mode: "fork",
      env: {
        NODE_ENV: "production",
        PORT: 3006,
        CONFIG_PATH: "./config.yaml"
      },
      error_file: path.join(BASE_DIR, 'logs/mayorana.error.log'),
      out_file: path.join(BASE_DIR, 'logs/mayorana.out.log'),
      log_file: path.join(BASE_DIR, 'logs/mayorana.log'),
      time: true,
      max_memory_restart: "500M"
    }
  ]
};

// ecosystem.config.js - Single /opt/app directory

const path = require('path');

// Single app directory containing both projects
const APP_DIR = '/opt/app';

console.log(`App directory: ${APP_DIR}`);

module.exports = {
  apps: [
    {
      name: "api0-landing",
      cwd: path.join(APP_DIR, 'api0-landing'),
      script: "npm",
      args: "start",
      instances: 1,
      exec_mode: "fork",
      env: {
        NODE_ENV: "production",
        PORT: 3005,
        CONFIG_PATH: "./config.yaml"
      },
      error_file: path.join(APP_DIR, 'logs/api0-landing.error.log'),
      out_file: path.join(APP_DIR, 'logs/api0-landing.out.log'),
      log_file: path.join(APP_DIR, 'logs/api0-landing.log'),
      time: true,
      max_memory_restart: "500M"
    },
    {
      name: "mayorana",
      cwd: path.join(APP_DIR, 'mayorana'),
      script: "node",
      args: "server.js",
      instances: 1,
      exec_mode: "fork",
      env: {
        NODE_ENV: "production",
        PORT: 3006,
        CONFIG_PATH: "./config.yaml"
      },
      error_file: path.join(APP_DIR, 'logs/mayorana.error.log'),
      out_file: path.join(APP_DIR, 'logs/mayorana.out.log'),
      log_file: path.join(APP_DIR, 'logs/mayorana.log'),
      time: true,
      max_memory_restart: "500M"
    }
  ]
};

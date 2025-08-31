# NextJS Deployment System

Linux-standard deployment system for NextJS applications using `/opt` directory structure.

## Overview

Deploys and manages:
- **landing** - NextJS landing page (api0.ai)  
- **mayorana** - NextJS application (mayorana.ch)

## Requirements

- Linux system (Ubuntu/Debian preferred)
- Root access for initial setup
- Dependencies: `git`, `node`, `yarn`, `pm2`

## Quick Start

```bash
# One-time setup (creates user + directories + deploys)
sudo make install

# Or just deploy if already set up
make deploy
```

## Architecture

```
/opt/api0/                    # Main deployment directory
├── landing/                  # NextJS landing page
├── mayorana/                 # NextJS application  
├── logs/                     # All service logs
├── config/                   # Global configurations
├── backups/                  # Configuration backups
└── ecosystem.config.js       # PM2 configuration
```

## Commands

| Command | Description |
|---------|-------------|
| `make install` | Full setup: user + dirs + deploy |
| `make deploy` | Clone/pull + build + restart services |
| `make setup-user` | Create api0 service user |
| `make setup-dirs` | Create /opt/api0 structure |
| `make status` | Show PM2 service status |
| `make logs SERVICE=name` | View service logs |
| `make restart SERVICE=name` | Restart specific service |
| `make stop` | Stop all services |
| `make clean` | Clean build artifacts |

## How It Works

The `make deploy` command:
1. **Updates Code**: Git clone (if new) or pull (if exists)
2. **Builds**: yarn install + yarn build for both NextJS apps  
3. **Configures**: Sets up YAML configs and PM2 ecosystem
4. **Restarts**: PM2 reload for zero-downtime updates

## Configuration

Each service gets a `config.yaml`:
```yaml
service:
  name: service-name  
  version: 1.0.0
```

## Monitoring

```bash
# Service status
make status

# Live logs
make logs                    # All services
make logs SERVICE=landing    # Specific service
make logs SERVICE=mayorana   # Mayorana logs

# PM2 monitoring dashboard
sudo -u api0 pm2 monit
```

## Security

- Services run as dedicated `api0` user (not root)
- Files owned by `api0:api0` with proper permissions
- Logs centralized in `/opt/api0/logs/`

## Production Usage

```bash
# Deploy latest version
make deploy

# Check everything is running
make status

# View recent logs
make logs | tail -50
```

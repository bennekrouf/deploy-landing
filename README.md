# Deployment System

A streamlined deployment system for NextJS applications: landing page and mayorana website.

## 🚀 Overview

This deployment system manages:

- **landing** - NextJS landing page (apisensei.ai)
- **mayorana** - NextJS application (mayorana.ch)
- **landing-solanize** - NextJS landing page (solanize project)

## 📋 Requirements

- Debian-based Linux system
- Node.js 18+ and Yarn
- PM2 process manager (`npm install -g pm2`)
- Git

## 🔧 Setup

```bash
# Clone and setup
make setup

# Build applications
make build

# Deploy
make deploy
```

## ⚙️ Configuration

Each project uses `config.yaml` in its directory:
- `landing/config.yaml`
- `mayorana/config.yaml`
- `landing-solanize/config.yaml`

## 🛠️ Commands

| Command | Description |
|---------|-------------|
| `make setup` | Clone repositories and setup |
| `make build` | Build NextJS applications |
| `make deploy` | Deploy with PM2 |
| `make status` | Show PM2 status |
| `make logs SERVICE=name` | View service logs |
| `make restart SERVICE=name` | Restart service |
| `make stop SERVICE=name` | Stop service |
| `make clean` | Clean build artifacts |

## 📁 Structure

```
deploy/
├── scripts/
│   ├── setup.sh
│   ├── build.sh
│   └── deploy.sh
├── landing/          # NextJS landing page
├── mayorana/         # NextJS application
├── landing-solanize/ # NextJS solanize landing
├── ecosystem.config.js
├── Makefile
└── README.md
```

## 📊 Monitoring

```bash
# Real-time monitoring
make monitor

# Check logs
make logs SERVICE=landing
make logs SERVICE=mayorana
make logs SERVICE=landing-solanize
```

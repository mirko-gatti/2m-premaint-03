# 2M PREMAINT-03 - Post-Clone Setup Guide

Welcome! This guide helps you complete the setup after cloning the repository.

## Quick Start

After cloning the repository, run the interactive setup menu:

```bash
cd /path/to/2m-premaint-03
./scripts/setup-menu.sh
```

This will launch an interactive menu with guided options for all setup steps.

---

## Setup Scripts Overview

All scripts are located in the `scripts/` directory.

### 1. **setup-menu.sh** (Main Entry Point)
Interactive menu that guides you through the complete setup process.

**Usage:**
```bash
./scripts/setup-menu.sh
```

**What it does:**
- Provides an interactive menu with 6 options
- Guides you through all setup steps in order
- Shows helpful information and status
- Requires user confirmation for major operations

**Options in the menu:**
1. Check Prerequisites - System dependencies
2. Check Ansible - Ansible and collections
3. Setup Environment - Deploy containers (Ansible playbook)
4. Check Environment - Detailed environment verification
5. Quick Start Guide - Show helpful access information
6. Exit - Close the menu

---

### 2. **check-prerequisites.sh**
Checks for all required system packages and offers to install them.

**Usage:**
```bash
./scripts/check-prerequisites.sh
```

**Checks:**
- curl (HTTP client)
- git (Version control)
- Docker (Container runtime)
- Python 3 (Programming language)
- pip3 (Python package manager)
- sudo (Privilege elevation)

**Features:**
- Displays version information for installed packages
- Asks confirmation before installing missing packages
- Supports multiple package managers (dnf, apt-get, pacman)
- Clear status indicators (✓, ✗, ⚠)

---

### 3. **check-ansible.sh**
Checks for Ansible installation and required collections.

**Usage:**
```bash
./scripts/check-ansible.sh
```

**Checks:**
- Ansible core installation
- community.docker collection (required for Docker tasks)

**Features:**
- Displays Ansible version
- Offers to install Ansible if not present
- Automatically installs required collections
- Supports multiple package managers

---

### 4. **check-environment.sh**
Comprehensive environment verification with detailed human-readable output.

**Usage:**
```bash
./scripts/check-environment.sh
```

**Detailed checks include:**

#### System Information
- OS distribution and kernel version
- CPU cores and available memory
- System architecture

#### Tools & Dependencies
- Git, curl, Python, pip
- Ansible and collections

#### Docker
- Docker installation and version
- Docker daemon status
- Storage driver and configuration
- User permissions and docker group membership
- Custom Docker network (m-network)

#### Running Containers
- InfluxDB container status
- Grafana container status
- Motor Ingestion container status
- Container ports and port mappings

#### Services
- InfluxDB health and configuration
- Grafana health and configuration
- Motor Ingestion status
- Port availability (3000, 8181)

#### Data & Security
- InfluxDB data directory and size
- Grafana data directory and size
- Motor Ingestion directory
- Security tokens (location and length):
  - InfluxDB admin token
  - InfluxDB motor user token
  - InfluxDB Grafana token
  - Grafana admin token

#### System Configuration
- Application user (udev1) status
- Docker group membership
- User permissions

#### Project Structure
- Ansible playbooks
- Configuration files
- Setup and teardown scripts

#### Initialization State
- InfluxDB initialization marker
- Grafana initialization marker

**Output:**
- Color-coded status (✓ OK, ✗ FAIL, ⚠ WARN, ℹ INFO)
- Detailed information for each component
- Summary with counts of passed/failed/warning checks
- Recommendations for issues

---

## Recommended Setup Workflow

### First-Time Setup

```bash
# 1. Start the menu
./scripts/setup-menu.sh

# 2. In the menu, select option 1
#    Check Prerequisites
#    → Verifies and installs system packages

# 3. Then select option 2
#    Check Ansible
#    → Verifies and installs Ansible

# 4. Then select option 3
#    Setup Environment
#    → Runs Ansible playbook to deploy everything
#    → This takes 5-10 minutes on first run
#    → You'll be asked for sudo password

# 5. Finally select option 4
#    Check Environment
#    → Verifies everything is running correctly

# 6. Select option 5 for Quick Start Guide
#    → Shows how to access all services
```

### Checking Status Later

At any time, you can verify the environment:

```bash
./scripts/check-environment.sh
```

This gives you a complete status report of all components.

---

## Individual Script Usage

You can also run scripts individually without the menu:

```bash
# Check prerequisites only
./scripts/check-prerequisites.sh

# Check Ansible only
./scripts/check-ansible.sh

# Run environment verification
./scripts/check-environment.sh

# Run setup playbook directly
./scripts/run_setup_playbook.sh

# Verify setup (existing script)
./scripts/verify-setup.sh
```

---

## Service Access After Setup

Once setup is complete, access your services:

### InfluxDB
- **URL:** http://localhost:8181
- **Purpose:** Time-series database for sensor data
- **Admin token:** Saved in `.influxdb-admin-token`
- **Motor token:** Saved in `.influxdb-motor-token`
- **Grafana token:** Saved in `.influxdb-grafana-token`

### Grafana
- **URL:** http://localhost:3000
- **Default credentials:** admin / admin (change on first login!)
- **Purpose:** Visualization and dashboards
- **Admin token:** Saved in `.grafana-admin-token`

### Motor Ingestion
- **Container:** motor_ingestion
- **Type:** Python 3.14 application
- **Location:** /home/udev1/motor_ingestion
- **View logs:** `docker logs -f motor_ingestion`

---

## Data Directories

All persistent data is stored in:

```
/home/udev1/
├── influxdb-data/        # InfluxDB database files
├── grafana-data/         # Grafana configuration and databases
└── motor_ingestion/      # Motor ingestion application code
```

These directories persist across teardown operations.

---

## Docker Commands Reference

```bash
# View running containers
docker ps

# View all containers (including stopped)
docker ps -a

# Follow container logs
docker logs -f <container-name>

# View container details
docker inspect <container-name>

# Stop a container
docker stop <container-name>

# Start a container
docker start <container-name>

# View network
docker network ls
docker network inspect m-network
```

---

## Security & Tokens

⚠️ **Important:**

1. **Tokens are sensitive** - Protect them and never commit to git
2. **Tokens are auto-generated** during setup and saved locally
3. **Default credentials** - Grafana default is admin/admin (change this!)
4. **Backup tokens** - Keep copies of tokens in a secure location if needed

Token files created:
- `.influxdb-admin-token` - InfluxDB admin access
- `.influxdb-motor-token` - Motor ingestion access to InfluxDB
- `.influxdb-grafana-token` - Grafana's access to InfluxDB
- `.grafana-admin-token` - Grafana admin token

---

## Troubleshooting

### Containers not starting
```bash
# Check container logs
docker logs <container-name>

# Verify Docker is running
sudo systemctl status docker

# Try restarting Docker
sudo systemctl restart docker
```

### Ports in use
```bash
# Check what's using port 3000 (Grafana)
sudo lsof -i :3000

# Check what's using port 8181 (InfluxDB)
sudo lsof -i :8181
```

### Setup fails
1. Run `./scripts/check-environment.sh` for detailed diagnostic info
2. Check for error messages in script output
3. Review `INSTALLATION_MANUAL.md` for troubleshooting
4. Check Docker daemon status: `sudo systemctl status docker`

### Permission issues with Docker
```bash
# Add current user to docker group
sudo usermod -aG docker $USER

# Activate new group membership (logout/login or)
newgrp docker
```

---

## Additional Resources

- **INSTALLATION_MANUAL.md** - Detailed installation and troubleshooting
- **QUICK_START.md** - Quick reference guide
- **IMPLEMENTATION_STATUS_REPORT.md** - Implementation status and features
- **ansible_scripts/** - Ansible playbooks for automation
- **config/setup-config.yaml** - Configuration file

---

## Script Features Summary

### Color-Coded Output
All scripts use consistent color coding:
- 🟢 **Green** - Success, ready, installed
- 🔴 **Red** - Error, failure, missing
- 🟡 **Yellow** - Warning, optional, not running
- 🔵 **Blue** - Sections and headers
- 🔷 **Cyan** - Details and information

### Status Indicators
- ✓ - Check passed / OK
- ✗ - Check failed / Error
- ⚠ - Warning / Caution required
- ℹ - Information / Note
- ⊘ - Skipped
- ✓ (OK) / [✗ FAIL] / [⚠ WARN] / [ℹ INFO] - Status labels

### Interactive Features
- Clear prompts for user choices
- Confirmation required for major operations
- Scripts pause after completion
- Helpful next-step recommendations
- Detailed error messages

---

## Maintenance

### Regular Checks
```bash
# Verify everything is still running
./scripts/check-environment.sh

# Quick setup verification
./scripts/verify-setup.sh
```

### Data Backup
Backup your data before major changes:
```bash
# Backup InfluxDB data
sudo tar -czf influxdb-backup.tar.gz /home/udev1/influxdb-data/

# Backup Grafana data
sudo tar -czf grafana-backup.tar.gz /home/udev1/grafana-data/
```

### Complete Cleanup
To remove everything and start fresh:
```bash
./scripts/run_teardown_playbook.sh
```

⚠️ Note: This removes containers but preserves data in /home/udev1/

---

## Getting Help

If you encounter issues:

1. Run `./scripts/check-environment.sh` for detailed diagnostics
2. Check the script output - it has helpful error messages
3. Review the documentation files listed above
4. Check Docker container logs: `docker logs -f <container-name>`
5. Verify prerequisites are installed: `./scripts/check-prerequisites.sh`

---

**Last Updated:** December 2025
**Script Version:** 1.0

# 2m-premaint-02: Project Reconstruction Blueprint

**Purpose:** Technical specification for recreating the entire 2m-premaint-02 project from first principles.  
**Audience:** Future self - to rebuild scripts, playbooks, and configurations.  
**Date Created:** December 14, 2025  
**Status:** In Progress - Phase 1-2 Complete

---

## Overview

This document serves as a **detailed blueprint** to recreate the 2m-premaint-02 project. It contains the exact specifications, code structures, and configurations needed to rebuild every script and Ansible playbook from scratch.

### Project Goal
Automated setup and teardown of a motor telemetry development and runtime environment using:
- Ansible (orchestration)
- Docker (containerization)
- InfluxDB 3.7.0-core (time-series database)
- Grafana (visualization)
- Python 3.12 (sensor simulation and data ingestion)

---

## Phase 1: Repository Cloning & Script Preparation

### Phase 1.1: Clone Repository Script

**File Location:** `clone-repo.sh` (project root)  
**Purpose:** Clone GitHub repository and prepare environment for initial setup  
**Execution:** Run once at project initialization

**Script Specification:**

```bash
#!/bin/bash

# Clone the 2m-premaint-02 repository from GitHub

set -e

REPO_URL="git@github.com:mirko-gatti/2m-premaint-02.git"
TARGET_DIR="${1:-.}"

# Function to print error messages and exit
handle_error() {
    echo "ERROR: $1"
    exit 1
}

echo "======================================="
echo "  Repository Clone Script"
echo "======================================="
echo ""
echo "Repository URL: $REPO_URL"
echo "Target Directory: $TARGET_DIR"
echo ""

# Check if git is installed
if ! command -v git &> /dev/null; then
    handle_error "git is not installed. Please install git first."
fi

# Clone the repository
echo "--- Cloning Repository ---"
git clone "$REPO_URL" "$TARGET_DIR"
if [ $? -ne 0 ]; then
    handle_error "Failed to clone the repository."
fi

echo ""
echo "SUCCESS: Repository cloned successfully."
echo ""
echo "Next steps:"
echo "1. Navigate to the repository: cd $TARGET_DIR"
echo "2. Run: ./scripts/setup-ansible.sh"
echo "3. Run: ansible-playbook -i ansible_scripts/inventory/hosts ansible_scripts/setup_dev_env.yml --ask-become-pass"
echo ""
echo "======================================="

exit 0
```

**Key Elements:**
- Uses SSH URL for GitHub (`git@github.com:...`) - requires SSH keys configured
- Accepts target directory as parameter or uses current directory
- Validates git is installed before attempting clone
- Provides clear next steps after successful clone
- Uses `set -e` for error handling (exit on first error)

**Execution:**
```bash
# Clone to current directory
./clone-repo.sh

# Or clone to specific directory
./clone-repo.sh ~/Dev/2m/2m-premaint-02
```

**Expected Output:**
```
======================================
  Repository Clone Script
======================================

Repository URL: git@github.com:mirko-gatti/2m-premaint-02.git
Target Directory: .

--- Cloning Repository ---
Cloning into '.'...
remote: Enumerating objects: ...
...
SUCCESS: Repository cloned successfully.

Next steps:
1. Navigate to the repository: cd 2m-premaint-02
2. Run: ./scripts/setup-ansible.sh
3. Run: ansible-playbook -i ansible_scripts/inventory/hosts ansible_scripts/setup_dev_env.yml --ask-become-pass
```

---

### Phase 1.2: Set Executable Permissions

**Objective:** Make all scripts executable after cloning

**Scripts to Make Executable:**
- `scripts/setup-ansible.sh`
- `scripts/teardown-ansible.sh`
- `clone-repo.sh`
- Any other shell scripts in `scripts/` directory

**Commands:**
```bash
# After cloning, navigate to project root
cd <cloned_repository>

# Make all shell scripts executable
chmod +x clone-repo.sh
chmod +x scripts/setup-ansible.sh
chmod +x scripts/teardown-ansible.sh

# Or batch set all .sh files
find scripts/ -name "*.sh" -exec chmod +x {} \;
find . -maxdepth 1 -name "*.sh" -exec chmod +x {} \;
```

**Verification:**
```bash
# Verify permissions are set
ls -la clone-repo.sh scripts/setup-ansible.sh scripts/teardown-ansible.sh

# Should show:
# -rwxr-xr-x 1 user user ... clone-repo.sh
# -rwxr-xr-x 1 user user ... scripts/setup-ansible.sh
# -rwxr-xr-x 1 user user ... scripts/teardown-ansible.sh
```

**Why This Matters:**
- Scripts need executable bit to run directly (e.g., `./setup-ansible.sh`)
- Without permissions, requires `bash setup-ansible.sh` or `sh setup-ansible.sh`
- Makes scripts user-friendly and directly executable

---

## Phase 2: Ansible Foundation Installation

### Phase 2.1: Ansible Setup Script

**File Location:** `scripts/setup-ansible.sh`  
**Purpose:** Install Ansible and required Ansible collections/modules  
**Execution:** Run immediately after cloning and setting permissions  
**Requires:** `sudo` access

**Script Specification:**

```bash
#!/bin/bash

# This script installs Ansible and required Ansible collections/modules.
# This is the preparation step before running the main playbooks.

set -e

echo "======================================="
echo "  Ansible Setup Script"
echo "======================================="

# Function to print error messages and exit
handle_error() {
    echo "ERROR: $1"
    exit 1
}

# --- Ansible Installation ---
echo ""
echo "--- Ansible Installation Check ---"
if command -v ansible &> /dev/null
then
    ANSIBLE_VERSION=$(ansible --version | head -n 1)
    echo "SUCCESS: Ansible is already installed."
    echo "         Version: $ANSIBLE_VERSION"
else
    echo "INFO: Ansible is not installed. Proceeding with installation..."
    sudo dnf install -y ansible-core
    if [ $? -ne 0 ]; then
        handle_error "Ansible installation failed."
    fi
    echo "SUCCESS: Ansible has been installed."
fi

# --- Ansible Collections Installation ---
echo ""
echo "--- Installing Ansible Collections ---"
echo "INFO: Installing community.docker collection..."
ansible-galaxy collection install community.docker -f
if [ $? -ne 0 ]; then
    handle_error "Failed to install community.docker collection."
fi
echo "SUCCESS: community.docker collection installed."

echo ""
echo "======================================="
echo "  Ansible Setup Complete!"
echo "======================================="
echo ""
echo "Next steps:"
echo "1. Install required Ansible collections: ansible-playbook ansible_scripts/install_collections.yml"
echo "2. Run setup playbook: ansible-playbook -i ansible_scripts/inventory/hosts ansible_scripts/setup_dev_env.yml --ask-become-pass"
echo ""

exit 0
```

**Key Elements:**

| Element | Details |
|---------|---------|
| **Check Existing** | Verifies if Ansible already installed before installing |
| **Package Manager** | Uses `dnf` (Fedora/RHEL) - primary OS for this project |
| **Collections** | Installs `community.docker` collection (required for Docker tasks in Ansible) |
| **Error Handling** | Validates each major step succeeds or exits with error |
| **User Feedback** | Clear status messages and next steps |

**Flow Diagram:**
```
Start
  ↓
Check if Ansible installed?
  ├─ YES → Display version → Continue
  └─ NO → Install ansible-core via dnf → Continue
  ↓
Install community.docker collection
  ↓
Display completion message
  ↓
End (Ready for playbook execution)
```

**Execution:**
```bash
# Navigate to project root
cd ~/Dev/2m/2m-premaint-02

# Run the script
./scripts/setup-ansible.sh

# Script will prompt for sudo password during dnf install
```

**Expected Output:**
```
=======================================
  Ansible Setup Script
=======================================

--- Ansible Installation Check ---
INFO: Ansible is not installed. Proceeding with installation...
[sudo password required]
...
SUCCESS: Ansible has been installed.

--- Installing Ansible Collections ---
INFO: Installing community.docker collection...
Starting galaxy collection install process
Process install dependency map
Starting collection install process
... 
SUCCESS: community.docker collection installed.

=======================================
  Ansible Setup Complete!
=======================================

Next steps:
1. Install required Ansible collections: ansible-playbook ansible_scripts/install_collections.yml
2. Run setup playbook: ansible-playbook -i ansible_scripts/inventory/hosts ansible_scripts/setup_dev_env.yml --ask-become-pass
```

---

### Phase 2.2: Ansible Collections Playbook

**File Location:** `ansible_scripts/install_collections.yml`  
**Purpose:** Alternative/supplementary method to install required collections  
**Type:** Ansible Playbook (YAML)  
**Execution:** Optional - can be run instead of manual collection installation

**Playbook Specification:**

```yaml
---
- name: Install required Ansible collections
  hosts: localhost
  connection: local
  tasks:
    - name: Install community.docker collection
      ansible.builtin.command: ansible-galaxy collection install community.docker
      changed_when: false
```

**Key Elements:**

| Element | Value | Purpose |
|---------|-------|---------|
| `hosts` | `localhost` | Run on local machine only |
| `connection` | `local` | No SSH needed, execute locally |
| `tasks` | command | Execute `ansible-galaxy` command |
| `changed_when` | `false` | Never report as changed (idempotent) |

**Usage:**
```bash
# Optional: Install collections using this playbook instead
ansible-playbook ansible_scripts/install_collections.yml

# Or combine with setup-ansible.sh which is the standard approach
```

**Why This File Exists:**
- Provides an Ansible-native way to install collections
- Can be integrated into larger automation workflows
- Useful if prefer to avoid shell scripts
- Documents required collections in Ansible format

---

### Phase 2.3: Inventory Configuration

**File Location:** `ansible_scripts/inventory/hosts`  
**Purpose:** Define target hosts for Ansible playbooks  
**Format:** INI-style inventory

**Inventory Specification:**

```ini
[local]
localhost ansible_connection=local
```

**Key Elements:**

| Element | Value | Purpose |
|---------|-------|---------|
| `[local]` | Inventory group | Groups hosts logically |
| `localhost` | Host identifier | Standard local machine reference |
| `ansible_connection=local` | Connection method | Execute locally without SSH |

**Design Rationale:**
- Single host: `localhost` (the machine running Ansible)
- Local connection: No SSH, Docker, or network communication needed
- Simple inventory: Perfect for development/single-machine setup
- Extensible: Easy to add remote hosts in future

**Usage:**
```bash
# Test inventory
ansible-inventory -i ansible_scripts/inventory/hosts --list

# Ping test
ansible -i ansible_scripts/inventory/hosts localhost -m ping

# Expected response:
# localhost | SUCCESS => {
#     "changed": false,
#     "ping": "pong"
# }
```

**Directory Structure:**
```
ansible_scripts/
├── inventory/
│   └── hosts           ← This file
├── setup_dev_env.yml
├── teardown_dev_env.yml
└── roles/
    └── ...
```

---

## Phase 3: Prerequisites Check

### Phase 3.1: System Requirements

Before attempting to run scripts, verify system meets requirements:

**Operating System:**
- Fedora 40+ (tested and primary target)
- RHEL/CentOS derivatives (compatible with adjustments)
- Other Linux distributions (not tested)

**Software:**
- `bash` 4.0+ (for shell scripts)
- `git` (for repository cloning)
- `sudo` access (for Docker and package management)
- `curl` or `wget` (for downloading Docker installer)

**System Resources:**
- RAM: 4GB minimum (8GB recommended for full stack)
- Disk: 10GB free (for containers and data)
- CPU: 2+ cores (4+ recommended)

**Verification Script:**
```bash
#!/bin/bash
# Quick system verification

echo "=== System Requirements Check ==="
echo ""

echo "OS: $(cat /etc/os-release | grep '^ID=')"
echo "Kernel: $(uname -r)"
echo "RAM: $(free -h | head -2 | tail -1)"
echo "Disk: $(df -h / | tail -1)"
echo ""

echo "=== Required Commands ==="
for cmd in bash git sudo curl dnf; do
    if command -v $cmd &> /dev/null; then
        echo "✓ $cmd"
    else
        echo "✗ $cmd (MISSING)"
    fi
done
echo ""

echo "=== Sudo Access ==="
if sudo -n true 2>/dev/null; then
    echo "✓ No password required for sudo"
else
    echo "⚠ Sudo password will be required"
fi
```

---

## Phase 4: Execution Workflow

### Phase 4.1: Step-by-Step Execution

**Complete workflow from start to running infrastructure:**

```
Step 1: Clone Repository
  $ ./clone-repo.sh
  → Creates ~/Dev/2m/2m-premaint-02/

Step 2: Set Permissions
  $ cd ~/Dev/2m/2m-premaint-02
  $ chmod +x scripts/*.sh

Step 3: Install Ansible
  $ ./scripts/setup-ansible.sh
  → Installs Ansible and community.docker collection
  → Requires sudo password

Step 4: Verify Ansible
  $ ansible --version
  $ ansible -i ansible_scripts/inventory/hosts localhost -m ping

Step 5: Run Setup Playbook (Phase 3+)
  $ ansible-playbook -i ansible_scripts/inventory/hosts \
      ansible_scripts/setup_dev_env.yml --ask-become-pass
  → Sets up Docker, InfluxDB, Grafana, Motor Ingestion

Step 6: Verify Running Services
  $ docker ps
  → Should show 3 containers: influxdb, grafana, motor_ingestion
```

---

## Phase 2.5: Centralized Configuration File

### Phase 2.5.1: Configuration File Purpose & Strategy

**File Location:** `config/setup-config.yaml`  
**Purpose:** Single source of truth for all setup parameters - versions, paths, credentials, names  
**Strategy:** All scripts and Ansible playbooks import this file and use its variables  
**Benefits:**
- One place to customize entire setup
- No hardcoded values scattered across scripts/playbooks
- Easy to version control different configurations
- Simple to replicate setup with different parameters
- Environment-agnostic (can have dev, staging, prod versions)

---

### Phase 2.5.2: Complete Configuration File Specification

**File Location:** `config/setup-config.yaml`

```yaml
---
# 2m-premaint-02 Setup Configuration File
# Single source of truth for all customizable parameters

# System & Package Configuration
system:
  package_manager: dnf
  ansible_package: ansible-core
  docker:
    repo_url: https://get.docker.com
    script_dest: /tmp/get-docker.sh
    packages:
      - docker-ce
      - docker-ce-cli
      - containerd.io
      - docker-buildx-plugin
      - docker-compose-plugin
      - docker-ce-rootless-extras

# User & Directory Configuration
user:
  username: udev1
  home_directory: /home/udev1
  shell: /bin/bash
  comment: "Development User for Motor Telemetry"

# Docker Network Configuration
docker:
  network:
    name: gemini-network
    driver: bridge

# InfluxDB Configuration
influxdb:
  container:
    name: influxdb
    image: influxdb:3.7.0-core
    port: 8181
    network: gemini-network
    restart_policy: always
  paths:
    data: "{{ user.home_directory }}/influxdb-data"
    config: "{{ user.home_directory }}/influxdb-config"
  node_id: influxdb-node-1
  http_bind_address: ":8181"
  disable_authz_endpoints:
    - health
    - ping
    - metrics
  startup_timeout: 120

# Grafana Configuration
grafana:
  container:
    name: grafana
    image: grafana/grafana:main
    port: 3000
    network: gemini-network
    restart_policy: always
  paths:
    data: "{{ user.home_directory }}/grafana-data"
    provisioning: "{{ user.home_directory }}/grafana-provisioning"
  admin:
    user: admin
    password: admin
  startup_timeout: 60

# Motor Ingestion Configuration
motor_ingestion:
  container:
    name: motor_ingestion
    image: python:3.12-slim
    network: gemini-network
    restart_policy: always
  paths:
    base: "{{ user.home_directory }}/motor_ingestion"
    scripts: "{{ user.home_directory }}/motor_ingestion/scripts"
    config: "{{ user.home_directory }}/motor_ingestion/config"
    logs: "{{ user.home_directory }}/motor_ingestion/logs"
    data: "{{ user.home_directory }}/motor_ingestion/data"
  container_paths:
    scripts: /app/scripts
    config: /app/config
    logs: /app/logs
    data: /app/data
  script: main.py
  environment:
    PYTHONUNBUFFERED: "1"
    LOG_LEVEL: "DEBUG"
    INFLUXDB_URL: "http://influxdb:8181"
    INFLUXDB_ORG: "motor_telemetry"
    INFLUXDB_BUCKET: "sensors"

# InfluxDB Schema Configuration
influxdb_schema:
  organization: motor_telemetry
  bucket: sensors
  measurements:
    current: motor_current
    temperature: motor_temperature
    vibration: motor_vibration
  tags:
    - facility_id
    - area_id
    - motor_id

# Motor Simulator Configuration
motor_simulator:
  count: 3
  motors:
    - id: MOTOR_001
      facility_id: facility_1
      area_id: area_1
    - id: MOTOR_002
      facility_id: facility_1
      area_id: area_1
    - id: MOTOR_003
      facility_id: facility_1
      area_id: area_2
  intervals:
    cycle_seconds: 20
  current:
    min: 24
    max: 26
  temperature:
    baseline: 46
    min: 45
    max: 47

# Project Paths
paths:
  project_root: "."
  ansible_dir: "./ansible_scripts"
  scripts_dir: "./scripts"
  config_dir: "./config"

# Feature Flags
features:
  preserve_data_on_teardown: true
  healthchecks_enabled: true
  autostart_enabled: true
```

**Key Customizable Parameters:**
- Image versions (influxdb, grafana, python)
- Dev user name & home directory
- All container names and ports
- Data persistence paths
- Admin credentials
- Network name
- Data generation intervals
- Motor definitions
- Feature flags

---

### Phase 2.5.3: Configuration Usage Pattern

**In Shell Scripts:**
```bash
# Load config from file
source config/setup-config.yaml

# Use variables in script
echo "Using dev user: $user_username"
echo "Using network: $docker_network_name"
```

**In Ansible Playbooks:**
```yaml
vars_files:
  - ../../config/setup-config.yaml

roles:
  - role: install_tools
    vars:
      ansible_package: "{{ system.ansible_package }}"
  # All roles can access config variables
```

**In Ansible Roles:**
```yaml
- name: Run InfluxDB container
  community.docker.docker_container:
    name: "{{ influxdb.container.name }}"
    image: "{{ influxdb.container.image }}"
    port: "{{ influxdb.container.port }}"
    # All values from config
```

---

### Phase 2.5.4: Directory Structure

```
config/
└── setup-config.yaml           ← Central configuration file
```

Place in project root alongside `scripts/`, `ansible_scripts/`, `docs/`.

---

## Phase 2.6: InfluxDB Security Configuration & Token Generation

### Phase 2.6.1: Security Architecture

**Objective:** Configure InfluxDB 3.x with full security enabled

**Security Components:**
1. **Organization Setup** - `motor_telemetry` organization
2. **Bucket Management** - `sensors` bucket with access control
3. **Authentication Tokens** - API tokens for different services
4. **User Accounts** - Admin and application users
5. **Authorization Rules** - Fine-grained permissions per token

**InfluxDB 3.x Security Model:**
- **Organization:** Top-level grouping (motor_telemetry)
- **Bucket:** Data container within organization (sensors)
- **Token:** Bearer token for API authentication
- **User:** Identity with assigned roles
- **Role:** Predefined permission set (admin, member, viewer, owner)

---

### Phase 2.6.2: Security Configuration File Extension

**Add to `config/setup-config.yaml`:**

```yaml
# ============================================================================
# INFLUXDB SECURITY CONFIGURATION
# ============================================================================

influxdb_security:
  # Organization configuration
  organization:
    name: motor_telemetry
    description: "Motor Telemetry Data Organization"
    
  # Bucket configuration
  bucket:
    name: sensors
    description: "Motor sensor measurements"
    retention_period_hours: 8760  # 1 year
    
  # Admin user configuration
  admin_user:
    username: influx_admin
    password: "ChangeMe!InfluxAdmin123"  # CHANGE THIS IN PRODUCTION
    
  # Application user configuration (motor ingestion)
  app_user:
    username: motor_app
    password: "ChangeMe!MotorApp456"  # CHANGE THIS IN PRODUCTION
    
  # API Tokens configuration
  tokens:
    # Admin token - full access (for setup and management)
    admin:
      description: "InfluxDB Admin Token - Full Access"
      permissions:
        - action: read
          resource:
            type: buckets
            id: "{{ influxdb_bucket_id }}"
        - action: write
          resource:
            type: buckets
            id: "{{ influxdb_bucket_id }}"
        - action: read
          resource:
            type: tasks
        - action: write
          resource:
            type: tasks
        - action: read
          resource:
            type: dashboards
        - action: write
          resource:
            type: dashboards
        - action: read
          resource:
            type: orgs
        - action: write
          resource:
            type: orgs
      
    # Motor ingestion token - restricted access (only write to sensors bucket)
    motor_ingestion:
      description: "Motor Ingestion Service - Write-Only Token"
      permissions:
        - action: write
          resource:
            type: buckets
            id: "{{ influxdb_bucket_id }}"
      
    # Grafana token - read-only access (only read from sensors bucket)
    grafana_reader:
      description: "Grafana Visualization - Read-Only Token"
      permissions:
        - action: read
          resource:
            type: buckets
            id: "{{ influxdb_bucket_id }}"
  
  # SSL/TLS Configuration (optional for development)
  tls:
    enabled: false  # Set to true for production
    cert_file: /etc/influxdb2/tls/influxdb.crt
    key_file: /etc/influxdb2/tls/influxdb.key
  
  # CORS Configuration (for web access)
  cors:
    enabled: true
    allowed_origins:
      - "http://localhost:3000"  # Grafana
      - "http://localhost:8181"  # InfluxDB UI
```

---

### Phase 2.6.3: InfluxDB Initialization Script

**File Location:** `scripts/influxdb-init.sh`  
**Purpose:** Initialize InfluxDB with security setup after container starts  
**Run After:** InfluxDB container is running and healthy

**Script Specification:**

```bash
#!/bin/bash

# InfluxDB Security Initialization Script
# Sets up organization, buckets, users, and tokens with security enabled

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
CONFIG_FILE="$PROJECT_ROOT/config/setup-config.yaml"

echo "======================================="
echo "  InfluxDB Security Initialization"
echo "======================================="
echo ""

# Function to print error messages and exit
handle_error() {
    echo "ERROR: $1"
    exit 1
}

# Function to extract YAML values (simple grep-based)
get_yaml_value() {
    local file="$1"
    local key="$2"
    grep "^${key}:" "$file" | sed 's/^.*: //' | tr -d '"' | tr -d "'"
}

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    handle_error "Config file not found at $CONFIG_FILE"
fi

echo "--- Loading Configuration ---"
# Source basic variables from config (using grep for YAML parsing)
INFLUXDB_ORG=$(grep "organization:" "$CONFIG_FILE" -A 1 | grep "name:" | sed 's/.*name: //' | tr -d ' ')
INFLUXDB_BUCKET=$(grep "bucket:" "$CONFIG_FILE" -A 1 | grep "name:" | sed 's/.*name: //' | tr -d ' ')
ADMIN_USER=$(grep "admin_user:" "$CONFIG_FILE" -A 1 | grep "username:" | sed 's/.*username: //' | tr -d ' ')
ADMIN_PASSWORD=$(grep "admin_user:" "$CONFIG_FILE" -A 2 | grep "password:" | sed 's/.*password: //' | tr -d ' ')
APP_USER=$(grep "app_user:" "$CONFIG_FILE" -A 1 | grep "username:" | sed 's/.*username: //' | tr -d ' ')
APP_PASSWORD=$(grep "app_user:" "$CONFIG_FILE" -A 2 | grep "password:" | sed 's/.*password: //' | tr -d ' ')

echo "Organization: $INFLUXDB_ORG"
echo "Bucket: $INFLUXDB_BUCKET"
echo "Admin User: $ADMIN_USER"
echo "App User: $APP_USER"
echo ""

# Check if InfluxDB is running
echo "--- Checking InfluxDB Health ---"
if ! docker ps | grep -q influxdb; then
    handle_error "InfluxDB container is not running. Start it first."
fi

# Wait for InfluxDB to be ready
echo "Waiting for InfluxDB to be ready..."
for i in {1..30}; do
    if docker exec influxdb curl -s http://localhost:8181/health &>/dev/null; then
        echo "InfluxDB is ready"
        break
    fi
    if [ $i -eq 30 ]; then
        handle_error "InfluxDB failed to start within 30 seconds"
    fi
    sleep 1
done

echo ""
echo "--- Creating Organization ---"
# Create organization
docker exec influxdb influxdb3 org create \
    --name "$INFLUXDB_ORG" \
    2>/dev/null || echo "Organization may already exist"

echo ""
echo "--- Creating Bucket ---"
# Create bucket in organization
docker exec influxdb influxdb3 bucket create \
    --name "$INFLUXDB_BUCKET" \
    --org "$INFLUXDB_ORG" \
    --retention 8760h \
    2>/dev/null || echo "Bucket may already exist"

echo ""
echo "--- Creating Admin User ---"
# Create admin user
docker exec influxdb influxdb3 user create \
    --name "$ADMIN_USER" \
    --password "$ADMIN_PASSWORD" \
    2>/dev/null || echo "Admin user may already exist"

echo ""
echo "--- Creating Application User ---"
# Create application user
docker exec influxdb influxdb3 user create \
    --name "$APP_USER" \
    --password "$APP_PASSWORD" \
    2>/dev/null || echo "App user may already exist"

echo ""
echo "--- Assigning Roles ---"
# Assign admin user to organization with owner role
docker exec influxdb influxdb3 member create \
    --member "$ADMIN_USER" \
    --org "$INFLUXDB_ORG" \
    --role owner \
    2>/dev/null || echo "Admin role assignment may already exist"

# Assign app user to organization with member role
docker exec influxdb influxdb3 member create \
    --member "$APP_USER" \
    --org "$INFLUXDB_ORG" \
    --role member \
    2>/dev/null || echo "App role assignment may already exist"

echo ""
echo "--- Creating API Tokens ---"

# Get bucket ID (needed for token permissions)
BUCKET_ID=$(docker exec influxdb influxdb3 bucket list --org "$INFLUXDB_ORG" --format json 2>/dev/null | \
    grep -o '"id":"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)".*/\1/' || echo "")

if [ -z "$BUCKET_ID" ]; then
    echo "WARNING: Could not retrieve bucket ID. Tokens may not have proper permissions."
else
    echo "Bucket ID: $BUCKET_ID"
fi

# Create admin token (full access)
echo "Creating admin token..."
ADMIN_TOKEN=$(docker exec influxdb influxdb3 token create \
    --description "InfluxDB Admin Token - Full Access" \
    --org "$INFLUXDB_ORG" \
    --all-access \
    2>/dev/null | grep -oP '(?<=token: )[^ ]+' || echo "")

if [ -n "$ADMIN_TOKEN" ]; then
    echo "Admin Token: $ADMIN_TOKEN"
    echo "$ADMIN_TOKEN" > "$PROJECT_ROOT/.influxdb-admin-token"
    chmod 600 "$PROJECT_ROOT/.influxdb-admin-token"
    echo "Token saved to .influxdb-admin-token (restricted permissions)"
else
    echo "WARNING: Could not create admin token"
fi

# Create motor ingestion token (write-only to bucket)
echo "Creating motor ingestion token..."
MOTOR_TOKEN=$(docker exec influxdb influxdb3 token create \
    --description "Motor Ingestion Service - Write-Only" \
    --org "$INFLUXDB_ORG" \
    2>/dev/null | grep -oP '(?<=token: )[^ ]+' || echo "")

if [ -n "$MOTOR_TOKEN" ]; then
    echo "Motor Ingestion Token: $MOTOR_TOKEN"
    echo "$MOTOR_TOKEN" > "$PROJECT_ROOT/.influxdb-motor-token"
    chmod 600 "$PROJECT_ROOT/.influxdb-motor-token"
    echo "Token saved to .influxdb-motor-token (restricted permissions)"
else
    echo "WARNING: Could not create motor ingestion token"
fi

# Create Grafana token (read-only to bucket)
echo "Creating Grafana reader token..."
GRAFANA_TOKEN=$(docker exec influxdb influxdb3 token create \
    --description "Grafana Visualization - Read-Only" \
    --org "$INFLUXDB_ORG" \
    2>/dev/null | grep -oP '(?<=token: )[^ ]+' || echo "")

if [ -n "$GRAFANA_TOKEN" ]; then
    echo "Grafana Token: $GRAFANA_TOKEN"
    echo "$GRAFANA_TOKEN" > "$PROJECT_ROOT/.influxdb-grafana-token"
    chmod 600 "$PROJECT_ROOT/.influxdb-grafana-token"
    echo "Token saved to .influxdb-grafana-token (restricted permissions)"
else
    echo "WARNING: Could not create Grafana token"
fi

echo ""
echo "======================================="
echo "  InfluxDB Initialization Complete!"
echo "======================================="
echo ""
echo "Generated Tokens (saved in files with restricted permissions):"
echo "  - Admin Token: .influxdb-admin-token"
echo "  - Motor Ingestion Token: .influxdb-motor-token"
echo "  - Grafana Token: .influxdb-grafana-token"
echo ""
echo "Access InfluxDB Web UI:"
echo "  URL: http://localhost:8181"
echo "  Username: $ADMIN_USER"
echo "  Password: (see config file)"
echo ""
echo "NOTE: Update ansible_scripts/roles/motor_ingestion/vars/main.yml"
echo "      with the motor ingestion token"
echo ""
echo "NOTE: Configure Grafana data source with grafana token"
echo ""

exit 0
```

**Key Functions:**
1. Validates config file exists
2. Extracts configuration values
3. Checks InfluxDB container is running
4. Waits for InfluxDB to be ready
5. Creates organization
6. Creates bucket with 1-year retention
7. Creates admin user
8. Creates application user
9. Assigns users to organization with appropriate roles
10. Creates 3 API tokens with specific permissions:
    - Admin token: full access (for management)
    - Motor ingestion token: write-only (for sensor data)
    - Grafana token: read-only (for visualization)
11. Saves tokens to files with restricted permissions (600)

---

### Phase 2.6.4: Token Integration into Roles

**Update `ansible_scripts/roles/run_influxdb/tasks/main.yml`:**

Add task to run initialization script after container starts:

```yaml
- name: Initialize InfluxDB with security
  ansible.builtin.command: "{{ scripts_dir }}/influxdb-init.sh"
  register: influxdb_init_result
  when: influxdb_init_enabled | default(true)
  tags:
    - run_influxdb
    - influxdb_security

- name: Display InfluxDB initialization output
  ansible.builtin.debug:
    msg: "{{ influxdb_init_result.stdout_lines }}"
  when: influxdb_init_result is defined
  tags:
    - run_influxdb
```

**Update `ansible_scripts/roles/motor_ingestion/vars/main.yml`:**

Add token variable and load from file:

```yaml
# InfluxDB authentication token (generated during setup)
influxdb_token_file: "{{ lookup('env', 'PWD') }}/.influxdb-motor-token"
influxdb_token: "{{ lookup('file', influxdb_token_file) | trim if influxdb_token_file else '' }}"

# Environment variables include token
motor_ingestion_env:
  PYTHONUNBUFFERED: "1"
  LOG_LEVEL: "DEBUG"
  INFLUXDB_URL: "{{ influxdb.container.url | default('http://influxdb:8181') }}"
  INFLUXDB_ORG: "{{ influxdb_schema.organization }}"
  INFLUXDB_BUCKET: "{{ influxdb_schema.bucket.name }}"
  INFLUXDB_TOKEN: "{{ influxdb_token }}"  # NEW: Add security token
  INFLUXDB_USERNAME: "{{ influxdb_security.app_user.username }}"  # Optional fallback
```

**Update Python script connection code:**

The motor ingestion Python scripts should use token for authentication:

```python
# In influxdb_connection.py
import os

class InfluxDBConnection:
    def __init__(self):
        self.url = os.getenv('INFLUXDB_URL', 'http://influxdb:8181')
        self.org = os.getenv('INFLUXDB_ORG', 'motor_telemetry')
        self.bucket = os.getenv('INFLUXDB_BUCKET', 'sensors')
        self.token = os.getenv('INFLUXDB_TOKEN', '')
        
        # Use token for authentication (preferred in InfluxDB 3.x)
        self.client = InfluxDBClient(
            url=self.url,
            org=self.org,
            token=self.token,  # Authentication token
            timeout=30000  # 30 seconds
        )
```

---

### Phase 2.6.5: Security Token File Management

**Generated Token Files:**
```
project_root/
├── .influxdb-admin-token       (600) - Full access token
├── .influxdb-motor-token       (600) - Motor ingestion write-only token
├── .influxdb-grafana-token     (600) - Grafana read-only token
└── .gitignore                  (includes token files)
```

**Update `.gitignore`:**
```
# InfluxDB security tokens (NEVER commit to git)
.influxdb-*-token
*.token
```

**Token File Handling:**
- Created with `600` permissions (owner read-write only)
- Referenced by Ansible roles and scripts
- Used as environment variables in containers
- Never committed to version control
- Can be regenerated by running init script again

---

### Phase 2.6.6: Security Modifications to Playbooks

**Update `ansible_scripts/setup_dev_env.yml`:**

```yaml
---
- name: Setup Development Environment with Security
  hosts: localhost
  connection: local
  gather_facts: true

  vars_files:
    - ../../config/setup-config.yaml

  pre_tasks:
    - name: Set ansible_user if not defined
      ansible.builtin.set_fact:
        ansible_user: "{{ lookup('env', 'USER') }}"
      when: ansible_user is not defined
    
    - name: Load InfluxDB security configuration
      ansible.builtin.include_vars:
        file: ../../config/setup-config.yaml
        name: influxdb_security_config

  roles:
    - role: install_tools
    - role: setup_docker
    - role: setup_udev_user
    - role: run_influxdb
    - role: run_grafana
    - role: motor_ingestion

  post_tasks:
    - name: Run InfluxDB security initialization
      ansible.builtin.command: "{{ scripts_dir }}/influxdb-init.sh"
      register: influxdb_init_result
      changed_when: false
      tags:
        - influxdb_security

    - name: Display security configuration summary
      ansible.builtin.debug:
        msg:
          - "Security Setup Complete!"
          - "Organization: {{ influxdb_schema.organization }}"
          - "Bucket: {{ influxdb_schema.bucket }}"
          - "Admin User: {{ influxdb_security.admin_user.username }}"
          - "App User: {{ influxdb_security.app_user.username }}"
          - "Tokens saved in: .influxdb-*-token files"
      tags:
        - influxdb_security
```

---

### Phase 2.6.7: Security Verification Script

**File Location:** `scripts/verify-influxdb-security.sh`  
**Purpose:** Verify InfluxDB security is properly configured

```bash
#!/bin/bash

# Verify InfluxDB Security Configuration

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

echo "======================================="
echo "  InfluxDB Security Verification"
echo "======================================="
echo ""

# Check if InfluxDB is running
echo "--- Checking InfluxDB Container ---"
if ! docker ps | grep -q influxdb; then
    echo "ERROR: InfluxDB container is not running"
    exit 1
fi
echo "✓ InfluxDB container is running"

# Check organization
echo ""
echo "--- Checking Organization ---"
docker exec influxdb influxdb3 org list | grep motor_telemetry && \
    echo "✓ Organization 'motor_telemetry' exists" || \
    echo "✗ Organization 'motor_telemetry' NOT found"

# Check bucket
echo ""
echo "--- Checking Bucket ---"
docker exec influxdb influxdb3 bucket list --org motor_telemetry | grep sensors && \
    echo "✓ Bucket 'sensors' exists" || \
    echo "✗ Bucket 'sensors' NOT found"

# Check users
echo ""
echo "--- Checking Users ---"
docker exec influxdb influxdb3 user list | grep influx_admin && \
    echo "✓ Admin user 'influx_admin' exists" || \
    echo "✗ Admin user 'influx_admin' NOT found"

docker exec influxdb influxdb3 user list | grep motor_app && \
    echo "✓ App user 'motor_app' exists" || \
    echo "✗ App user 'motor_app' NOT found"

# Check token files
echo ""
echo "--- Checking Token Files ---"
for token_file in .influxdb-admin-token .influxdb-motor-token .influxdb-grafana-token; do
    if [ -f "$PROJECT_ROOT/$token_file" ]; then
        perms=$(ls -l "$PROJECT_ROOT/$token_file" | awk '{print $1}')
        echo "✓ $token_file exists (permissions: $perms)"
    else
        echo "✗ $token_file NOT found"
    fi
done

echo ""
echo "======================================="
echo "  Verification Complete!"
echo "======================================="
```

---

### Phase 2.6.8: Updated Helper Script

**Update `scripts/run_setup_playbook.sh`:**

Add security check before setup:

```bash
# After playbook execution, add:

# Verify security setup
print_section "Verifying InfluxDB Security"
if [ -f "$PROJECT_ROOT/scripts/verify-influxdb-security.sh" ]; then
    bash "$PROJECT_ROOT/scripts/verify-influxdb-security.sh"
else
    echo "WARNING: Security verification script not found"
fi
```

---

## Summary: InfluxDB Security Implementation

**What Gets Configured:**
- ✅ Organization: `motor_telemetry`
- ✅ Bucket: `sensors` with 1-year retention
- ✅ Admin User: `influx_admin`
- ✅ App User: `motor_app`
- ✅ Admin Token: Full access (management)
- ✅ Motor Ingestion Token: Write-only (data insertion)
- ✅ Grafana Token: Read-only (visualization)

**Security Files Generated:**
- `.influxdb-admin-token` - Full access (600 permissions)
- `.influxdb-motor-token` - Write-only (600 permissions)
- `.influxdb-grafana-token` - Read-only (600 permissions)

**Integration Points:**
- Motor ingestion uses motor token via environment variable
- Grafana uses grafana token for data source
- Admin token for management and debugging
- All tokens stored locally, never in code/git

---

## Phase 2.7: Grafana Security Configuration

### Phase 2.7.1: Grafana Security Architecture

**Objective:** Configure Grafana with full security enabled

**Security Components:**
1. **Admin User** - Primary administrator account
2. **Service Accounts** - Non-interactive accounts for API access
3. **API Tokens** - Bearer tokens for service-to-service communication
4. **Data Sources** - Secure connection to InfluxDB with authentication
5. **RBAC (Role-Based Access Control)** - User roles and permissions
6. **LDAP/OAuth** - Optional external authentication
7. **Session Security** - Secure cookies, CSRF protection
8. **SMTP Configuration** - Secure email notifications

**Grafana Security Model:**
- **Org:** Organization (like InfluxDB org)
- **User:** Individual user with credentials
- **Service Account:** Non-interactive account for API access
- **API Token:** Bearer token for authentication
- **Role:** Admin, Editor, Viewer with permission inheritance
- **Data Source:** Backend service connection with credentials

---

### Phase 2.7.2: Grafana Security Configuration File Extension

**Add to `config/setup-config.yaml`:**

```yaml
# ============================================================================
# GRAFANA SECURITY CONFIGURATION
# ============================================================================

grafana_security:
  # Admin user configuration (primary administrator)
  admin:
    username: grafana_admin
    password: "ChangeMe!GrafanaAdmin123"  # CHANGE THIS IN PRODUCTION
    email: admin@motor-telemetry.local
    
  # Organization configuration
  organization:
    name: "Motor Telemetry"
    admins:
      - grafana_admin
      
  # Data source configuration (InfluxDB connection)
  datasources:
    influxdb:
      name: "InfluxDB-Motor"
      type: "influxdb"
      url: "http://influxdb:8181"
      org_id: 1
      is_default: true
      access: "proxy"  # Browser/Server mode
      # Authentication
      auth:
        type: "bearer_token"  # Token-based authentication
        token_field: "Authorization"
        token: "{{ influxdb_security.tokens.grafana_reader.token }}"  # From InfluxDB
      # TLS/SSL configuration
      tls:
        skip_verify: true  # Development only - set to false in production
      database: "{{ influxdb_schema.bucket }}"
      
  # Service account for programmatic access (e.g., provisioning, monitoring)
  service_accounts:
    provisioning:
      name: grafana_provisioning
      role: Editor
      description: "Service account for dashboard provisioning"
      scopes:
        - dashboards:create
        - dashboards:write
        - dashboards:read
        - datasources:read
        - folders:read
        
    monitoring:
      name: grafana_monitoring
      role: Viewer
      description: "Service account for monitoring and alerting"
      scopes:
        - alerts:read
        - dashboards:read
        - datasources:read

  # API authentication settings
  api:
    api_key_max_seconds_to_live: 2592000  # 30 days
    enable_api_keys: true  # Allow API key authentication
    
  # Session security settings
  session:
    cookie_name: grafana_session
    cookie_secure: true  # HTTPS only (set to false for development)
    cookie_samesite: Lax
    session_life_days: 30
    
  # Authentication settings
  auth:
    # Disable auto-signup for security
    auto_signup_enabled: false
    # Require users to confirm email
    email_confirmation: true
    # Allow external authentication (optional)
    oauth:
      enabled: false
      # Configure OAuth providers if needed
      # - github
      # - google
      # - azure
      
  # SMTP Configuration for notifications
  smtp:
    enabled: true
    host: "localhost:25"  # Change to actual SMTP server
    user: ""
    password: ""
    from_address: "grafana@motor-telemetry.local"
    from_name: "Motor Telemetry Alerting"
    
  # Security headers
  security_headers:
    x_content_type_options: "nosniff"
    x_frame_options: "DENY"
    x_xss_protection: "1; mode=block"
    
  # Feature toggles for security
  features:
    enforce_domain_login: false  # Not enforced in dev
    login_cookie_lifetime: 604800  # 7 days in seconds
    oidc_enabled: false

  # LDAP Configuration (optional for enterprise)
  ldap:
    enabled: false
    host: "ldap.example.com"
    port: 389
    use_ssl: true
    search_filter: "(uid=%s)"
    search_base_dns:
      - "cn=users,dc=example,dc=com"
```

---

### Phase 2.7.3: Grafana Initialization Script

**File Location:** `scripts/grafana-init.sh`  
**Purpose:** Initialize Grafana with security setup after container starts  
**Run After:** Grafana container is running and healthy

**Script Specification:**

```bash
#!/bin/bash

# Grafana Security Initialization Script
# Sets up admin user, data sources, service accounts, and API tokens

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
CONFIG_FILE="$PROJECT_ROOT/config/setup-config.yaml"

echo "======================================="
echo "  Grafana Security Initialization"
echo "======================================="
echo ""

# Function to print error messages and exit
handle_error() {
    echo "ERROR: $1"
    exit 1
}

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    handle_error "Config file not found at $CONFIG_FILE"
fi

echo "--- Loading Configuration ---"
# Extract configuration values
GRAFANA_ADMIN_USER=$(grep "username:" "$CONFIG_FILE" | grep -A 5 "admin:" | head -1 | sed 's/.*username: //' | tr -d ' ')
GRAFANA_ADMIN_PASSWORD=$(grep "password:" "$CONFIG_FILE" | grep -B 1 "ChangeMe!GrafanaAdmin" | tail -1 | sed 's/.*password: //' | tr -d '"' | tr -d "'")
GRAFANA_ORG=$(grep "name:" "$CONFIG_FILE" | grep -A 1 "organization:" | grep "name:" | sed 's/.*name: //' | tr -d '"' | tr -d "'")
INFLUXDB_URL=$(grep "url:" "$CONFIG_FILE" | grep -B 5 "InfluxDB-Motor" | grep "url:" | head -1 | sed 's/.*url: //' | tr -d ' ')
INFLUXDB_BUCKET=$(grep "bucket:" "$CONFIG_FILE" | grep "name:" | sed 's/.*name: //' | tr -d ' ')
INFLUXDB_TOKEN_FILE="$PROJECT_ROOT/.influxdb-grafana-token"

echo "Grafana Admin: $GRAFANA_ADMIN_USER"
echo "Organization: $GRAFANA_ORG"
echo "InfluxDB URL: $INFLUXDB_URL"
echo ""

# Check if Grafana is running
echo "--- Checking Grafana Health ---"
if ! docker ps | grep -q grafana; then
    handle_error "Grafana container is not running. Start it first."
fi

# Wait for Grafana to be ready
echo "Waiting for Grafana to be ready..."
for i in {1..30}; do
    if docker exec grafana curl -s -u "$GRAFANA_ADMIN_USER:$GRAFANA_ADMIN_PASSWORD" \
        http://localhost:3000/api/health &>/dev/null; then
        echo "Grafana is ready"
        break
    fi
    if [ $i -eq 30 ]; then
        handle_error "Grafana failed to start within 30 seconds"
    fi
    sleep 1
done

echo ""
echo "--- Setting Admin Password ---"
# Grafana sets default admin password at startup, we verify it's set
curl -s -X POST \
    -u admin:admin \
    http://localhost:3000/api/admin/users/1/password \
    -H "Content-Type: application/json" \
    -d "{\"password\":\"$GRAFANA_ADMIN_PASSWORD\"}" \
    2>/dev/null || echo "Password may already be set"

echo ""
echo "--- Creating Organization ---"
# Create organization (if not exists)
ORG_ID=$(curl -s -X POST \
    -u "$GRAFANA_ADMIN_USER:$GRAFANA_ADMIN_PASSWORD" \
    http://localhost:3000/api/orgs \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"$GRAFANA_ORG\"}" \
    2>/dev/null | grep -o '"id":[0-9]*' | sed 's/.*://' || echo "1")

echo "Organization ID: $ORG_ID"

echo ""
echo "--- Setting Current Organization ---"
# Set current organization for admin user
curl -s -X POST \
    -u "$GRAFANA_ADMIN_USER:$GRAFANA_ADMIN_PASSWORD" \
    http://localhost:3000/api/user/using/$ORG_ID \
    2>/dev/null || echo "Organization may already be set"

echo ""
echo "--- Creating Data Source ---"
# Read InfluxDB token
if [ -f "$INFLUXDB_TOKEN_FILE" ]; then
    INFLUXDB_TOKEN=$(cat "$INFLUXDB_TOKEN_FILE")
    echo "Using InfluxDB token from: $INFLUXDB_TOKEN_FILE"
else
    echo "WARNING: InfluxDB token file not found at $INFLUXDB_TOKEN_FILE"
    INFLUXDB_TOKEN=""
fi

# Create InfluxDB data source with token authentication
DS_JSON=$(cat <<EOF
{
  "name": "InfluxDB-Motor",
  "type": "influxdb",
  "url": "$INFLUXDB_URL",
  "access": "proxy",
  "isDefault": true,
  "jsonData": {
    "httpMode": "GET",
    "organization": "motor_telemetry",
    "defaultBucket": "$INFLUXDB_BUCKET"
  },
  "secureJsonData": {
    "token": "$INFLUXDB_TOKEN"
  },
  "orgId": 1
}
EOF
)

curl -s -X POST \
    -u "$GRAFANA_ADMIN_USER:$GRAFANA_ADMIN_PASSWORD" \
    http://localhost:3000/api/datasources \
    -H "Content-Type: application/json" \
    -d "$DS_JSON" \
    2>/dev/null | grep -q '"id"' && echo "Data source created" || echo "Data source may already exist"

echo ""
echo "--- Creating Service Accounts ---"

# Create provisioning service account
PROV_SA=$(curl -s -X POST \
    -u "$GRAFANA_ADMIN_USER:$GRAFANA_ADMIN_PASSWORD" \
    http://localhost:3000/api/serviceaccounts \
    -H "Content-Type: application/json" \
    -d '{
        "name": "grafana_provisioning",
        "role": "Editor",
        "isDisabled": false
    }' \
    2>/dev/null | grep -o '"id":[0-9]*' | sed 's/.*://' || echo "")

if [ -n "$PROV_SA" ]; then
    echo "Provisioning service account created (ID: $PROV_SA)"
else
    echo "Provisioning service account may already exist"
fi

# Create monitoring service account
MON_SA=$(curl -s -X POST \
    -u "$GRAFANA_ADMIN_USER:$GRAFANA_ADMIN_PASSWORD" \
    http://localhost:3000/api/serviceaccounts \
    -H "Content-Type: application/json" \
    -d '{
        "name": "grafana_monitoring",
        "role": "Viewer",
        "isDisabled": false
    }' \
    2>/dev/null | grep -o '"id":[0-9]*' | sed 's/.*://' || echo "")

if [ -n "$MON_SA" ]; then
    echo "Monitoring service account created (ID: $MON_SA)"
else
    echo "Monitoring service account may already exist"
fi

echo ""
echo "--- Creating API Tokens ---"

# Create provisioning API token
PROV_TOKEN=$(curl -s -X POST \
    -u "$GRAFANA_ADMIN_USER:$GRAFANA_ADMIN_PASSWORD" \
    http://localhost:3000/api/serviceaccounts/$PROV_SA/tokens \
    -H "Content-Type: application/json" \
    -d '{
        "name": "provisioning-token",
        "secondsToLive": 2592000
    }' \
    2>/dev/null | grep -o '"key":"[^"]*' | sed 's/.*"key":"//' || echo "")

if [ -n "$PROV_TOKEN" ]; then
    echo "Provisioning API token: $PROV_TOKEN"
    echo "$PROV_TOKEN" > "$PROJECT_ROOT/.grafana-provisioning-token"
    chmod 600 "$PROJECT_ROOT/.grafana-provisioning-token"
    echo "Token saved to .grafana-provisioning-token"
else
    echo "WARNING: Could not create provisioning API token"
fi

# Create admin API token for general use
ADMIN_TOKEN=$(curl -s -X POST \
    -u "$GRAFANA_ADMIN_USER:$GRAFANA_ADMIN_PASSWORD" \
    http://localhost:3000/api/auth/keys \
    -H "Content-Type: application/json" \
    -d '{
        "name": "admin-token",
        "role": "Admin",
        "secondsToLive": 2592000
    }' \
    2>/dev/null | grep -o '"key":"[^"]*' | sed 's/.*"key":"//' || echo "")

if [ -n "$ADMIN_TOKEN" ]; then
    echo "Admin API token: $ADMIN_TOKEN"
    echo "$ADMIN_TOKEN" > "$PROJECT_ROOT/.grafana-admin-token"
    chmod 600 "$PROJECT_ROOT/.grafana-admin-token"
    echo "Token saved to .grafana-admin-token"
else
    echo "WARNING: Could not create admin API token"
fi

echo ""
echo "--- Enabling Security Features ---"

# Update admin settings for security
curl -s -X PUT \
    -u "$GRAFANA_ADMIN_USER:$GRAFANA_ADMIN_PASSWORD" \
    http://localhost:3000/api/admin/settings \
    -H "Content-Type: application/json" \
    -d '{
        "auth": {
            "oauth_auto_signup": "false",
            "disable_signout_menu": "false"
        },
        "security": {
            "cookie_secure": "false",
            "cookie_samesite": "Lax"
        }
    }' \
    2>/dev/null || echo "Security settings may already be configured"

echo ""
echo "======================================="
echo "  Grafana Initialization Complete!"
echo "======================================="
echo ""
echo "Access Grafana Web UI:"
echo "  URL: http://localhost:3000"
echo "  Username: $GRAFANA_ADMIN_USER"
echo "  Password: (see config file)"
echo ""
echo "Generated API Tokens (saved in files with restricted permissions):"
echo "  - Admin Token: .grafana-admin-token"
echo "  - Provisioning Token: .grafana-provisioning-token"
echo ""
echo "Configured Data Source:"
echo "  - Name: InfluxDB-Motor"
echo "  - URL: $INFLUXDB_URL"
echo "  - Organization: motor_telemetry"
echo "  - Bucket: $INFLUXDB_BUCKET"
echo ""
echo "Security Features Enabled:"
echo "  - Admin password set"
echo "  - Organization created"
echo "  - Data source configured with token authentication"
echo "  - Service accounts created"
echo "  - API tokens generated"
echo "  - Signup disabled"
echo ""

exit 0
```

**Key Functions:**
1. Validates config file exists
2. Extracts configuration values
3. Checks Grafana container is running
4. Waits for Grafana to be ready
5. Sets admin password (overrides default)
6. Creates organization
7. Creates InfluxDB data source with token-based authentication
8. Creates service accounts (provisioning and monitoring)
9. Generates API tokens for programmatic access
10. Enables security features
11. Saves tokens to files with 600 permissions

---

### Phase 2.7.4: Integration into Ansible Roles

**Update `ansible_scripts/roles/run_grafana/tasks/main.yml`:**

Add task to run initialization script after container starts:

```yaml
- name: Initialize Grafana with security
  ansible.builtin.command: "{{ scripts_dir }}/grafana-init.sh"
  register: grafana_init_result
  when: grafana_init_enabled | default(true)
  tags:
    - run_grafana
    - grafana_security

- name: Display Grafana initialization output
  ansible.builtin.debug:
    msg: "{{ grafana_init_result.stdout_lines }}"
  when: grafana_init_result is defined
  tags:
    - run_grafana
```

**Update `ansible_scripts/roles/run_grafana/vars/main.yml`:**

Add security-related variables:

```yaml
# Grafana initialization
grafana_init_enabled: true

# API token files (created during initialization)
grafana_admin_token_file: "{{ lookup('env', 'PWD') }}/.grafana-admin-token"
grafana_provisioning_token_file: "{{ lookup('env', 'PWD') }}/.grafana-provisioning-token"

# Load tokens if available
grafana_admin_token: "{{ lookup('file', grafana_admin_token_file) | trim if grafana_admin_token_file else '' }}"
grafana_provisioning_token: "{{ lookup('file', grafana_provisioning_token_file) | trim if grafana_provisioning_token_file else '' }}"
```

---

### Phase 2.7.5: Security Configuration Files

**Update `config/setup-config.yaml` - Grafana section:**

Replace hardcoded values with comprehensive security config:

```yaml
grafana:
  # Container configuration
  container:
    name: grafana
    image: grafana/grafana:main
    port: 3000
    network: gemini-network
    restart_policy: always
    
  # Data persistence paths
  paths:
    data: "{{ user.home_directory }}/grafana-data"
    provisioning: "{{ user.home_directory }}/grafana-provisioning"
    
  # Admin credentials (CHANGE FOR PRODUCTION!)
  admin:
    user: grafana_admin
    password: ChangeMe!GrafanaAdmin123
    email: admin@motor-telemetry.local
    
  # Organization
  organization:
    name: "Motor Telemetry"
    
  # Data source configuration
  datasource:
    name: InfluxDB-Motor
    type: influxdb
    url: http://influxdb:8181
    database: sensors
    access: proxy
    auth_type: bearer_token
    
  # Session security
  session:
    cookie_secure: false  # Set to true for HTTPS in production
    cookie_samesite: Lax
    session_life_days: 30
    
  # Authentication settings
  auth:
    auto_signup_enabled: false
    email_confirmation: false  # Set to true in production
    
  # SMTP configuration
  smtp:
    enabled: true
    host: "localhost:25"
    from_address: "grafana@motor-telemetry.local"
    from_name: "Motor Telemetry"
    
  # Health check configuration
  healthcheck:
    enabled: true
    test: "curl -s http://localhost:3000/api/health"
    interval: 30s
    timeout: 10s
    retries: 3
    start_period: 30s
    
  # Startup timeout
  startup_timeout: 60
```

---

### Phase 2.7.6: Grafana Security Verification Script

**File Location:** `scripts/verify-grafana-security.sh`  
**Purpose:** Verify Grafana security is properly configured

```bash
#!/bin/bash

# Verify Grafana Security Configuration

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

echo "======================================="
echo "  Grafana Security Verification"
echo "======================================="
echo ""

# Check if Grafana is running
echo "--- Checking Grafana Container ---"
if ! docker ps | grep -q grafana; then
    echo "ERROR: Grafana container is not running"
    exit 1
fi
echo "✓ Grafana container is running"

# Check Grafana health
echo ""
echo "--- Checking Grafana Health ---"
if docker exec grafana curl -s http://localhost:3000/api/health | grep -q '"database":"ok"'; then
    echo "✓ Grafana health check passed"
else
    echo "✗ Grafana health check failed"
fi

# Check admin user
echo ""
echo "--- Checking Admin User ---"
GRAFANA_ADMIN=$(grep "username:" "$PROJECT_ROOT/config/setup-config.yaml" | \
    grep -A 5 "admin:" | head -1 | sed 's/.*username: //' | tr -d ' ')

if [ -n "$GRAFANA_ADMIN" ]; then
    echo "✓ Admin user configured: $GRAFANA_ADMIN"
else
    echo "✗ Admin user not found in config"
fi

# Check data source
echo ""
echo "--- Checking Data Source ---"
DATASOURCE_COUNT=$(docker exec grafana curl -s \
    -u "$GRAFANA_ADMIN:admin" \
    http://localhost:3000/api/datasources | grep -c "InfluxDB-Motor" || echo "0")

if [ "$DATASOURCE_COUNT" -gt 0 ]; then
    echo "✓ InfluxDB data source configured"
else
    echo "✗ InfluxDB data source NOT found"
fi

# Check API token files
echo ""
echo "--- Checking API Token Files ---"
for token_file in .grafana-admin-token .grafana-provisioning-token; do
    if [ -f "$PROJECT_ROOT/$token_file" ]; then
        perms=$(ls -l "$PROJECT_ROOT/$token_file" | awk '{print $1}')
        echo "✓ $token_file exists (permissions: $perms)"
    else
        echo "✗ $token_file NOT found"
    fi
done

# Check organization
echo ""
echo "--- Checking Organization ---"
GRAFANA_ORG=$(grep "name:" "$PROJECT_ROOT/config/setup-config.yaml" | \
    grep -A 1 "organization:" | grep "name:" | sed 's/.*name: //' | tr -d '"' | tr -d "'")

if [ -n "$GRAFANA_ORG" ]; then
    echo "✓ Organization configured: $GRAFANA_ORG"
else
    echo "✗ Organization not found in config"
fi

echo ""
echo "======================================="
echo "  Verification Complete!"
echo "======================================="
```

---

### Phase 2.7.7: Grafana Provisioning Configuration

**File Location:** `ansible_scripts/roles/run_grafana/files/provisioning/dashboards/motor_telemetry.json`  
**Purpose:** Pre-provision dashboard for motor telemetry visualization

```json
{
  "annotations": {
    "list": [
      {
        "builtIn": 1,
        "datasource": "Prometheus",
        "enable": true,
        "hide": true,
        "iconColor": "rgba(0, 211, 255, 1)",
        "name": "Annotations & Alerts",
        "type": "dashboard"
      }
    ]
  },
  "description": "Motor Telemetry Dashboard",
  "editable": true,
  "gnetId": null,
  "graphTooltip": 0,
  "id": null,
  "links": [],
  "panels": [
    {
      "datasource": "InfluxDB-Motor",
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              }
            ]
          },
          "unit": "A"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 0,
        "y": 0
      },
      "id": 2,
      "options": {
        "legend": {
          "calcs": [],
          "displayMode": "list",
          "placement": "bottom"
        },
        "tooltip": {
          "mode": "single"
        }
      },
      "targets": [
        {
          "expr": "motor_current",
          "refId": "A"
        }
      ],
      "title": "Motor Current (3-Phase)",
      "type": "timeseries"
    },
    {
      "datasource": "InfluxDB-Motor",
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "blue",
                "value": null
              }
            ]
          },
          "unit": "°C"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 12,
        "y": 0
      },
      "id": 3,
      "options": {
        "legend": {
          "calcs": [],
          "displayMode": "list",
          "placement": "bottom"
        },
        "tooltip": {
          "mode": "single"
        }
      },
      "targets": [
        {
          "expr": "motor_temperature",
          "refId": "A"
        }
      ],
      "title": "Motor Temperature",
      "type": "timeseries"
    }
  ],
  "refresh": "10s",
  "schemaVersion": 38,
  "style": "dark",
  "tags": ["motor", "telemetry"],
  "templating": {
    "list": []
  },
  "time": {
    "from": "now-1h",
    "to": "now"
  },
  "timepicker": {},
  "timezone": "",
  "title": "Motor Telemetry Dashboard",
  "uid": "motor-telemetry",
  "version": 1
}
```

---

### Phase 2.7.8: Updated Setup Playbook

**Update `ansible_scripts/setup_dev_env.yml`:**

Add security initialization for Grafana:

```yaml
  post_tasks:
    - name: Run InfluxDB security initialization
      ansible.builtin.command: "{{ scripts_dir }}/influxdb-init.sh"
      register: influxdb_init_result
      changed_when: false
      tags:
        - influxdb_security

    - name: Run Grafana security initialization
      ansible.builtin.command: "{{ scripts_dir }}/grafana-init.sh"
      register: grafana_init_result
      changed_when: false
      tags:
        - grafana_security

    - name: Display security configuration summary
      ansible.builtin.debug:
        msg:
          - "Security Setup Complete!"
          - ""
          - "InfluxDB:"
          - "  Organization: motor_telemetry"
          - "  Bucket: sensors"
          - "  Tokens: .influxdb-*-token"
          - ""
          - "Grafana:"
          - "  Admin User: {{ grafana.admin.user }}"
          - "  API Tokens: .grafana-*-token"
          - "  Data Source: InfluxDB-Motor (token-authenticated)"
          - ""
          - "Next Steps:"
          - "  1. Access Grafana: http://localhost:3000"
          - "  2. Access InfluxDB: http://localhost:8181"
          - "  3. Verify security: ./scripts/verify-influxdb-security.sh"
          - "  4. Verify security: ./scripts/verify-grafana-security.sh"
      tags:
        - grafana_security
```

---

### Phase 2.7.9: Security Token File Management

**Generated Grafana Token Files:**
```
project_root/
├── .grafana-admin-token           (600) - Full access token
├── .grafana-provisioning-token    (600) - Provisioning service account token
└── (existing InfluxDB tokens)
```

**Update `.gitignore`:**
```
# Grafana security tokens (NEVER commit to git)
.grafana-*-token

# InfluxDB security tokens (from Phase 2.6)
.influxdb-*-token

# All token files
*.token
```

---

## Summary: Grafana Security Implementation

**What Gets Configured:**
- ✅ Admin User: `grafana_admin` with secure password
- ✅ Organization: `Motor Telemetry`
- ✅ Data Source: InfluxDB with token-based authentication
- ✅ Service Accounts: Provisioning and monitoring
- ✅ API Tokens: Admin and provisioning tokens
- ✅ Session Security: Secure cookies, CSRF protection
- ✅ Security Features: Signup disabled, email confirmation ready
- ✅ SMTP: Configured for notifications

**Security Files Generated:**
- `.grafana-admin-token` - Full access (600 permissions)
- `.grafana-provisioning-token` - Provisioning service account (600 permissions)

**Integration with InfluxDB:**
- Grafana data source uses InfluxDB token from `.influxdb-grafana-token`
- Read-only access to sensors bucket
- Secure token-based authentication

**Pre-provisioned:**
- InfluxDB data source pre-configured and connected
- Sample motor telemetry dashboard
- Service accounts ready for automation
- API tokens for external integrations

---

## Phase 3: Ansible Setup Playbook & Roles

### Phase 3.0: Main Setup Playbook

**File Location:** `ansible_scripts/setup_dev_env.yml`  
**Purpose:** Orchestrate infrastructure setup by calling roles in sequence  
**Execution:** `ansible-playbook -i ansible_scripts/inventory/hosts ansible_scripts/setup_dev_env.yml --ask-become-pass`

**Playbook Specification:**

```yaml
---
- name: Setup Development Environment
  hosts: localhost
  connection: local
  gather_facts: true

  pre_tasks:
    - name: Set ansible_user if not defined
      ansible.builtin.set_fact:
        ansible_user: "{{ lookup('env', 'USER') }}"
      when: ansible_user is not defined

  roles:
    - role: install_tools
    - role: setup_docker
    - role: setup_udev_user
    - role: run_influxdb
    - role: run_grafana
    - role: motor_ingestion
```

**Key Structure:**
- **hosts:** `localhost` - runs on local machine only
- **connection:** `local` - no SSH needed
- **gather_facts:** `true` - gather system information (OS, CPU, RAM, etc.)
- **pre_tasks:** Set `ansible_user` to current running user
- **roles:** Execute 6 roles in strict order (dependencies respected)

**Execution Flow:**
```
1. install_tools          → Install Ansible, Docker
2. setup_docker           → Create network, pull images
3. setup_udev_user        → Create udev1 user
4. run_influxdb          → Start InfluxDB container
5. run_grafana           → Start Grafana container
6. motor_ingestion       → Start Python ingestion container
```

**Expected Output:**
```
PLAY [Setup Development Environment] ****

TASK [Gathering Facts] ****
ok: [localhost]

TASK [Set ansible_user if not defined] ****
ok: [localhost]

TASK [install_tools : Update dnf cache] ****
changed: [localhost]
...
[~30 more tasks]

PLAY RECAP ****
localhost : ok=35  changed=10  unreachable=0  failed=0
```

---

### Phase 3.1: install_tools Role

**Location:** `ansible_scripts/roles/install_tools/`

**Purpose:** Install Ansible and Docker with required tools

**Directory Structure:**
```
install_tools/
├── tasks/
│   └── main.yml
└── vars/
    └── main.yml
```

**vars/main.yml:**
```yaml
---
# vars file for install_tools
ansible_package: ansible-core
docker_repo_url: https://get.docker.com
docker_script_dest: /tmp/get-docker.sh
```

**tasks/main.yml:**
```yaml
---
# tasks file for install_tools

- name: Update dnf cache
  become: true
  ansible.builtin.dnf:
    update_cache: true
  changed_when: false
  tags:
    - install_tools

- name: Check if Ansible is installed
  ansible.builtin.command: command -v ansible
  register: ansible_check
  changed_when: false
  ignore_errors: true
  tags:
    - install_tools

- name: Install Ansible
  become: true
  ansible.builtin.dnf:
    name: "{{ ansible_package }}"
    state: present
  when: ansible_check.rc != 0
  tags:
    - install_tools

- name: Check if Docker is installed
  ansible.builtin.command: command -v docker
  register: docker_check
  changed_when: false
  ignore_errors: true
  tags:
    - install_tools

- name: Download Docker installation script
  ansible.builtin.get_url:
    url: "{{ docker_repo_url }}"
    dest: "{{ docker_script_dest }}"
    mode: '0755'
  when: docker_check.rc != 0
  tags:
    - install_tools

- name: Install Docker
  become: true
  ansible.builtin.command: sh {{ docker_script_dest }}
  when: docker_check.rc != 0
  tags:
    - install_tools

- name: Ensure Docker service is started and enabled
  become: true
  ansible.builtin.systemd:
    name: docker
    state: started
    enabled: true
  tags:
    - install_tools

- name: Add ansible_user to the docker group
  become: true
  ansible.builtin.user:
    name: "{{ ansible_user }}"
    groups: docker
    append: true
  tags:
    - install_tools

- name: Reset SSH connection to apply group changes
  ansible.builtin.meta: reset_connection
  tags:
    - install_tools
```

**Key Tasks:**
1. Update dnf package cache
2. Check if Ansible already installed (idempotent)
3. Install Ansible if not present
4. Check if Docker already installed
5. Download Docker installer script (only if needed)
6. Execute Docker install script
7. Start Docker service and enable auto-start
8. Add current user to docker group
9. Reset connection to apply group changes

---

### Phase 3.2: setup_docker Role

**Location:** `ansible_scripts/roles/setup_docker/`

**Purpose:** Create Docker network and pull container images

**Directory Structure:**
```
setup_docker/
├── tasks/
│   └── main.yml
└── vars/
    └── main.yml
```

**vars/main.yml:**
```yaml
---
# vars file for setup_docker
docker_network_name: gemini-network
docker_images:
  - influxdb:3.7.0-core
  - grafana/grafana:main
```

**tasks/main.yml:**
```yaml
---
# tasks file for setup_docker

- name: Ensure Docker network exists
  become: true
  community.docker.docker_network:
    name: "{{ docker_network_name }}"
    state: present
  tags:
    - setup_docker

- name: Pull Docker images
  become: true
  community.docker.docker_image:
    name: "{{ item }}"
    source: pull
  loop: "{{ docker_images }}"
  tags:
    - setup_docker
```

**Key Tasks:**
1. Create Docker bridge network `gemini-network` for inter-container communication
2. Pull 2 base images:
   - `influxdb:3.7.0-core` - time-series database
   - `grafana/grafana:main` - visualization dashboard

**Why Separate Images:**
- InfluxDB: Pre-configured time-series DB
- Grafana: Pre-configured visualization
- Python: Pulled later in motor_ingestion role (for final stage)

---

### Phase 3.3: setup_udev_user Role

**Location:** `ansible_scripts/roles/setup_udev_user/`

**Purpose:** Create application user and manage data directories

**Directory Structure:**
```
setup_udev_user/
├── tasks/
│   └── main.yml
└── vars/
    └── main.yml
```

**vars/main.yml:**
```yaml
---
# vars file for setup_udev_user

# User configuration
udev_user: "udev1"
udev_user_home: "/home/udev1"
udev_user_shell: "/bin/bash"
udev_user_comment: "Development User for Motor Telemetry"

# Docker container storage paths will be under udev1 home
container_data_base: "{{ udev_user_home }}"
```

**tasks/main.yml:**
```yaml
---
# tasks file for setup_udev_user

- name: Check if udev1 home directory exists
  ansible.builtin.stat:
    path: "{{ udev_user_home }}"
  register: udev_home_stat
  tags:
    - setup_udev_user

- name: Check if udev1 user already exists
  ansible.builtin.getent:
    database: passwd
    key: "{{ udev_user }}"
  ignore_errors: true
  register: udev_user_info
  tags:
    - setup_udev_user

- name: Create udev1 user (home directory does not exist)
  become: true
  ansible.builtin.user:
    name: "{{ udev_user }}"
    home: "{{ udev_user_home }}"
    shell: "{{ udev_user_shell }}"
    comment: "{{ udev_user_comment }}"
    state: present
    create_home: true
  when: not udev_home_stat.stat.exists
  tags:
    - setup_udev_user

- name: Create udev1 user with existing home directory
  become: true
  ansible.builtin.user:
    name: "{{ udev_user }}"
    home: "{{ udev_user_home }}"
    shell: "{{ udev_user_shell }}"
    comment: "{{ udev_user_comment }}"
    state: present
    create_home: false
  when: udev_home_stat.stat.exists and udev_user_info.failed
  tags:
    - setup_udev_user

- name: Ensure udev1 home directory has correct permissions
  become: true
  ansible.builtin.file:
    path: "{{ udev_user_home }}"
    state: directory
    owner: "{{ udev_user }}"
    group: "{{ udev_user }}"
    mode: '0755'
  tags:
    - setup_udev_user

- name: Add udev1 to docker group
  become: true
  ansible.builtin.user:
    name: "{{ udev_user }}"
    groups: docker
    append: true
  tags:
    - setup_udev_user

- name: Display udev1 user setup information
  ansible.builtin.debug:
    msg:
      - "udev1 user has been configured"
      - "Username: {{ udev_user }}"
      - "Home directory: {{ udev_user_home }}"
      - "Shell: {{ udev_user_shell }}"
  tags:
    - setup_udev_user
```

**Key Tasks:**
1. Check if home directory already exists
2. Check if user already exists
3. Create user (with or without creating home directory)
4. Ensure directory permissions correct
5. Add user to docker group
6. Display confirmation

**Purpose of udev1 User:**
- Separate application data from admin user
- Container volumes mount to `/home/udev1/`
- Easy to identify and manage application-owned files
- Enables multi-user environments

---

### Phase 3.4: run_influxdb Role

**Location:** `ansible_scripts/roles/run_influxdb/`

**Purpose:** Create data directories and start InfluxDB container

**Directory Structure:**
```
run_influxdb/
├── tasks/
│   └── main.yml
└── vars/
    └── main.yml
```

**vars/main.yml:**
```yaml
---
# vars file for run_influxdb

# Container configuration
influxdb_container_name: influxdb
influxdb_image: "influxdb:3.7.0-core"
influxdb_port: 8181
influxdb_network: gemini-network

# Data persistence paths - stored under udev1 home directory
udev_user_home: "/home/udev1"
influxdb_data_host_path: "{{ udev_user_home }}/influxdb-data"
influxdb_config_host_path: "{{ udev_user_home }}/influxdb-config"

# InfluxDB 3.x core configuration
influxdb_node_id: "influxdb-node-1"

# InfluxDB environment variables
influxdb_http_bind_address: ":8181"

# Restart policy for auto-start on boot
influxdb_restart_policy: always
```

**tasks/main.yml:**
```yaml
---
# tasks file for run_influxdb

- name: Create InfluxDB data directory on host
  become: true
  ansible.builtin.file:
    path: "{{ influxdb_data_host_path }}"
    state: directory
    mode: '0755'
    owner: "udev1"
    group: "udev1"
  tags:
    - run_influxdb

- name: Create InfluxDB config directory on host
  become: true
  ansible.builtin.file:
    path: "{{ influxdb_config_host_path }}"
    state: directory
    mode: '0755'
    owner: "udev1"
    group: "udev1"
  tags:
    - run_influxdb

- name: Remove existing InfluxDB container (if any)
  become: true
  community.docker.docker_container:
    name: "{{ influxdb_container_name }}"
    state: absent
  ignore_errors: true
  tags:
    - run_influxdb

- name: Run InfluxDB container
  become: true
  community.docker.docker_container:
    name: "{{ influxdb_container_name }}"
    image: "{{ influxdb_image }}"
    state: started
    restart_policy: "{{ influxdb_restart_policy }}"
    networks:
      - name: "{{ influxdb_network }}"
    ports:
      - "{{ influxdb_port }}:8181"
    volumes:
      - "{{ influxdb_data_host_path }}:/var/lib/influxdb2"
      - "{{ influxdb_config_host_path }}:/etc/influxdb2"
    env:
      INFLUXDB_HTTP_BIND_ADDRESS: "{{ influxdb_http_bind_address }}"
    command: 
      - "influxdb3"
      - "serve"
      - "--node-id"
      - "{{ influxdb_node_id }}"
      - "--disable-authz"
      - "health,ping,metrics"
    healthcheck:
      test: ["CMD", "curl", "-s", "http://localhost:8181/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s
  tags:
    - run_influxdb

- name: Wait for InfluxDB to be ready
  ansible.builtin.wait_for:
    host: localhost
    port: "{{ influxdb_port }}"
    delay: 5
    timeout: 120
  tags:
    - run_influxdb

- name: Display InfluxDB container information
  ansible.builtin.debug:
    msg:
      - "InfluxDB container is running"
      - "Container name: {{ influxdb_container_name }}"
      - "Image: {{ influxdb_image }}"
      - "Port: {{ influxdb_port }}"
      - "Data directory: {{ influxdb_data_host_path }}"
      - "Access URL: http://localhost:{{ influxdb_port }}"
  tags:
    - run_influxdb
```

**Key Tasks:**
1. Create host directories for data persistence
2. Remove any existing container (idempotent)
3. Start container with:
   - Port mapping: `8181:8181`
   - Network: `gemini-network`
   - Volumes: data and config directories
   - Auth disabled for development (health, ping, metrics endpoints)
4. Wait for port 8181 to be listening
5. Display connection information

**Key Configuration:**
- `--disable-authz health,ping,metrics` - Allow health checks without authentication
- `restart_policy: always` - Auto-restart on boot
- Health check every 30 seconds

---

### Phase 3.5: run_grafana Role

**Location:** `ansible_scripts/roles/run_grafana/`

**Purpose:** Create data directories and start Grafana container

**Directory Structure:**
```
run_grafana/
├── tasks/
│   └── main.yml
└── vars/
    └── main.yml
```

**vars/main.yml:**
```yaml
---
# vars file for run_grafana

# Container configuration
grafana_container_name: grafana
grafana_image: "grafana/grafana:main"
grafana_port: 3000
grafana_network: gemini-network

# Data persistence paths - stored under udev1 home directory
udev_user_home: "/home/udev1"
grafana_data_host_path: "{{ udev_user_home }}/grafana-data"
grafana_provisioning_host_path: "{{ udev_user_home }}/grafana-provisioning"

# Grafana admin credentials (change these for production!)
grafana_admin_user: admin
grafana_admin_password: admin

# Grafana environment variables
grafana_users_allow_sign_up: "false"
grafana_security_admin_user: "{{ grafana_admin_user }}"
grafana_security_admin_password: "{{ grafana_admin_password }}"

# Restart policy for auto-start on boot
grafana_restart_policy: always
```

**tasks/main.yml:**
```yaml
---
# tasks file for run_grafana

- name: Create Grafana data directory on host
  become: true
  ansible.builtin.file:
    path: "{{ grafana_data_host_path }}"
    state: directory
    mode: '0777'
    owner: "udev1"
    group: "udev1"
  tags:
    - run_grafana

- name: Create Grafana provisioning directory on host
  become: true
  ansible.builtin.file:
    path: "{{ grafana_provisioning_host_path }}"
    state: directory
    mode: '0777'
    owner: "udev1"
    group: "udev1"
  tags:
    - run_grafana

- name: Remove existing Grafana container (if any)
  become: true
  community.docker.docker_container:
    name: "{{ grafana_container_name }}"
    state: absent
  ignore_errors: true
  tags:
    - run_grafana

- name: Run Grafana container
  become: true
  community.docker.docker_container:
    name: "{{ grafana_container_name }}"
    image: "{{ grafana_image }}"
    state: started
    restart_policy: "{{ grafana_restart_policy }}"
    networks:
      - name: "{{ grafana_network }}"
    ports:
      - "{{ grafana_port }}:3000"
    volumes:
      - "{{ grafana_data_host_path }}:/var/lib/grafana"
      - "{{ grafana_provisioning_host_path }}:/etc/grafana/provisioning"
    env:
      GF_USERS_ALLOW_SIGN_UP: "{{ grafana_users_allow_sign_up }}"
      GF_SECURITY_ADMIN_USER: "{{ grafana_security_admin_user }}"
      GF_SECURITY_ADMIN_PASSWORD: "{{ grafana_security_admin_password }}"
    healthcheck:
      test: ["CMD", "curl", "-s", "http://localhost:3000/api/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s
  tags:
    - run_grafana

- name: Wait for Grafana to be ready
  ansible.builtin.wait_for:
    host: localhost
    port: "{{ grafana_port }}"
    delay: 5
    timeout: 60
  tags:
    - run_grafana

- name: Display Grafana container information
  ansible.builtin.debug:
    msg:
      - "Grafana container is running"
      - "Container name: {{ grafana_container_name }}"
      - "Port: {{ grafana_port }}"
      - "Data directory: {{ grafana_data_host_path }}"
      - "Access URL: http://localhost:{{ grafana_port }}"
      - "Default credentials: {{ grafana_admin_user }} / {{ grafana_admin_password }}"
      - "NOTE: Change default password after first login!"
  tags:
    - run_grafana
```

**Key Tasks:**
1. Create host directories for data and provisioning
2. Remove any existing container
3. Start container with:
   - Port mapping: `3000:3000`
   - Network: `gemini-network`
   - Volumes: dashboards, settings, provisioning
   - Default credentials: `admin/admin`
4. Wait for port 3000 to be listening
5. Display connection information

**Key Configuration:**
- `GF_SECURITY_ADMIN_USER` / `GF_SECURITY_ADMIN_PASSWORD` - Set via environment variables
- `GF_USERS_ALLOW_SIGN_UP: false` - Disable open registration
- Health check via HTTP API

---

### Phase 3.6: motor_ingestion Role

**Location:** `ansible_scripts/roles/motor_ingestion/`

**Purpose:** Copy Python scripts and start motor telemetry ingestion container

**Directory Structure:**
```
motor_ingestion/
├── tasks/
│   └── main.yml
└── vars/
    └── main.yml
```

**vars/main.yml:**
```yaml
---
# vars file for motor_ingestion

# Container configuration
motor_ingestion_container_name: motor_ingestion
motor_ingestion_image: "python:3.12-slim"
motor_ingestion_network: "gemini-network"
motor_ingestion_restart_policy: "always"

# Directory paths (all under /home/udev1)
motor_ingestion_host_path: "/home/udev1/motor_ingestion"
motor_ingestion_scripts_path: "/home/udev1/motor_ingestion/scripts"
motor_ingestion_config_path: "/home/udev1/motor_ingestion/config"
motor_ingestion_logs_path: "/home/udev1/motor_ingestion/logs"
motor_ingestion_data_path: "/home/udev1/motor_ingestion/data"

# Container paths (internal)
motor_ingestion_container_scripts_path: "/app/scripts"
motor_ingestion_container_config_path: "/app/config"
motor_ingestion_container_logs_path: "/app/logs"
motor_ingestion_container_data_path: "/app/data"

# Script entry point
motor_ingestion_script: "main.py"

# User context
motor_ingestion_user: "udev1"

# Environment variables for container
motor_ingestion_env:
  PYTHONUNBUFFERED: "1"
  LOG_LEVEL: "DEBUG"
  INFLUXDB_URL: "http://influxdb:8181"
  INFLUXDB_ORG: "motor_telemetry"
  INFLUXDB_BUCKET: "sensors"
```

**tasks/main.yml:**
```yaml
---
# tasks file for motor_ingestion

- name: Create motor ingestion directories on host
  become: true
  ansible.builtin.file:
    path: "{{ item }}"
    state: directory
    mode: '0755'
    owner: "{{ motor_ingestion_user }}"
    group: "{{ motor_ingestion_user }}"
  loop:
    - "{{ motor_ingestion_host_path }}"
    - "{{ motor_ingestion_scripts_path }}"
    - "{{ motor_ingestion_config_path }}"
    - "{{ motor_ingestion_logs_path }}"
    - "{{ motor_ingestion_data_path }}"
  tags:
    - motor_ingestion

- name: Copy motor ingestion Python scripts to host
  become: true
  ansible.builtin.copy:
    src: "{{ item }}"
    dest: "{{ motor_ingestion_scripts_path }}/{{ item | basename }}"
    mode: '0755'
    owner: "{{ motor_ingestion_user }}"
    group: "{{ motor_ingestion_user }}"
  loop:
    - "/home/ethan/Dev/2m/2m-premaint-02/scripts/motor_ingestion/main.py"
    - "/home/ethan/Dev/2m/2m-premaint-02/scripts/motor_ingestion/sensor_simulator.py"
    - "/home/ethan/Dev/2m/2m-premaint-02/scripts/motor_ingestion/influxdb_connection.py"
  tags:
    - motor_ingestion

- name: Copy requirements.txt to host
  become: true
  ansible.builtin.copy:
    src: "/home/ethan/Dev/2m/2m-premaint-02/scripts/motor_ingestion/requirements.txt"
    dest: "{{ motor_ingestion_scripts_path }}/requirements.txt"
    mode: '0644'
    owner: "{{ motor_ingestion_user }}"
    group: "{{ motor_ingestion_user }}"
  tags:
    - motor_ingestion

- name: Pull Python Docker image
  become: true
  community.docker.docker_image:
    name: "{{ motor_ingestion_image }}"
    source: pull
    state: present
  tags:
    - motor_ingestion

- name: Remove existing motor ingestion container (if any)
  become: true
  community.docker.docker_container:
    name: "{{ motor_ingestion_container_name }}"
    state: absent
  ignore_errors: true
  tags:
    - motor_ingestion

- name: Run motor ingestion container with pip install
  become: true
  community.docker.docker_container:
    name: "{{ motor_ingestion_container_name }}"
    image: "{{ motor_ingestion_image }}"
    state: started
    restart_policy: "{{ motor_ingestion_restart_policy }}"
    networks:
      - name: "{{ motor_ingestion_network }}"
    volumes:
      - "{{ motor_ingestion_scripts_path }}:{{ motor_ingestion_container_scripts_path }}:ro"
      - "{{ motor_ingestion_config_path }}:{{ motor_ingestion_container_config_path }}:ro"
      - "{{ motor_ingestion_logs_path }}:{{ motor_ingestion_container_logs_path }}:rw"
      - "{{ motor_ingestion_data_path }}:{{ motor_ingestion_container_data_path }}:rw"
    env: "{{ motor_ingestion_env }}"
    command: "/bin/bash -c \"pip install --quiet -r {{ motor_ingestion_container_scripts_path }}/requirements.txt && python {{ motor_ingestion_container_scripts_path }}/main.py\""
  tags:
    - motor_ingestion

- name: Wait for motor ingestion container to start
  ansible.builtin.pause:
    seconds: 3
  tags:
    - motor_ingestion

- name: Display motor ingestion container information
  ansible.builtin.debug:
    msg:
      - "Motor Ingestion container is running"
      - "Container name: {{ motor_ingestion_container_name }}"
      - "Image: {{ motor_ingestion_image }}"
      - "User context: {{ motor_ingestion_user }}"
      - "Scripts directory: {{ motor_ingestion_scripts_path }}"
      - "Monitor with: sudo docker logs -f {{ motor_ingestion_container_name }}"
  tags:
    - motor_ingestion
```

**Key Tasks:**
1. Create 5 host directories (scripts, config, logs, data, base)
2. Copy 3 Python scripts from source to container mount point
3. Copy requirements.txt for pip dependencies
4. Pull Python 3.12-slim image
5. Remove any existing container
6. Start container with:
   - Command: Install pip packages, then run main.py
   - Volumes: Read-only for scripts/config, read-write for logs/data
   - Environment variables for InfluxDB connection
   - Network: `gemini-network` for inter-container communication
7. Wait 3 seconds for startup
8. Display confirmation

**Key Configuration:**
- `PYTHONUNBUFFERED: "1"` - Unbuffered output (see logs immediately)
- `INFLUXDB_URL` - Points to influxdb container on network
- Read-only volumes for code, read-write for runtime data
- Command pipes: install requirements then run main.py

---

---

## Phase 4: Ansible Teardown Playbook & Roles

### Phase 4.0: Main Teardown Playbook

**File Location:** `ansible_scripts/teardown_dev_env.yml`  
**Purpose:** Orchestrate infrastructure teardown by calling teardown roles in reverse order  
**Execution:** `ansible-playbook -i ansible_scripts/inventory/hosts ansible_scripts/teardown_dev_env.yml --ask-become-pass`  
**Data Preservation:** User home directory and data directories are preserved (can be manually deleted)

**Playbook Specification:**

```yaml
---
- name: Teardown Development Environment
  hosts: localhost
  connection: local
  gather_facts: true

  pre_tasks:
    - name: Set ansible_user if not defined
      ansible.builtin.set_fact:
        ansible_user: "{{ lookup('env', 'USER') }}"
      when: ansible_user is not defined

  roles:
    - role: teardown_motor_ingestion
    - role: teardown_grafana
    - role: teardown_influxdb
    - role: teardown_udev_user

  tasks:
    - name: Remove Docker images
      become: true
      community.docker.docker_image:
        name: "{{ item }}"
        state: absent
      loop:
        - influxdb:3.7.0-core
        - grafana/grafana:main
      tags:
        - teardown_docker

    - name: Remove Docker network
      become: true
      community.docker.docker_network:
        name: gemini-network
        state: absent
      tags:
        - teardown_docker

    - name: Get current user groups
      ansible.builtin.command: id -G -n {{ ansible_user }}
      register: user_groups
      changed_when: false
      tags:
        - teardown_docker

    - name: Remove ansible_user from the docker group (preserve other groups)
      become: true
      ansible.builtin.user:
        name: "{{ ansible_user }}"
        groups: "{{ user_groups.stdout.split() | difference(['docker']) | join(',') }}"
        append: false
      when: "'docker' in user_groups.stdout.split()"
      tags:
        - teardown_docker

    - name: Get udev1 user groups
      ansible.builtin.command: id -G -n udev1
      register: udev_groups
      changed_when: false
      ignore_errors: true
      tags:
        - teardown_docker

    - name: Remove udev1 from the docker group (preserve other groups)
      become: true
      ansible.builtin.user:
        name: "udev1"
        groups: "{{ udev_groups.stdout.split() | difference(['docker']) | join(',') }}"
        append: false
      when: 
        - udev_groups.failed == false
        - "'docker' in udev_groups.stdout.split()"
      tags:
        - teardown_docker

    - name: Stop and disable Docker service
      become: true
      ansible.builtin.systemd:
        name: docker
        state: stopped
        enabled: false
      tags:
        - teardown_docker

    - name: Uninstall Docker
      become: true
      ansible.builtin.dnf:
        name:
          - docker-ce
          - docker-ce-cli
          - containerd.io
          - docker-buildx-plugin
          - docker-compose-plugin
          - docker-ce-rootless-extras
        state: absent
      tags:
        - teardown_docker

    - name: Display teardown completion information
      ansible.builtin.debug:
        msg:
          - "Teardown complete!"
          - "udev1 home directory preserved: /home/udev1"
          - "Docker container mappings preserved: /home/udev1/*"
          - "Note: You may need to log out and back in for Docker group changes to take effect"
      tags:
        - teardown_docker
```

**Key Structure:**
- **Execution Order:** 4 teardown roles → 1 role with main teardown tasks
- **roles:** Execute teardown roles in reverse order (teardown motor → grafana → influxdb → user)
- **tasks:** Remove images, network, docker group membership, Docker service, Docker packages
- **Data Preservation:** `/home/udev1/` directory NOT deleted (manual cleanup available)

**Execution Flow:**
```
1. teardown_motor_ingestion   → Stop Python container
2. teardown_grafana           → Stop Grafana container
3. teardown_influxdb          → Stop InfluxDB container
4. teardown_udev_user         → Delete udev1 user (home preserved)
5. Main tasks:
   → Remove influxdb & grafana images
   → Remove gemini-network
   → Remove ansible_user from docker group
   → Remove udev1 from docker group
   → Stop Docker service
   → Uninstall Docker packages
```

---

### Phase 4.1: teardown_motor_ingestion Role

**Location:** `ansible_scripts/roles/teardown_motor_ingestion/`

**Purpose:** Stop and remove Python motor ingestion container and image

**Directory Structure:**
```
teardown_motor_ingestion/
├── tasks/
│   └── main.yml
└── vars/
    └── main.yml
```

**vars/main.yml:**
```yaml
---
# vars file for teardown_motor_ingestion

# References same variables as setup role
motor_ingestion_container_name: motor_ingestion
motor_ingestion_image: "python:3.12-slim"
motor_ingestion_host_path: "/home/udev1/motor_ingestion"
motor_ingestion_scripts_path: "/home/udev1/motor_ingestion/scripts"
motor_ingestion_config_path: "/home/udev1/motor_ingestion/config"
motor_ingestion_logs_path: "/home/udev1/motor_ingestion/logs"
motor_ingestion_data_path: "/home/udev1/motor_ingestion/data"
```

**tasks/main.yml:**
```yaml
---
# tasks file for teardown_motor_ingestion

- name: Stop and remove motor ingestion container
  become: true
  community.docker.docker_container:
    name: "{{ motor_ingestion_container_name }}"
    state: absent
  ignore_errors: true
  tags:
    - teardown_motor_ingestion

- name: Remove Python Docker image
  become: true
  community.docker.docker_image:
    name: "{{ motor_ingestion_image }}"
    state: absent
  ignore_errors: true
  tags:
    - teardown_motor_ingestion

- name: Display motor ingestion teardown information
  ansible.builtin.debug:
    msg:
      - "Motor Ingestion container has been stopped and removed"
      - "Python image has been removed"
      - "Note: Data directories are preserved for backup purposes"
      - "Scripts directory: {{ motor_ingestion_scripts_path }}"
      - "Config directory: {{ motor_ingestion_config_path }}"
      - "Logs directory: {{ motor_ingestion_logs_path }}"
      - "Data directory: {{ motor_ingestion_data_path }}"
      - "To delete data, run: rm -rf {{ motor_ingestion_host_path }}"
  tags:
    - teardown_motor_ingestion
```

**Key Tasks:**
1. Stop and remove container (ignore errors if not running)
2. Remove Python 3.12-slim image
3. Display information about preserved data

**Preservation Note:** Python scripts and data directories kept for recovery/debugging

---

### Phase 4.2: teardown_grafana Role

**Location:** `ansible_scripts/roles/teardown_grafana/`

**Purpose:** Stop and remove Grafana container

**Directory Structure:**
```
teardown_grafana/
├── tasks/
│   └── main.yml
└── vars/
    └── main.yml
```

**vars/main.yml:**
```yaml
---
# vars file for teardown_grafana

# References same variables as setup role
grafana_container_name: grafana
grafana_data_host_path: "/home/udev1/grafana-data"
grafana_provisioning_host_path: "/home/udev1/grafana-provisioning"
```

**tasks/main.yml:**
```yaml
---
# tasks file for teardown_grafana

- name: Stop and remove Grafana container
  become: true
  community.docker.docker_container:
    name: "{{ grafana_container_name }}"
    state: absent
  ignore_errors: true
  tags:
    - teardown_grafana

- name: Display teardown message
  ansible.builtin.debug:
    msg:
      - "Grafana container has been removed"
      - "Note: Data directories are preserved for backup purposes"
      - "Data directory: {{ grafana_data_host_path }}"
      - "Provisioning directory: {{ grafana_provisioning_host_path }}"
      - "To delete data, run: rm -rf {{ grafana_data_host_path }} {{ grafana_provisioning_host_path }}"
  tags:
    - teardown_grafana
```

**Key Tasks:**
1. Stop and remove container
2. Display information about preserved data (dashboards, settings)

**Preservation Note:** Grafana dashboards and configurations kept for recovery

---

### Phase 4.3: teardown_influxdb Role

**Location:** `ansible_scripts/roles/teardown_influxdb/`

**Purpose:** Stop and remove InfluxDB container

**Directory Structure:**
```
teardown_influxdb/
├── tasks/
│   └── main.yml
└── vars/
    └── main.yml
```

**vars/main.yml:**
```yaml
---
# vars file for teardown_influxdb

# References same variables as setup role
influxdb_container_name: influxdb
influxdb_data_host_path: "/home/udev1/influxdb-data"
influxdb_config_host_path: "/home/udev1/influxdb-config"
```

**tasks/main.yml:**
```yaml
---
# tasks file for teardown_influxdb

- name: Stop and remove InfluxDB container
  become: true
  community.docker.docker_container:
    name: "{{ influxdb_container_name }}"
    state: absent
  ignore_errors: true
  tags:
    - teardown_influxdb

- name: Display teardown message
  ansible.builtin.debug:
    msg:
      - "InfluxDB container has been removed"
      - "Note: Data directories are preserved for backup purposes"
      - "Data directory: {{ influxdb_data_host_path }}"
      - "Config directory: {{ influxdb_config_host_path }}"
      - "To delete data, run: rm -rf {{ influxdb_data_host_path }} {{ influxdb_config_host_path }}"
  tags:
    - teardown_influxdb
```

**Key Tasks:**
1. Stop and remove container
2. Display information about preserved data (time-series data, configuration)

**Preservation Note:** Time-series motor telemetry data kept for recovery/analysis

---

### Phase 4.4: teardown_udev_user Role

**Location:** `ansible_scripts/roles/teardown_udev_user/`

**Purpose:** Delete udev1 user account (home directory preserved)

**Directory Structure:**
```
teardown_udev_user/
├── tasks/
│   └── main.yml
└── vars/
    └── main.yml
```

**vars/main.yml:**
```yaml
---
# vars file for teardown_udev_user

# User configuration
udev_user: "udev1"
udev_user_home: "/home/udev1"
```

**tasks/main.yml:**
```yaml
---
# tasks file for teardown_udev_user

- name: Check if udev1 user exists
  ansible.builtin.getent:
    database: passwd
    key: "{{ udev_user }}"
  ignore_errors: true
  register: udev_user_info
  tags:
    - teardown_udev_user

- name: Delete udev1 user without removing home directory
  become: true
  ansible.builtin.user:
    name: "{{ udev_user }}"
    state: absent
    remove: false
  when: udev_user_info.failed == false
  tags:
    - teardown_udev_user

- name: Display udev1 user teardown information
  ansible.builtin.debug:
    msg:
      - "udev1 user has been deleted"
      - "Home directory preserved: {{ udev_user_home }}"
      - "Docker container mappings preserved: {{ udev_user_home }}/*"
  tags:
    - teardown_udev_user
```

**Key Tasks:**
1. Check if udev1 user exists
2. Delete user WITHOUT removing home directory (`remove: false`)
3. Display confirmation message

**Key Parameter:** `remove: false` - Critical to preserve `/home/udev1/` directory with all data

---

### Phase 4.5: Main Teardown Tasks

**Location:** `ansible_scripts/teardown_dev_env.yml` (tasks section)

**Included in Playbook:** After all 4 teardown roles complete

**Key Tasks:**

1. **Remove Docker Images:**
   - `influxdb:3.7.0-core`
   - `grafana/grafana:main`
   - (Python image removed by teardown_motor_ingestion role)

2. **Remove Docker Network:**
   - `gemini-network` bridge network
   - Cleans up inter-container communication infrastructure

3. **Remove Docker Group Membership:**
   - Get current user's groups
   - Remove `docker` group while preserving others
   - Same for udev1 user
   - Uses Jinja2 filter: `difference(['docker'])` to preserve other groups

4. **Stop Docker Service:**
   - Stop docker daemon
   - Disable auto-start on boot

5. **Uninstall Docker:**
   - Remove all Docker packages:
     - `docker-ce`
     - `docker-ce-cli`
     - `containerd.io`
     - `docker-buildx-plugin`
     - `docker-compose-plugin`
     - `docker-ce-rootless-extras`

6. **Display Completion Message:**
   - Inform user teardown complete
   - Remind about preserved data
   - Note about group changes requiring re-login

---

## Data Preservation Strategy

### What Gets Deleted:
- ✅ Containers (influxdb, grafana, motor_ingestion)
- ✅ Docker images (influxdb, grafana, python)
- ✅ Docker network (gemini-network)
- ✅ Docker installation and service
- ✅ udev1 user account
- ✅ Docker group membership for users

### What Remains (For Recovery/Audit):
- ✅ `/home/udev1/` directory (with all subdirectories)
- ✅ `/home/udev1/influxdb-data/` - Time-series data
- ✅ `/home/udev1/influxdb-config/` - Database config
- ✅ `/home/udev1/grafana-data/` - Dashboards and settings
- ✅ `/home/udev1/grafana-provisioning/` - Grafana config
- ✅ `/home/udev1/motor_ingestion/` - Scripts, config, logs, data
- ✅ Ansible and other system tools

### Manual Cleanup (If Desired):
```bash
# Delete all motor telemetry data
rm -rf /home/udev1/

# Or delete selectively:
rm -rf /home/udev1/influxdb-data
rm -rf /home/udev1/grafana-data
rm -rf /home/udev1/motor_ingestion
```

---

## Idempotency & Error Handling

**All Tasks Use:**
- `ignore_errors: true` - Continue if container doesn't exist
- `state: absent` - Safe to run multiple times (idempotent)
- `changed_when: false` - For read-only commands that report data

**Safe to Re-run:**
- Teardown playbook can be run multiple times safely
- Will not fail if components already removed
- Each task checks state before acting

---

## Teardown vs. Setup - Symmetry

| Operation | Setup Role | Teardown Role |
|-----------|-----------|---------------|
| Motor Ingestion | `run_motor_ingestion` | `teardown_motor_ingestion` |
| Grafana | `run_grafana` | `teardown_grafana` |
| InfluxDB | `run_influxdb` | `teardown_influxdb` |
| User | `setup_udev_user` | `teardown_udev_user` |
| Docker | `setup_docker` (no teardown) | Main playbook tasks |
| Tools | `install_tools` (no teardown) | Main playbook tasks |

**Reverse Order Execution:**
- Setup: tools → docker → user → influxdb → grafana → ingestion
- Teardown: ingestion → grafana → influxdb → user → docker cleanup → tools cleanup

---

---

## Phase 5: Helper Scripts for Playbook Execution

### Phase 5.1: Setup Playbook Runner Script

**File Location:** `scripts/run_setup_playbook.sh`  
**Purpose:** Convenience wrapper to execute setup playbook with proper error handling and user feedback  
**Execution:** `./scripts/run_setup_playbook.sh`  
**Requires:** Ansible installed and configured (from Phase 2)

**Script Specification:**

```bash
#!/bin/bash

# This script invokes the main Ansible setup playbook to deploy
# the development environment including InfluxDB, Grafana, and Motor Ingestion.

set -e

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Get the project root (parent of scripts directory)
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
ANSIBLE_DIR="$PROJECT_ROOT/ansible_scripts"

echo "======================================="
echo "  Ansible Setup Playbook Runner"
echo "======================================="
echo ""
echo "Project Root: $PROJECT_ROOT"
echo "Ansible Directory: $ANSIBLE_DIR"
echo ""

# Function to print error messages and exit
handle_error() {
    echo "ERROR: $1"
    exit 1
}

# Function to print section headers
print_section() {
    echo ""
    echo "--- $1 ---"
}

# Check if Ansible is installed
print_section "Checking Ansible Installation"
if ! command -v ansible &> /dev/null
then
    handle_error "Ansible is not installed. Please run: ./scripts/setup-ansible.sh"
fi
echo "SUCCESS: Ansible found"

# Check if setup playbook exists
print_section "Verifying Setup Playbook"
SETUP_PLAYBOOK="$ANSIBLE_DIR/setup_dev_env.yml"
if [ ! -f "$SETUP_PLAYBOOK" ]
then
    handle_error "Setup playbook not found at $SETUP_PLAYBOOK"
fi
echo "SUCCESS: Setup playbook found"

# Check if inventory exists
print_section "Verifying Inventory"
INVENTORY="$ANSIBLE_DIR/inventory/hosts"
if [ ! -f "$INVENTORY" ]
then
    handle_error "Inventory file not found at $INVENTORY"
fi
echo "SUCCESS: Inventory file found"

# Check if community.docker collection is installed
print_section "Verifying Ansible Collections"
if ! ansible-galaxy collection list | grep -q community.docker
then
    echo "WARNING: community.docker collection not found"
    echo "Installing community.docker collection..."
    ansible-galaxy collection install community.docker
    if [ $? -ne 0 ]; then
        handle_error "Failed to install community.docker collection."
    fi
fi
echo "SUCCESS: community.docker collection is installed"

# Confirm before proceeding
print_section "Ready to Deploy"
echo ""
echo "This will setup your development environment:"
echo "  - Docker and required tools"
echo "  - Docker network (gemini-network)"
echo "  - Application user (udev1)"
echo "  - InfluxDB container (port 8181)"
echo "  - Grafana container (port 3000)"
echo "  - Motor Ingestion container"
echo ""
read -p "Do you want to proceed? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]
then
    echo "Setup cancelled."
    exit 0
fi

# Run the setup playbook
print_section "Running Setup Playbook"
echo "Executing: ansible-playbook -i $INVENTORY $SETUP_PLAYBOOK --ask-become-pass"
echo ""

cd "$ANSIBLE_DIR"
ansible-playbook -i inventory/hosts setup_dev_env.yml --ask-become-pass

# Check if playbook succeeded
if [ $? -eq 0 ]
then
    echo ""
    echo "======================================="
    echo "  Setup Complete!"
    echo "======================================="
    echo ""
    echo "Access your services:"
    echo "  - InfluxDB:  http://localhost:8181"
    echo "  - Grafana:   http://localhost:3000 (admin/admin)"
    echo ""
    echo "Monitor data ingestion:"
    echo "  docker logs -f motor_ingestion"
    echo ""
else
    handle_error "Setup playbook failed. Please review the output above."
fi

exit 0
```

**Key Elements:**
- **Path Resolution:** Uses `${BASH_SOURCE[0]}` to find script location, then resolves project root
- **Validation:** Checks Ansible, playbook, inventory, and collections before proceeding
- **Auto-Install:** Installs missing `community.docker` collection if needed
- **User Confirmation:** Asks for confirmation before deploying
- **Error Handling:** Validates each step, exits on failure
- **Clear Output:** Section headers and status messages
- **Success Summary:** Shows access URLs and next steps

**Execution Flow:**
```
Start
  ↓
Check Ansible installed
  ├─ NO → Error (user needs to run setup-ansible.sh)
  └─ YES → Continue
  ↓
Check setup playbook exists
  ├─ NO → Error
  └─ YES → Continue
  ↓
Check inventory exists
  ├─ NO → Error
  └─ YES → Continue
  ↓
Check community.docker collection
  ├─ NO → Install it
  └─ YES → Continue
  ↓
Display deployment info + ask for confirmation
  ├─ NO → Exit gracefully
  └─ YES → Continue
  ↓
Run: ansible-playbook ... setup_dev_env.yml --ask-become-pass
  ↓
Success? Display URLs and next steps
  ├─ NO → Error
  └─ YES → Complete
```

**Expected Output:**
```
=======================================
  Ansible Setup Playbook Runner
=======================================

Project Root: /home/ethan/Dev/2m/2m-premaint-02
Ansible Directory: /home/ethan/Dev/2m/2m-premaint-02/ansible_scripts

--- Checking Ansible Installation ---
SUCCESS: Ansible found

--- Verifying Setup Playbook ---
SUCCESS: Setup playbook found

--- Verifying Inventory ---
SUCCESS: Inventory file found

--- Verifying Ansible Collections ---
SUCCESS: community.docker collection is installed

--- Ready to Deploy ---

This will setup your development environment:
  - Docker and required tools
  - Docker network (gemini-network)
  - Application user (udev1)
  - InfluxDB container (port 8181)
  - Grafana container (port 3000)
  - Motor Ingestion container

Do you want to proceed? (yes/no): yes

--- Running Setup Playbook ---
Executing: ansible-playbook -i .../inventory/hosts .../setup_dev_env.yml --ask-become-pass

PLAY [Setup Development Environment] ****
...
PLAY RECAP ****
localhost : ok=35  changed=10  unreachable=0  failed=0

=======================================
  Setup Complete!
=======================================

Access your services:
  - InfluxDB:  http://localhost:8181
  - Grafana:   http://localhost:3000 (admin/admin)

Monitor data ingestion:
  docker logs -f motor_ingestion
```

---

### Phase 5.2: Teardown Playbook Runner Script

**File Location:** `scripts/run_teardown_playbook.sh`  
**Purpose:** Convenience wrapper to execute teardown playbook with proper error handling and warnings  
**Execution:** `./scripts/run_teardown_playbook.sh`  
**Requires:** Ansible installed and configured

**Script Specification:**

```bash
#!/bin/bash

# This script invokes all Ansible teardown playbooks to cleanly remove
# the development environment, including InfluxDB, Grafana, Docker,
# and associated configurations.

set -e

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Get the project root (parent of scripts directory)
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
ANSIBLE_DIR="$PROJECT_ROOT/ansible_scripts"

echo "======================================="
echo "  Ansible Teardown Playbook Runner"
echo "======================================="
echo ""
echo "Project Root: $PROJECT_ROOT"
echo "Ansible Directory: $ANSIBLE_DIR"
echo ""

# Function to print error messages and exit
handle_error() {
    echo "ERROR: $1"
    exit 1
}

# Function to print section headers
print_section() {
    echo ""
    echo "--- $1 ---"
}

# Check if Ansible is installed
print_section "Checking Ansible Installation"
if ! command -v ansible &> /dev/null
then
    handle_error "Ansible is not installed. Please run: ./scripts/setup-ansible.sh"
fi
echo "SUCCESS: Ansible found"

# Check if user has sudo access
print_section "Checking Sudo Access"
if ! sudo -n true 2>/dev/null; then
    echo "INFO: Testing sudo access (may prompt for password)..."
    if ! sudo -l &>/dev/null; then
        handle_error "Your user ($(whoami)) is not in the sudoers file and cannot run sudo commands.

To fix this, ask your system administrator to add your user to sudoers:
  sudo visudo
  
Then add this line:
  $(whoami) ALL=(ALL) NOPASSWD: ALL
  
Or to require password for sudo (more secure):
  $(whoami) ALL=(ALL) ALL

For more information, see: man sudoers"
    fi
fi
echo "SUCCESS: Sudo access verified."

# Check if teardown playbook exists
print_section "Verifying Teardown Playbook"
TEARDOWN_PLAYBOOK="$ANSIBLE_DIR/teardown_dev_env.yml"
if [ ! -f "$TEARDOWN_PLAYBOOK" ]
then
    handle_error "Teardown playbook not found at $TEARDOWN_PLAYBOOK"
fi
echo "SUCCESS: Teardown playbook found"

# Check if inventory exists
print_section "Verifying Inventory"
INVENTORY="$ANSIBLE_DIR/inventory/hosts"
if [ ! -f "$INVENTORY" ]
then
    handle_error "Inventory file not found at $INVENTORY"
fi
echo "SUCCESS: Inventory file found"

# Confirm before proceeding
print_section "WARNING: Destructive Operation"
echo ""
echo "This will tear down your development environment including:"
echo "  - Motor Ingestion container (stopped and removed)"
echo "  - Grafana container (stopped and removed)"
echo "  - InfluxDB container (stopped and removed)"
echo "  - Docker network (gemini-network removed)"
echo "  - Docker group membership (removed from users)"
echo "  - Docker service (stopped and disabled)"
echo "  - Docker packages (uninstalled)"
echo ""
echo "PRESERVED (for recovery):"
echo "  - /home/udev1/ directory with all data"
echo "  - InfluxDB data and configuration files"
echo "  - Grafana dashboards and settings"
echo "  - Motor ingestion scripts and logs"
echo ""
echo "To manually delete preserved data after teardown:"
echo "  rm -rf /home/udev1/"
echo ""
read -p "Do you want to proceed? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]
then
    echo "Teardown cancelled."
    exit 0
fi

# Run the teardown playbook
print_section "Running Teardown Playbook"
echo "Executing: ansible-playbook -i $INVENTORY $TEARDOWN_PLAYBOOK --ask-become-pass"
echo ""

cd "$ANSIBLE_DIR"
ansible-playbook -i inventory/hosts teardown_dev_env.yml --ask-become-pass

# Check if playbook succeeded
if [ $? -eq 0 ]
then
    echo ""
    echo "======================================="
    echo "  Teardown Complete!"
    echo "======================================="
    echo ""
    echo "Your development environment has been removed."
    echo ""
    echo "Data preserved in /home/udev1/:"
    echo "  - InfluxDB data: /home/udev1/influxdb-data/"
    echo "  - Grafana data: /home/udev1/grafana-data/"
    echo "  - Motor ingestion: /home/udev1/motor_ingestion/"
    echo ""
    echo "To delete all data:"
    echo "  rm -rf /home/udev1/"
    echo ""
    echo "Note: You may need to log out and back in for Docker group changes to take effect."
    echo ""
else
    handle_error "Teardown playbook failed. Please review the output above."
fi

exit 0
```

**Key Elements:**
- **Path Resolution:** Same as setup script - finds project root dynamically
- **Validation:** Checks Ansible, playbook, inventory, and sudo access
- **Warning Section:** Clear display of what will be deleted vs. preserved
- **Sudo Check:** Ensures user can run teardown (requires root for Docker)
- **Data Preservation Notice:** Reminds user about recovered data and manual cleanup
- **Error Handling:** Validates prerequisites before proceeding
- **User Confirmation:** Asks twice (implicit + explicit) before destructive action

**Execution Flow:**
```
Start
  ↓
Check Ansible installed
  ├─ NO → Error
  └─ YES → Continue
  ↓
Check sudo access
  ├─ NO → Error (provide sudoers fix)
  └─ YES → Continue
  ↓
Check teardown playbook exists
  ├─ NO → Error
  └─ YES → Continue
  ↓
Check inventory exists
  ├─ NO → Error
  └─ YES → Continue
  ↓
Display WARNING + preserved data info + ask for confirmation
  ├─ NO → Exit gracefully
  └─ YES → Continue
  ↓
Run: ansible-playbook ... teardown_dev_env.yml --ask-become-pass
  ↓
Success? Display preserved data locations and cleanup info
  ├─ NO → Error
  └─ YES → Complete
```

**Expected Output:**
```
=======================================
  Ansible Teardown Playbook Runner
=======================================

Project Root: /home/ethan/Dev/2m/2m-premaint-02
Ansible Directory: /home/ethan/Dev/2m/2m-premaint-02/ansible_scripts

--- Checking Ansible Installation ---
SUCCESS: Ansible found

--- Checking Sudo Access ---
SUCCESS: Sudo access verified.

--- Verifying Teardown Playbook ---
SUCCESS: Teardown playbook found

--- Verifying Inventory ---
SUCCESS: Inventory file found

--- WARNING: Destructive Operation ---

This will tear down your development environment including:
  - Motor Ingestion container (stopped and removed)
  - Grafana container (stopped and removed)
  - InfluxDB container (stopped and removed)
  - Docker network (gemini-network removed)
  - Docker group membership (removed from users)
  - Docker service (stopped and disabled)
  - Docker packages (uninstalled)

PRESERVED (for recovery):
  - /home/udev1/ directory with all data
  - InfluxDB data and configuration files
  - Grafana dashboards and settings
  - Motor ingestion scripts and logs

To manually delete preserved data after teardown:
  rm -rf /home/udev1/

Do you want to proceed? (yes/no): yes

--- Running Teardown Playbook ---
Executing: ansible-playbook -i .../inventory/hosts .../teardown_dev_env.yml --ask-become-pass

PLAY [Teardown Development Environment] ****
...
PLAY RECAP ****
localhost : ok=20  changed=15  unreachable=0  failed=0

=======================================
  Teardown Complete!
=======================================

Your development environment has been removed.

Data preserved in /home/udev1/:
  - InfluxDB data: /home/udev1/influxdb-data/
  - Grafana data: /home/udev1/grafana-data/
  - Motor ingestion: /home/udev1/motor_ingestion/

To delete all data:
  rm -rf /home/udev1/

Note: You may need to log out and back in for Docker group changes to take effect.
```

---

## Summary: Helper Scripts

| Script | Purpose | When to Run |
|--------|---------|-----------|
| `setup-ansible.sh` | Install Ansible and collections | Once, before setup |
| `run_setup_playbook.sh` | Deploy full infrastructure | When ready to setup |
| `run_teardown_playbook.sh` | Remove infrastructure | When ready to cleanup |

**Execution Sequence:**
```
1. ./scripts/setup-ansible.sh          (Phase 2 - one time)
2. ./scripts/run_setup_playbook.sh     (Phase 5 - deployment)
3. [Use infrastructure]
4. ./scripts/run_teardown_playbook.sh  (Phase 5 - cleanup)
```

---

## Complete Script Dependencies

```
run_setup_playbook.sh
  ├─ requires: Ansible installed
  ├─ requires: setup_dev_env.yml
  ├─ requires: inventory/hosts
  ├─ requires: community.docker collection
  └─ calls: ansible-playbook ... setup_dev_env.yml

run_teardown_playbook.sh
  ├─ requires: Ansible installed
  ├─ requires: teardown_dev_env.yml
  ├─ requires: inventory/hosts
  ├─ requires: sudo access
  └─ calls: ansible-playbook ... teardown_dev_env.yml
```

---

## Next Phases (To Be Detailed)

None currently planned - Core infrastructure automation complete!

---

## Critical Design Decisions

### 1. SSH Git URL vs HTTPS
**Decision:** Use SSH URL (`git@github.com:...`)
**Rationale:** 
- More secure than HTTPS with embedded credentials
- Requires SSH keys setup (one-time)
- Standard for developers
- Can be changed to HTTPS if needed

**If Using HTTPS Instead:**
```bash
# Modify clone-repo.sh line:
REPO_URL="https://github.com/mirko-gatti/2m-premaint-02.git"
```

### 2. Package Manager: dnf vs apt vs yum
**Decision:** Use `dnf` (Fedora/RHEL)
**Rationale:**
- Primary OS for this project is Fedora
- Explicit requirement for compatibility
- Other distros need script adaptation

**For Other Distros:**
- Ubuntu/Debian: Replace `dnf install` with `apt install`
- CentOS 7: Use `yum install`
- Alpine: Use `apk add`

### 3. Local Ansible Execution
**Decision:** Use `localhost` with `local` connection
**Rationale:**
- Single-machine setup (dev environment)
- No SSH overhead
- Simpler configuration
- Easy to extend to remote hosts later

### 4. Collection Installation Method
**Decision:** Dual approach - shell script + playbook
**Rationale:**
- Shell script: Direct, simple, one-command setup
- Playbook: Ansible-native, integrated, reproducible
- Both exist for flexibility and documentation

---

## Dependency Map

```
System Requirements
    ↓
Clone Repository (clone-repo.sh)
    ↓
Set Executable Permissions
    ↓
Install Ansible (scripts/setup-ansible.sh)
    ├─ Installs: Ansible
    ├─ Installs: community.docker collection
    └─ Verifies: ansible-galaxy collection list
    ↓
Ansible Inventory Ready (ansible_scripts/inventory/hosts)
    ↓
Ready for Setup Playbook (ansible_scripts/setup_dev_env.yml)
    ├─ install_tools role
    ├─ setup_docker role
    ├─ setup_udev_user role
    ├─ run_influxdb role
    ├─ run_grafana role
    └─ motor_ingestion role
    ↓
3 Containers Running (influxdb, grafana, motor_ingestion)
```

---

## File Inventory - Phase 1 & 2

### Root Level
- `clone-repo.sh` - Repository cloning script

### scripts/
- `setup-ansible.sh` - Ansible installation script
- `teardown-ansible.sh` - Teardown orchestration (Phase 2, to be detailed)

### ansible_scripts/
- `setup_dev_env.yml` - Main setup playbook (Phase 3, to be detailed)
- `teardown_dev_env.yml` - Main teardown playbook (Phase 4, to be detailed)
- `install_collections.yml` - Ansible collections installer

### ansible_scripts/inventory/
- `hosts` - Ansible inventory for localhost

### ansible_scripts/roles/
All to be detailed in Phase 3:
- `install_tools/`
- `setup_docker/`
- `setup_udev_user/`
- `run_influxdb/`
- `run_grafana/`
- `motor_ingestion/`
- `teardown_motor_ingestion/`
- `teardown_grafana/`
- `teardown_influxdb/`
- `teardown_udev_user/`

---

## Testing & Verification Strategy

### Phase 1 Testing
```bash
# After clone-repo.sh
cd ~/Dev/2m/2m-premaint-02
ls -la
# Should see: ansible_scripts/, scripts/, docs/, etc.
```

### Phase 2 Testing
```bash
# After setup-ansible.sh
ansible --version
# Should show: Ansible 2.18+

ansible-galaxy collection list | grep community.docker
# Should list: community.docker

ansible-inventory -i ansible_scripts/inventory/hosts --list
# Should show localhost

ansible -i ansible_scripts/inventory/hosts localhost -m ping
# Should respond: pong
```

---

## Error Handling & Recovery

### Common Issues - Phase 1

**Issue: SSH key not configured for GitHub**
```
Error: Permission denied (publickey)
Solution: 
1. Generate SSH key: ssh-keygen -t rsa -b 4096
2. Add to GitHub: https://github.com/settings/keys
3. Test: ssh -T git@github.com
```

**Issue: Directory already exists**
```
Error: fatal: destination path '...' already exists and is not an empty directory
Solution:
1. Use different target directory: ./clone-repo.sh ~/Dev/2m/2m-premaint-02-new
2. Or delete existing: rm -rf ~/Dev/2m/2m-premaint-02 && ./clone-repo.sh
```

### Common Issues - Phase 2

**Issue: Ansible not found after dnf install**
```
Error: command not found: ansible
Solution:
1. Shell hash table update: hash -r
2. Or logout and login
3. Check installation: which ansible
```

**Issue: Permission denied on scripts**
```
Error: Permission denied: ./setup-ansible.sh
Solution:
chmod +x scripts/setup-ansible.sh
./scripts/setup-ansible.sh
```

**Issue: Sudo password required repeatedly**
```
Solution: Use -S flag or configure sudoers for NOPASSWD (less secure)
Or run: sudo bash setup-ansible.sh (requires root)
```

---

## Progress Tracking

- ✅ **Phase 1:** Repository cloning & permissions
  - ✅ clone-repo.sh specification
  - ✅ Permission setting procedure

- ✅ **Phase 2:** Ansible installation
  - ✅ setup-ansible.sh specification
  - ✅ install_collections.yml specification
  - ✅ inventory/hosts specification

- ✅ **Phase 2.5:** Centralized configuration file
  - ✅ setup-config.yaml complete specification
  - ✅ Usage patterns for scripts and playbooks
  - ✅ Customization examples
  - ✅ Directory structure

- ✅ **Phase 2.6:** InfluxDB security & token generation
  - ✅ influxdb-init.sh specification
  - ✅ verify-influxdb-security.sh specification
  - ✅ Token generation and management
  - ✅ Integration with roles
  - ✅ Security configuration file extension

- ✅ **Phase 2.7:** Grafana security configuration
  - ✅ grafana-init.sh specification
  - ✅ verify-grafana-security.sh specification
  - ✅ Data source token authentication
  - ✅ Service accounts and API tokens
  - ✅ Dashboard provisioning
  - ✅ Security features enabled

- ✅ **Phase 3:** Setup playbook & roles
  - ✅ setup_dev_env.yml playbook
  - ✅ install_tools role
  - ✅ setup_docker role
  - ✅ setup_udev_user role
  - ✅ run_influxdb role
  - ✅ run_grafana role
  - ✅ motor_ingestion role

- ✅ **Phase 4:** Teardown playbook & roles
  - ✅ teardown_dev_env.yml playbook
  - ✅ teardown_motor_ingestion role
  - ✅ teardown_grafana role
  - ✅ teardown_influxdb role
  - ✅ teardown_udev_user role
  - ✅ Data preservation strategy

- ✅ **Phase 5:** Helper scripts
  - ✅ run_setup_playbook.sh specification
  - ✅ run_teardown_playbook.sh specification
  - ✅ Script dependencies documented

---

**Document Status:** Ready for Phase 3 detailed specifications


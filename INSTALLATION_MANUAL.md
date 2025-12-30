# 2M Premaint-03: Installation & Teardown Manual

**Version:** 1.0  
**Last Updated:** December 30, 2025  
**Status:** Production Ready

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Preliminary Steps](#preliminary-steps)
3. [Installation Sequence](#installation-sequence)
4. [Post-Installation Verification](#post-installation-verification)
5. [Teardown Sequence](#teardown-sequence)
6. [Troubleshooting](#troubleshooting)
7. [Quick Reference](#quick-reference)

---

## Prerequisites

### System Requirements

- **OS:** Fedora 40+ (or RHEL/CentOS compatible)
- **CPU:** 2+ cores
- **RAM:** 4GB minimum (8GB recommended)
- **Disk:** 20GB free space
- **Network:** Internet connectivity for package downloads

### Required Software (Pre-installed)

- `bash` (shell)
- `git` (for cloning repository)
- `curl` or `wget` (for downloading packages)
- `sudo` (for privileged operations)

### User Requirements

- Current user must have **sudo access** (passwordless or with password prompt)
- Current user must be able to run `ansible` commands
- No existing Docker installation required (setup handles this)

### Network Requirements

- Ports **3000** and **8181** must be available
- No restrictive firewall blocking container communication
- Docker registry access (docker.io) for pulling images

---

## Preliminary Steps

### Step 1: Clone Repository (If Not Already Done)

```bash
# Clone the repository
git clone git@github.com:<organization>/2m-premaint-03.git
cd 2m-premaint-03

# Verify directory structure
ls -la
# Expected output:
#   ansible_scripts/
#   config/
#   scripts/
#   INSTALLATION_MANUAL.md
#   PROJECT_RECONSTRUCTION_BLUEPRINT.md
#   (other documentation files)
```

### Step 2: Review Configuration

```bash
# Review the setup configuration
cat config/setup-config.yaml

# Key sections to verify:
#   - system.package_manager (should be: dnf for Fedora)
#   - user.username (should be: udev1)
#   - user.home_directory (should be: /home/udev1)
#   - docker network name (should be: m-network)
#   - influxdb.container.port (should be: 8181)
#   - grafana.container.port (should be: 3000)

# IMPORTANT: Change default passwords before production use!
#   - influxdb_security.admin_user.password
#   - influxdb_security.app_user.password
#   - grafana_security.admin.password
```

### Step 3: Verify Ansible Installation

```bash
# Check if Ansible is installed
ansible --version

# If not installed, run:
./scripts/setup-ansible.sh

# Verify community.docker collection
ansible-galaxy collection list | grep community.docker

# If not installed, install it:
ansible-galaxy collection install community.docker
```

### Step 4: Check Current System State

```bash
# Check if Docker is already installed
docker --version

# If Docker exists, check containers
docker ps
docker images

# Check if udev1 user exists
id udev1 || echo "udev1 user not found (this is OK)"

# Check network
docker network ls | grep m-network || echo "m-network not found (this is OK)"
```

---

## Installation Sequence

### PHASE 1: Initial Setup (Full First-Time Installation)

#### Step 1: Start the Setup Wizard

```bash
cd /path/to/2m-premaint-03

# Run the main setup script
./scripts/run_setup_playbook.sh

# The script will display:
#   - Project paths
#   - Ansible installation check
#   - Setup playbook location verification
#   - Inventory file verification
#   - Community.docker collection check
#
# THEN: You'll see a detailed warning with setup details
# THEN: You'll be asked for explicit confirmation (type 'yes')
# THEN: Setup begins with sudo password prompt
```

#### Step 2: Provide Sudo Password

```bash
# When prompted: "Please provide your password for sudo"
# Enter your user's password (required for Docker installation and daemon setup)

# The setup will:
# 1. Install Ansible (if not already installed)
# 2. Download and install Docker
# 3. Start Docker daemon
# 4. Create udev1 user
# 5. Add users to docker group
# 6. Create Docker network
# 7. Start InfluxDB container
# 8. Start Grafana container
# 9. Start Motor Ingestion container
# 10. Initialize InfluxDB security
# 11. Initialize Grafana security
```

#### Step 3: Wait for Completion

```bash
# Installation typically takes 5-10 minutes on first run
# Monitor the output for:
#
# ✓ All role executions complete
# ✓ Post-tasks run (InfluxDB and Grafana initialization)
# ✓ Final summary displayed

# Expected final output:
#   =========================================
#   Development Environment Setup Complete!
#   =========================================
#   
#   Containers Running:
#     - InfluxDB (port 8181): http://localhost:8181
#     - Grafana (port 3000): http://localhost:3000
#     - Motor Ingestion: Ready for Python scripts
```

---

## Post-Installation Verification

### Verification Step 1: Check Containers

```bash
# Verify all three containers are running
docker ps

# Expected output (3 containers):
#   CONTAINER ID   IMAGE                      NAMES
#   ...            influxdb:3.7.0-core        influxdb
#   ...            grafana/grafana:main       grafana
#   ...            python:3.14-slim           motor_ingestion
```

### Verification Step 2: Check Docker Network

```bash
# Verify m-network exists and containers are connected
docker network inspect m-network

# Expected output:
#   - Network name: m-network
#   - Driver: bridge
#   - Connected containers: influxdb, grafana, motor_ingestion
```

### Verification Step 3: Check Generated Token Files

```bash
# Navigate to project root
cd /path/to/2m-premaint-03

# Check InfluxDB tokens
ls -la .influxdb-*-token

# Expected files:
#   .influxdb-admin-token
#   .influxdb-motor-token
#   .influxdb-grafana-token

# Check Grafana tokens
ls -la .grafana-*-token

# Expected files:
#   .grafana-admin-token
#   .grafana-provisioning-token (may not exist if service account creation failed)

# Check token content (they should contain actual tokens, not placeholders)
cat .influxdb-admin-token | wc -c
# Should be > 50 characters
```

### Verification Step 4: Check State Markers

```bash
# Verify initialization completion markers
ls -la .influxdb-initialized .grafana-initialized

# Expected output:
#   -rw-r--r-- ... .influxdb-initialized
#   -rw-r--r-- ... .grafana-initialized
```

### Verification Step 5: Check InfluxDB Health

```bash
# Check InfluxDB is responding
curl -s http://localhost:8181/health | jq .

# Expected response:
#   {
#     "status": "ok"
#   }

# Check organization was created
docker exec influxdb influxdb3 org list

# Expected output:
#   Organization ID: motor_telemetry

# Check bucket was created
docker exec influxdb influxdb3 bucket list --org motor_telemetry

# Expected output:
#   Bucket ID: sensors
```

### Verification Step 6: Check Grafana Health

```bash
# Check Grafana is responding
curl -s http://localhost:3000/api/health | jq .

# Expected response (partial):
#   {
#     "status": "ok",
#     "database": "ok"
#   }

# List datasources (should have InfluxDB-Motor)
curl -s -u admin:admin http://localhost:3000/api/datasources | jq '.[].name'

# Expected output:
#   InfluxDB-Motor
```

### Verification Step 7: Check Data Directories

```bash
# Verify all data directories are created with proper ownership
ls -la /home/udev1/ | grep -E "influxdb|grafana|motor"

# Expected output:
#   drwxr-xr-x  udev1  udev1  influxdb-config
#   drwxr-xr-x  udev1  udev1  influxdb-data
#   drwxr-xr-x  udev1  udev1  grafana-data
#   drwxr-xr-x  udev1  udev1  grafana-provisioning
#   drwxr-xr-x  udev1  udev1  motor_ingestion
```

### Verification Step 8: Quick Integration Test

```bash
# Write test data to InfluxDB
docker exec influxdb influxdb3 write \
  --org motor_telemetry \
  --bucket sensors \
  --file - << 'EOF'
measurement,motor_id=MOTOR_001 current_amps=25.5 1640880000000000000
EOF

# Query test data
docker exec influxdb influxdb3 query \
  --org motor_telemetry \
  'from(bucket:"sensors") |> range(start:-1h)'

# Expected output: Should show the test measurement
```

### Summary Check Script

Run all checks at once:

```bash
# Create a verification script (or use the one provided)
./scripts/verify-setup.sh

# This will check:
# ✓ All containers running
# ✓ Network connectivity
# ✓ Token files exist
# ✓ InfluxDB health
# ✓ Grafana health
# ✓ Data directories
```

---

## Idempotency Test (Optional But Recommended)

After successful first installation, test idempotency:

```bash
# Run setup again without changes
./scripts/run_setup_playbook.sh

# Expected behavior:
# - All Ansible tasks report "ok" (no changes)
# - InfluxDB init script skips (state marker exists)
# - Grafana init script skips (state marker exists)
# - Containers report "started" but not recreated
# - Final output shows changed=0
```

---

## Teardown Sequence

### Step 1: Prepare for Teardown

```bash
# Backup any important data (optional)
cp -r /home/udev1/ /backup/udev1-backup-$(date +%Y%m%d)

# Optionally: Back up token files
cp .influxdb-*-token /backup/
cp .grafana-*-token /backup/

# Navigate to project directory
cd /path/to/2m-premaint-03
```

### Step 2: Run Teardown Script

```bash
# Execute teardown
./scripts/run_teardown_playbook.sh

# The script will display:
#   - Detailed warning about removal
#   - List of what will be removed
#   - Confirmation requirement (type 'yes' explicitly)
#   - Sudo password prompt

# Teardown will:
# 1. Stop and remove all containers
# 2. Remove Docker network
# 3. Remove Docker images (explicit list)
# 4. Prune dangling images
# 5. Clean orphaned volumes
# 6. Stop Docker daemon
# 7. Remove Docker packages
# 8. Remove udev1 user and group membership
# 9. Clean systemd service files
# 10. Remove Docker configuration
```

### Step 3: Verify Complete Removal

```bash
# Check containers are gone
docker ps -a
# Should show no 2m-premaint containers

# Check network is gone
docker network ls | grep m-network
# Should show nothing

# Check images are gone
docker images | grep -E "influxdb|grafana|python:3.14"
# Should show nothing

# Check udev1 user is gone
id udev1
# Should return: "id: 'udev1': no such user"

# Check Docker is uninstalled (optional, depends on setup)
which docker
# May still exist if system package manager, but daemon should not run
```

### Step 4: Optional Complete Cleanup

```bash
# Remove state markers (if reinstalling from scratch)
rm -f .influxdb-initialized .grafana-initialized

# Remove token files (if reinstalling)
rm -f .influxdb-*-token .grafana-*-token

# Remove all user data (CAUTION: Destructive)
# sudo rm -rf /home/udev1/

# Remove project directory (if desired)
# cd /parent/directory && rm -rf 2m-premaint-03
```

---

## Common Workflows

### Workflow 1: Fresh Installation on New System

```bash
# 1. Clone repository
git clone git@github.com:<org>/2m-premaint-03.git
cd 2m-premaint-03

# 2. Review configuration
cat config/setup-config.yaml
# Edit passwords if needed: nano config/setup-config.yaml

# 3. Run setup
./scripts/run_setup_playbook.sh
# Confirm with "yes"
# Enter sudo password

# 4. Verify installation
./scripts/verify-setup.sh

# 5. Access services
# InfluxDB: http://localhost:8181
# Grafana: http://localhost:3000 (admin/admin)
```

### Workflow 2: Re-run Setup (Idempotent)

```bash
# This is safe to run multiple times
cd /path/to/2m-premaint-03
./scripts/run_setup_playbook.sh

# Expected: All tasks report "ok", no changes made
```

### Workflow 3: Reset Everything

```bash
# 1. Teardown completely
cd /path/to/2m-premaint-03
./scripts/run_teardown_playbook.sh

# 2. Clear state markers
rm -f .influxdb-initialized .grafana-initialized

# 3. Fresh setup
./scripts/run_setup_playbook.sh
```

### Workflow 4: Data Preservation Teardown

```bash
# 1. Teardown (preserves /home/udev1/ data)
./scripts/run_teardown_playbook.sh

# 2. Data is still available in /home/udev1/
ls /home/udev1/influxdb-data/
ls /home/udev1/grafana-data/

# 3. Re-setup (reuses volumes)
./scripts/run_setup_playbook.sh

# 4. All previous data is restored!
```

---

## Troubleshooting

### Problem: "permission denied while trying to connect to the docker API"

**Cause:** Init scripts don't have Docker daemon access  
**Solution:**
```bash
# This is now fixed in the latest setup_dev_env.yml
# The playbook adds 'become: true' to init script tasks

# If you still see this error:
# 1. Ensure setup_dev_env.yml has 'become: true' on init tasks
# 2. Check that ansible_user is in docker group:
sudo groups $USER | grep docker

# 3. If not in docker group, add manually:
sudo usermod -aG docker $USER
newgrp docker

# 4. Retry setup
./scripts/run_setup_playbook.sh
```

### Problem: Docker daemon not running

**Cause:** Docker service not started  
**Solution:**
```bash
# Check status
sudo systemctl status docker

# Start Docker
sudo systemctl start docker

# Enable auto-start
sudo systemctl enable docker

# Verify it's running
docker ps
```

### Problem: Port 3000 or 8181 already in use

**Cause:** Another service using the port  
**Solution:**
```bash
# Find process using port
sudo lsof -i :3000      # For Grafana
sudo lsof -i :8181      # For InfluxDB

# Either stop the process or change port in config/setup-config.yaml
# Edit the port numbers and rerun setup
nano config/setup-config.yaml
./scripts/run_setup_playbook.sh
```

### Problem: "Ansible is not installed"

**Cause:** Ansible not on system  
**Solution:**
```bash
# Run Ansible setup script
./scripts/setup-ansible.sh

# Or install manually
sudo dnf install ansible-core

# Verify installation
ansible --version
```

### Problem: "community.docker collection not found"

**Cause:** Ansible collection not installed  
**Solution:**
```bash
# Install the collection
ansible-galaxy collection install community.docker

# Verify installation
ansible-galaxy collection list | grep community.docker
```

### Problem: Setup hangs or times out

**Cause:** System too slow, network issues, or container startup delays  
**Solution:**
```bash
# Ctrl+C to interrupt
# Check Docker status
docker ps

# If containers are partially created, try idempotent re-run:
./scripts/run_setup_playbook.sh

# If that doesn't work, teardown and retry:
./scripts/run_teardown_playbook.sh
./scripts/run_setup_playbook.sh
```

### Problem: InfluxDB init fails

**Cause:** InfluxDB container not ready  
**Solution:**
```bash
# Check if container is running
docker ps | grep influxdb

# Check container logs
docker logs influxdb

# Wait for health check to pass
docker exec influxdb curl http://localhost:8181/health

# Once healthy, manually run init
./scripts/influxdb-init.sh
```

### Problem: Grafana init fails

**Cause:** Grafana container not ready or datasource issues  
**Solution:**
```bash
# Check if container is running
docker ps | grep grafana

# Check container logs
docker logs grafana

# Wait for health check to pass
docker exec grafana curl http://localhost:3000/api/health

# Once healthy, manually run init
./scripts/grafana-init.sh
```

### Problem: Token files not created

**Cause:** Init script failed silently or was skipped  
**Solution:**
```bash
# Check if state markers exist
ls -la .influxdb-initialized .grafana-initialized

# If they exist, remove to force re-initialization
rm -f .influxdb-initialized .grafana-initialized

# Run init scripts manually
./scripts/influxdb-init.sh
./scripts/grafana-init.sh

# Verify tokens were created
ls -la .influxdb-*-token .grafana-*-token
```

---

## Quick Reference

### Essential Commands

| Task | Command |
|------|---------|
| Full Setup | `./scripts/run_setup_playbook.sh` |
| Full Teardown | `./scripts/run_teardown_playbook.sh` |
| Verify Setup | `./scripts/verify-setup.sh` |
| InfluxDB Init | `./scripts/influxdb-init.sh` |
| Grafana Init | `./scripts/grafana-init.sh` |
| Check Containers | `docker ps` |
| Check Logs (InfluxDB) | `docker logs influxdb` |
| Check Logs (Grafana) | `docker logs grafana` |
| Check Logs (Motor) | `docker logs motor_ingestion` |

### Service URLs

| Service | URL | Credentials |
|---------|-----|-------------|
| InfluxDB UI | http://localhost:8181 | influx_admin / (see config) |
| Grafana | http://localhost:3000 | admin / admin |
| Motor Ingestion | (container only) | - |

### Important Files

| File | Purpose |
|------|---------|
| `config/setup-config.yaml` | Configuration (CHANGE PASSWORDS!) |
| `scripts/run_setup_playbook.sh` | Main setup orchestrator |
| `scripts/run_teardown_playbook.sh` | Main teardown orchestrator |
| `ansible_scripts/setup_dev_env.yml` | Ansible playbook |
| `.influxdb-admin-token` | InfluxDB admin token |
| `.influxdb-motor-token` | InfluxDB motor ingestion token |
| `.influxdb-grafana-token` | InfluxDB Grafana token |
| `.grafana-admin-token` | Grafana API token |

### Data Locations

| Service | Data Location | Owner |
|---------|---------------|-------|
| InfluxDB Data | `/home/udev1/influxdb-data` | udev1 |
| InfluxDB Config | `/home/udev1/influxdb-config` | udev1 |
| Grafana Data | `/home/udev1/grafana-data` | udev1 |
| Motor Ingestion | `/home/udev1/motor_ingestion` | udev1 |

---

## Support & Documentation

For more detailed information, see:

- **[SETUP_IDEMPOTENCY_AUDIT.md](SETUP_IDEMPOTENCY_AUDIT.md)** - Issue analysis
- **[SETUP_IDEMPOTENCY_FIXES.md](SETUP_IDEMPOTENCY_FIXES.md)** - Fix documentation
- **[SETUP_SCRIPT_REVIEW_COMPLETE.md](SETUP_SCRIPT_REVIEW_COMPLETE.md)** - Complete review
- **[PROJECT_RECONSTRUCTION_BLUEPRINT.md](PROJECT_RECONSTRUCTION_BLUEPRINT.md)** - Original blueprint

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-12-30 | Initial manual creation |

---

**Last Updated:** December 30, 2025  
**Status:** Production Ready  
**Maintainer:** 2M Development Team

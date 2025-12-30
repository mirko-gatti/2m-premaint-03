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
print_section "Ready to Deploy - Please Review"
echo ""
echo "⚠️  WARNING: This setup will perform the following actions:"
echo ""
echo "✓ Installation:"
echo "    - Install Ansible and Docker"
echo "    - Setup Docker daemon and enable auto-start"
echo "    - Create application user (udev1)"
echo ""
echo "✓ Docker Infrastructure:"
echo "    - Create Docker network: m-network"
echo "    - Pull Docker images (InfluxDB, Grafana, Python)"
echo "    - Create data directories under /home/udev1/"
echo ""
echo "✓ Containers (will be started and configured for auto-restart):"
echo "    - InfluxDB (port 8181) - Time-series database"
echo "    - Grafana (port 3000) - Visualization dashboard"
echo "    - Motor Ingestion (Python 3.14) - Data ingestion container"
echo ""
echo "✓ Security Configuration:"
echo "    - Create InfluxDB users and organizations"
echo "    - Generate InfluxDB API tokens (saved to .influxdb-*-token files)"
echo "    - Configure Grafana admin user and datasource"
echo "    - Generate Grafana API tokens (saved to .grafana-*-token files)"
echo ""
echo "⚠️  REQUIREMENTS:"
echo "    - Sudo/root access required"
echo "    - Docker installation will download and execute get-docker.sh"
echo "    - Network ports 8181 and 3000 must be available"
echo "    - Estimated time: 5-10 minutes on first run"
echo ""
echo "✓ DATA PRESERVATION:"
echo "    - All data in /home/udev1/*/data directories persists across teardowns"
echo "    - To cleanly remove everything: run_teardown_playbook.sh"
echo ""
read -p "Are you SURE you want to proceed? (type 'yes' to confirm): " CONFIRM

if [ "$CONFIRM" != "yes" ]
then
    echo ""
    echo "Setup cancelled by user."
    exit 0
fi

echo ""

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

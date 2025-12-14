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
echo "  - Docker network (m-network)"
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

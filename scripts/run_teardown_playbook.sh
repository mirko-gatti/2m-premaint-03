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
echo "  - Docker network (m-network removed)"
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

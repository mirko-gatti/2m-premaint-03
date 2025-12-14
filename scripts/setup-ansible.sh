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

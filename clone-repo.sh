#!/bin/bash

# Clone the 2m-premaint-03 repository from GitHub

set -e

REPO_URL="git@github.com:mirko-gatti/2m-premaint-03.git"
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
echo "2. Set executable permissions: chmod +x scripts/*.sh"
echo "3. Run: ./scripts/setup-ansible.sh"
echo "4. Run: ./scripts/run_setup_playbook.sh"
echo ""
echo "======================================="

exit 0

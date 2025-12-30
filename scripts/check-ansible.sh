#!/bin/bash

# Ansible Installation Check Script
# Checks for Ansible installation and optionally installs it
# Also ensures required Ansible collections are available

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print section headers
print_section() {
    echo ""
    echo -e "${BLUE}════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}════════════════════════════════════════════${NC}"
    echo ""
}

# ==================== ANSIBLE INSTALLATION ====================

print_section "Ansible Installation Check"

# Check if Ansible is installed
if command -v ansible &> /dev/null; then
    ANSIBLE_VERSION=$(ansible --version | head -n 1)
    echo -e "${GREEN}✓${NC} Ansible is installed"
    echo -e "  ${CYAN}$ANSIBLE_VERSION${NC}"
else
    echo -e "${RED}✗${NC} Ansible is ${RED}NOT${NC} installed"
    echo ""
    read -p "Install Ansible now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}→${NC} Installing Ansible..."
        
        if command -v dnf &> /dev/null; then
            echo -e "${CYAN}  Using dnf package manager${NC}"
            if sudo dnf install -y ansible-core &> /dev/null; then
                echo -e "${GREEN}✓${NC} Ansible installed successfully"
            else
                echo -e "${RED}✗${NC} Failed to install Ansible via dnf"
                echo ""
                echo "Try installing manually:"
                echo "  Fedora/RHEL: ${CYAN}sudo dnf install ansible-core${NC}"
                echo "  Ubuntu/Debian: ${CYAN}sudo apt-get install ansible${NC}"
                exit 1
            fi
        elif command -v apt-get &> /dev/null; then
            echo -e "${CYAN}  Using apt-get package manager${NC}"
            if sudo apt-get update > /dev/null && sudo apt-get install -y ansible &> /dev/null; then
                echo -e "${GREEN}✓${NC} Ansible installed successfully"
            else
                echo -e "${RED}✗${NC} Failed to install Ansible via apt-get"
                echo ""
                echo "Try installing manually:"
                echo "  Ubuntu/Debian: ${CYAN}sudo apt-get install ansible${NC}"
                exit 1
            fi
        elif command -v pacman &> /dev/null; then
            echo -e "${CYAN}  Using pacman package manager${NC}"
            if sudo pacman -S --noconfirm ansible &> /dev/null; then
                echo -e "${GREEN}✓${NC} Ansible installed successfully"
            else
                echo -e "${RED}✗${NC} Failed to install Ansible via pacman"
                exit 1
            fi
        else
            echo -e "${RED}✗${NC} No supported package manager found"
            echo ""
            echo "Please install Ansible manually:"
            echo "  ${CYAN}https://docs.ansible.com/ansible/latest/installation_guide/index.html${NC}"
            exit 1
        fi
    else
        echo -e "${YELLOW}⚠${NC}  Ansible is required to run the setup. Exiting."
        exit 1
    fi
fi

echo ""

# ==================== ANSIBLE COLLECTIONS ====================

print_section "Ansible Collections Check"

# Check community.docker collection
if ansible-galaxy collection list 2>/dev/null | grep -q "community.docker"; then
    VERSION=$(ansible-galaxy collection list 2>/dev/null | grep "community.docker" | awk '{print $2}')
    echo -e "${GREEN}✓${NC} community.docker collection is installed"
    echo -e "  ${CYAN}Version: $VERSION${NC}"
else
    echo -e "${RED}✗${NC} community.docker collection is ${RED}NOT${NC} installed"
    echo ""
    read -p "Install community.docker collection now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}→${NC} Installing community.docker collection..."
        if ansible-galaxy collection install community.docker -f &> /dev/null; then
            echo -e "${GREEN}✓${NC} community.docker collection installed successfully"
        else
            echo -e "${RED}✗${NC} Failed to install community.docker collection"
            echo ""
            echo "Try installing manually:"
            echo "  ${CYAN}ansible-galaxy collection install community.docker${NC}"
            exit 1
        fi
    else
        echo -e "${YELLOW}⚠${NC}  community.docker collection is required. Exiting."
        exit 1
    fi
fi

echo ""

# ==================== SUMMARY ====================

print_section "Ansible Check Complete"

echo -e "${GREEN}✓${NC} Ansible environment is ready"
echo ""
echo "Next steps:"
echo "  1. Check environment setup: ${CYAN}./scripts/check-environment.sh${NC}"
echo "  2. Run full setup menu: ${CYAN}./scripts/setup-menu.sh${NC}"
echo ""

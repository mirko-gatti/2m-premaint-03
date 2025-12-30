#!/bin/bash

# Prerequisites Check Script
# Checks for system dependencies required to run the project
# Offers to install missing prerequisites when possible

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

# Counters
INSTALLED=0
MISSING=0
FAILED_INSTALL=0

# Function to print section headers
print_section() {
    echo ""
    echo -e "${BLUE}════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}════════════════════════════════════════════${NC}"
    echo ""
}

# Function to check and report command availability
check_command() {
    local cmd="$1"
    local package="$2"
    local display_name="${3:-$cmd}"
    
    if command -v "$cmd" &> /dev/null; then
        version=$("$cmd" --version 2>&1 | head -n 1 || echo "")
        echo -e "${GREEN}✓${NC} $display_name is installed"
        if [ -n "$version" ]; then
            echo -e "  ${CYAN}$version${NC}"
        fi
        ((INSTALLED++))
        return 0
    else
        echo -e "${RED}✗${NC} $display_name is ${RED}NOT${NC} installed"
        echo -e "  Package: ${CYAN}$package${NC}"
        ((MISSING++))
        return 1
    fi
}

# Function to try installing a package
try_install() {
    local package="$1"
    local cmd="$2"
    
    # Determine package manager
    if command -v dnf &> /dev/null; then
        echo -e "${YELLOW}→${NC} Installing via dnf: ${CYAN}$package${NC}"
        if sudo dnf install -y "$package" &> /dev/null; then
            echo -e "${GREEN}✓${NC} Successfully installed: $package"
            ((INSTALLED++))
            ((MISSING--))
            return 0
        else
            echo -e "${RED}✗${NC} Failed to install: $package"
            ((FAILED_INSTALL++))
            ((MISSING--))
            return 1
        fi
    elif command -v apt-get &> /dev/null; then
        echo -e "${YELLOW}→${NC} Installing via apt-get: ${CYAN}$package${NC}"
        if sudo apt-get update > /dev/null && sudo apt-get install -y "$package" &> /dev/null; then
            echo -e "${GREEN}✓${NC} Successfully installed: $package"
            ((INSTALLED++))
            ((FAILED_INSTALL--))
            return 0
        else
            echo -e "${RED}✗${NC} Failed to install: $package"
            ((FAILED_INSTALL++))
            return 1
        fi
    elif command -v pacman &> /dev/null; then
        echo -e "${YELLOW}→${NC} Installing via pacman: ${CYAN}$package${NC}"
        if sudo pacman -S --noconfirm "$package" &> /dev/null; then
            echo -e "${GREEN}✓${NC} Successfully installed: $package"
            ((INSTALLED++))
            ((MISSING--))
            return 0
        else
            echo -e "${RED}✗${NC} Failed to install: $package"
            ((FAILED_INSTALL++))
            ((MISSING--))
            return 1
        fi
    else
        echo -e "${RED}✗${NC} No supported package manager found (dnf, apt-get, pacman)"
        return 1
    fi
}

# ==================== START CHECKS ====================

print_section "System Prerequisites Check"

echo -e "${CYAN}Checking required system packages...${NC}"
echo ""

# Check curl
if ! check_command "curl" "curl" "curl (HTTP client)"; then
    read -p "Install curl now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        try_install "curl" "curl"
    fi
fi
echo ""

# Check git
if ! check_command "git" "git" "git (Version control)"; then
    read -p "Install git now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        try_install "git" "git"
    fi
fi
echo ""

# Check Docker
if ! check_command "docker" "docker-ce" "Docker (Container runtime)"; then
    echo -e "${YELLOW}⚠${NC}  Docker is required to run containers"
    read -p "Install Docker now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}→${NC} Installing Docker..."
        if command -v dnf &> /dev/null; then
            # Install docker via dnf
            if sudo dnf install -y docker-ce &> /dev/null; then
                echo -e "${GREEN}✓${NC} Docker installed successfully"
                echo -e "${YELLOW}→${NC} Starting Docker daemon..."
                sudo systemctl daemon-reload
                sudo systemctl enable docker
                sudo systemctl start docker
                echo -e "${GREEN}✓${NC} Docker daemon started"
                ((INSTALLED++))
                ((MISSING--))
            else
                echo -e "${RED}✗${NC} Failed to install Docker"
                ((FAILED_INSTALL++))
            fi
        else
            echo -e "${YELLOW}→${NC} Please visit: ${CYAN}https://docs.docker.com/install/${NC}"
            echo -e "${YELLOW}→${NC} Run installation script and retry this script"
            ((FAILED_INSTALL++))
        fi
    fi
fi
echo ""

# Check Python 3
if ! check_command "python3" "python3" "Python 3 (Programming language)"; then
    read -p "Install python3 now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        try_install "python3" "python3"
    fi
fi
echo ""

# Check pip
if ! check_command "pip3" "python3-pip" "pip3 (Python package manager)"; then
    read -p "Install pip3 now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        try_install "python3-pip" "pip3"
    fi
fi
echo ""

# Check sudo
if ! command -v sudo &> /dev/null; then
    echo -e "${RED}✗${NC} sudo is ${RED}NOT${NC} installed (Required for installation)"
    echo -e "  ${RED}This cannot be automatically installed as it requires root${NC}"
    ((MISSING++))
    ((FAILED_INSTALL++))
fi
echo ""

# ==================== SUMMARY ====================

print_section "Prerequisites Summary"

echo -e "${GREEN}Installed: $INSTALLED${NC}"
echo -e "${RED}Missing: $MISSING${NC}"
if [ $FAILED_INSTALL -gt 0 ]; then
    echo -e "${YELLOW}Failed to Install: $FAILED_INSTALL${NC}"
fi
echo ""

if [ $MISSING -eq 0 ]; then
    echo -e "${GREEN}✓ All prerequisites are met!${NC}"
    echo ""
    echo "You can now proceed with:"
    echo "  1. Check Ansible installation: ${CYAN}./scripts/check-ansible.sh${NC}"
    echo "  2. Run setup menu: ${CYAN}./scripts/setup-menu.sh${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠${NC}  Some prerequisites are missing or failed to install"
    echo ""
    if [ $FAILED_INSTALL -gt 0 ]; then
        echo "Manual installation required for:"
        grep -E "✗" <<< "$(check_command 'curl' 'curl' 'curl')" || true
        echo ""
        echo "Please install the missing packages manually and retry:"
        echo "  - Fedora/RHEL: ${CYAN}sudo dnf install <package>${NC}"
        echo "  - Ubuntu/Debian: ${CYAN}sudo apt-get install <package>${NC}"
        echo "  - Arch: ${CYAN}sudo pacman -S <package>${NC}"
        echo ""
    fi
    exit 1
fi

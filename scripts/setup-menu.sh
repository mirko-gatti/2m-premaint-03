#!/bin/bash

# Interactive Setup Menu
# Guides users through the complete setup process with a user-friendly menu interface
# Provides options to check prerequisites, verify Ansible, run setup, and check environment

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Function to clear screen and show banner
show_banner() {
    clear
    echo -e "${BOLD}${BLUE}"
    cat << "EOF"
    ╔═══════════════════════════════════════════════════════════════════════╗
    ║                                                                       ║
    ║                   2M PREMAINT-03 Setup Menu                          ║
    ║                                                                       ║
    ║          Complete Setup & Configuration Guide                        ║
    ║                                                                       ║
    ╚═══════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Function to show main menu
show_main_menu() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Main Menu${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${BOLD}1${NC}) Check Prerequisites"
    echo -e "     Verify and install system dependencies (curl, git, Python, Docker)"
    echo ""
    echo -e "  ${BOLD}2${NC}) Check Ansible"
    echo -e "     Verify and install Ansible and required collections"
    echo ""
    echo -e "  ${BOLD}3${NC}) Setup Environment"
    echo -e "     Run Ansible playbook to deploy InfluxDB, Grafana, and Motor Ingestion"
    echo ""
    echo -e "  ${BOLD}4${NC}) Check Environment"
    echo -e "     Detailed verification of the complete setup (status, configs, security)"
    echo ""
    echo -e "  ${BOLD}5${NC}) Quick Start Guide"
    echo -e "     Display helpful information about accessing services"
    echo ""
    echo -e "  ${BOLD}6${NC}) Exit"
    echo -e "     Close this menu"
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
}

# Function to pause and wait for input
pause_menu() {
    echo ""
    read -p "Press ${BOLD}ENTER${NC} to continue..." -r
}

# Function to run a subscript
run_script() {
    local script="$1"
    local title="$2"
    
    if [ ! -f "$SCRIPT_DIR/$script" ]; then
        echo ""
        echo -e "${RED}✗ Error: Script not found: $script${NC}"
        pause_menu
        return 1
    fi
    
    echo ""
    echo -e "${BLUE}Running: $title${NC}"
    echo ""
    
    bash "$SCRIPT_DIR/$script"
    local exit_code=$?
    
    echo ""
    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}✓ $title completed successfully${NC}"
    else
        echo -e "${YELLOW}⚠ $title completed with warnings or errors${NC}"
    fi
    
    pause_menu
    return $exit_code
}

# Function to show quick start guide
show_quick_start() {
    clear
    echo -e "${BOLD}${BLUE}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════════════╗
║                      Quick Start Guide                               ║
╚═══════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    echo -e "${CYAN}📋 Service Access${NC}"
    echo -e "═══════════════════════════════════════════════════════════════"
    echo ""
    echo -e "  ${BOLD}InfluxDB${NC} (Time Series Database)"
    echo -e "    URL:      ${GREEN}http://localhost:8181${NC}"
    echo -e "    Port:     ${CYAN}8181${NC}"
    echo -e "    Admin Token: Saved in ${YELLOW}.influxdb-admin-token${NC}"
    echo ""
    
    echo -e "  ${BOLD}Grafana${NC} (Visualization & Dashboards)"
    echo -e "    URL:      ${GREEN}http://localhost:3000${NC}"
    echo -e "    Port:     ${CYAN}3000${NC}"
    echo -e "    Default:  ${CYAN}admin / admin${NC} (change after first login)"
    echo -e "    Admin Token: Saved in ${YELLOW}.grafana-admin-token${NC}"
    echo ""
    
    echo -e "  ${BOLD}Motor Ingestion${NC} (Data Ingestion Container)"
    echo -e "    Container: ${CYAN}motor_ingestion${NC}"
    echo -e "    Type:     ${CYAN}Python 3.14${NC}"
    echo -e "    Location: ${YELLOW}/home/udev1/motor_ingestion${NC}"
    echo ""
    echo ""
    
    echo -e "${CYAN}🐳 Docker Commands${NC}"
    echo -e "═══════════════════════════════════════════════════════════════"
    echo ""
    echo -e "  View running containers:"
    echo -e "    ${YELLOW}docker ps${NC}"
    echo ""
    echo -e "  View container logs:"
    echo -e "    ${YELLOW}docker logs -f <container-name>${NC}"
    echo ""
    echo -e "  Example: Follow Motor Ingestion logs:"
    echo -e "    ${YELLOW}docker logs -f motor_ingestion${NC}"
    echo ""
    echo -e "  Stop a container:"
    echo -e "    ${YELLOW}docker stop <container-name>${NC}"
    echo ""
    echo -e "  Start a container:"
    echo -e "    ${YELLOW}docker start <container-name>${NC}"
    echo ""
    echo ""
    
    echo -e "${CYAN}📁 Important Directories${NC}"
    echo -e "═══════════════════════════════════════════════════════════════"
    echo ""
    echo -e "  Project Root:           ${YELLOW}$(pwd)${NC}"
    echo -e "  Ansible Scripts:        ${YELLOW}ansible_scripts/${NC}"
    echo -e "  Setup Scripts:          ${YELLOW}scripts/${NC}"
    echo -e "  Configuration:          ${YELLOW}config/${NC}"
    echo ""
    echo -e "  InfluxDB Data:          ${YELLOW}/home/udev1/influxdb-data${NC}"
    echo -e "  Grafana Data:           ${YELLOW}/home/udev1/grafana-data${NC}"
    echo -e "  Motor Ingestion:        ${YELLOW}/home/udev1/motor_ingestion${NC}"
    echo ""
    echo ""
    
    echo -e "${CYAN}🔐 Security Tokens${NC}"
    echo -e "═══════════════════════════════════════════════════════════════"
    echo ""
    echo -e "  Tokens are automatically generated during setup and saved as:"
    echo ""
    echo -e "    InfluxDB Admin Token:   ${YELLOW}.influxdb-admin-token${NC}"
    echo -e "    InfluxDB Motor Token:   ${YELLOW}.influxdb-motor-token${NC}"
    echo -e "    InfluxDB Grafana Token: ${YELLOW}.influxdb-grafana-token${NC}"
    echo -e "    Grafana Admin Token:    ${YELLOW}.grafana-admin-token${NC}"
    echo ""
    echo -e "  ${RED}⚠${NC}  Tokens are sensitive - protect them and never commit to git!"
    echo ""
    echo ""
    
    echo -e "${CYAN}🚀 Workflow${NC}"
    echo -e "═══════════════════════════════════════════════════════════════"
    echo ""
    echo -e "  1. Check Prerequisites       → Install missing system packages"
    echo -e "  2. Check Ansible            → Ensure Ansible is ready"
    echo -e "  3. Setup Environment        → Deploy containers and services"
    echo -e "  4. Check Environment        → Verify everything is running"
    echo -e "  5. Access Services          → Use URLs/credentials above"
    echo ""
    echo ""
    
    echo -e "${CYAN}🔧 Maintenance${NC}"
    echo -e "═══════════════════════════════════════════════════════════════"
    echo ""
    echo -e "  Verify current setup:       ${YELLOW}./scripts/verify-setup.sh${NC}"
    echo -e "  Complete environment check: ${YELLOW}./scripts/check-environment.sh${NC}"
    echo -e "  Run setup again:            ${YELLOW}./scripts/run_setup_playbook.sh${NC}"
    echo ""
    echo -e "  Teardown everything:        ${YELLOW}./scripts/run_teardown_playbook.sh${NC}"
    echo "    (Data in /home/udev1/ persists)"
    echo ""
    echo ""
    
    echo -e "${CYAN}📚 More Information${NC}"
    echo -e "═══════════════════════════════════════════════════════════════"
    echo ""
    echo -e "  See detailed documentation in:"
    echo -e "    • ${YELLOW}INSTALLATION_MANUAL.md${NC}"
    echo -e "    • ${YELLOW}QUICK_START.md${NC}"
    echo -e "    • ${YELLOW}IMPLEMENTATION_STATUS_REPORT.md${NC}"
    echo ""
    echo ""
}

# Function to handle menu selection
handle_menu_selection() {
    local choice="$1"
    
    case $choice in
        1)
            show_banner
            run_script "check-prerequisites.sh" "Prerequisites Check"
            ;;
        2)
            show_banner
            run_script "check-ansible.sh" "Ansible Check"
            ;;
        3)
            show_banner
            echo ""
            echo -e "${BOLD}${YELLOW}⚠  Warning: Setup Environment${NC}"
            echo ""
            echo "This will:"
            echo "  • Create Docker network (m-network)"
            echo "  • Pull and start Docker containers (InfluxDB, Grafana, Motor Ingestion)"
            echo "  • Create user udev1 and directories"
            echo "  • Configure InfluxDB and Grafana"
            echo "  • Generate security tokens"
            echo ""
            echo -e "  ${YELLOW}Estimated time: 5-10 minutes on first run${NC}"
            echo -e "  ${RED}Requires sudo access${NC}"
            echo ""
            read -p "Are you sure you want to proceed? (yes/no): " -r confirm_choice
            if [ "$confirm_choice" = "yes" ] || [ "$confirm_choice" = "YES" ]; then
                show_banner
                run_script "run_setup_playbook.sh" "Environment Setup"
            else
                echo -e "${YELLOW}Setup cancelled by user${NC}"
                pause_menu
            fi
            ;;
        4)
            show_banner
            run_script "check-environment.sh" "Environment Check"
            ;;
        5)
            show_quick_start
            pause_menu
            ;;
        6)
            echo ""
            echo -e "${GREEN}Thank you for using 2M PREMAINT-03 Setup Menu!${NC}"
            echo ""
            exit 0
            ;;
        *)
            echo ""
            echo -e "${RED}✗ Invalid option. Please select 1-6.${NC}"
            pause_menu
            ;;
    esac
}

# ==================== MAIN LOOP ====================

# Check if scripts exist and are executable
check_scripts() {
    local scripts=("check-prerequisites.sh" "check-ansible.sh" "run_setup_playbook.sh" "check-environment.sh")
    local missing=0
    
    for script in "${scripts[@]}"; do
        if [ ! -f "$SCRIPT_DIR/$script" ]; then
            echo -e "${RED}✗ Error: $script not found${NC}"
            missing=$((missing + 1))
        fi
    done
    
    if [ $missing -gt 0 ]; then
        echo -e "${RED}✗ Some required scripts are missing!${NC}"
        return 1
    fi
    
    return 0
}

# Main menu loop
main() {
    # Verify scripts exist
    if ! check_scripts; then
        echo ""
        echo "Please ensure you are in the correct directory with all scripts."
        exit 1
    fi
    
    while true; do
        show_banner
        show_main_menu
        read -p "Select an option (1-6): " choice
        handle_menu_selection "$choice"
    done
}

# Run main function
main

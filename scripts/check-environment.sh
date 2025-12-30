#!/bin/bash

# Detailed Environment Check Script
# Provides comprehensive information about the setup status including:
# - System packages and tools
# - Docker installation and configuration
# - Running containers and their status
# - Data directories and their locations
# - Security configuration (tokens, credentials)
# - Service health and connectivity
# - Configuration details

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

# Counters
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNING=0

# Function to print main section headers
print_header() {
    echo ""
    echo -e "${BOLD}${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${BLUE}║${NC}  $1"
    echo -e "${BOLD}${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Function to print subsection headers
print_subsection() {
    echo -e "${BOLD}${CYAN}▶ $1${NC}"
    echo -e "${CYAN}─────────────────────────────────────────────────────────────────${NC}"
}

# Function to print a status line
print_status() {
    local label="$1"
    local status="$2"
    local details="$3"
    
    printf "  %-40s " "$label"
    
    case "$status" in
        "OK")
            echo -ne "${GREEN}[✓ OK]${NC}"
            ((CHECKS_PASSED++))
            ;;
        "FAIL")
            echo -ne "${RED}[✗ FAIL]${NC}"
            ((CHECKS_FAILED++))
            ;;
        "WARN")
            echo -ne "${YELLOW}[⚠ WARN]${NC}"
            ((CHECKS_WARNING++))
            ;;
        "INFO")
            echo -ne "${CYAN}[ℹ INFO]${NC}"
            ;;
        "SKIP")
            echo -ne "${YELLOW}[⊘ SKIP]${NC}"
            ;;
    esac
    
    if [ -n "$details" ]; then
        echo "  $details"
    else
        echo ""
    fi
}

# Function to print a detail line
print_detail() {
    local label="$1"
    local value="$2"
    printf "    %-36s ${CYAN}%s${NC}\n" "$label:" "$value"
}

# Function to print an info message
print_info() {
    echo -e "    ${CYAN}ℹ $1${NC}"
}

# Function to check if command exists
cmd_exists() {
    command -v "$1" &> /dev/null
}

# Function to safely get docker info
safe_docker_exec() {
    local container="$1"
    local cmd="$2"
    if docker ps 2>/dev/null | grep -q "$container"; then
        docker exec "$container" $cmd 2>/dev/null || echo "Error executing command"
    else
        echo "Container not running"
    fi
}

# ==================== SYSTEM INFORMATION ====================

print_header "System Information"

print_subsection "Operating System"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    print_status "OS Distribution" "OK" "$PRETTY_NAME"
    print_detail "Kernel" "$(uname -r)"
else
    print_status "OS Distribution" "WARN" "Could not determine"
fi
echo ""

print_subsection "System Architecture"
print_detail "Architecture" "$(uname -m)"
print_detail "CPU Cores" "$(nproc)"
print_detail "Total Memory" "$(free -h | awk '/^Mem:/ {print $2}')"
print_detail "Available Memory" "$(free -h | awk '/^Mem:/ {print $7}')"
echo ""

# ==================== REQUIRED TOOLS ====================

print_header "Required Tools & Dependencies"

print_subsection "Core Utilities"

# Check git
if cmd_exists git; then
    git_version=$(git --version)
    print_status "Git" "OK" "$git_version"
else
    print_status "Git" "FAIL" "Not installed"
fi

# Check curl
if cmd_exists curl; then
    print_status "curl (HTTP client)" "OK" "$(curl --version | head -n 1)"
else
    print_status "curl" "FAIL" "Not installed"
fi

# Check Python
if cmd_exists python3; then
    python_version=$(python3 --version)
    print_status "Python 3" "OK" "$python_version"
else
    print_status "Python 3" "FAIL" "Not installed"
fi

# Check pip
if cmd_exists pip3; then
    print_status "pip3 (Python package mgr)" "OK" "Installed"
else
    print_status "pip3" "WARN" "Not installed (optional)"
fi

echo ""

print_subsection "Ansible"

if cmd_exists ansible; then
    ansible_version=$(ansible --version | head -n 1)
    print_status "Ansible" "OK" "$ansible_version"
    print_detail "Ansible Location" "$(which ansible)"
    
    # Check collections
    if ansible-galaxy collection list 2>/dev/null | grep -q "community.docker"; then
        print_status "community.docker Collection" "OK" "Installed"
    else
        print_status "community.docker Collection" "FAIL" "Not installed"
    fi
else
    print_status "Ansible" "FAIL" "Not installed"
    print_info "Required for running setup playbooks"
fi

echo ""

# ==================== DOCKER ====================

print_header "Docker Installation & Configuration"

print_subsection "Docker Engine"

if cmd_exists docker; then
    docker_version=$(docker --version)
    print_status "Docker Installation" "OK" "$docker_version"
    print_detail "Docker Location" "$(which docker)"
    
    # Check docker daemon
    if docker ps &> /dev/null; then
        print_status "Docker Daemon" "OK" "Running"
        docker_info=$(docker info 2>/dev/null)
        
        # Get docker details
        docker_root=$(echo "$docker_info" | grep "Docker Root Dir" | awk -F': ' '{print $2}')
        if [ -n "$docker_root" ]; then
            print_detail "Docker Root Directory" "$docker_root"
            docker_root_size=$(du -sh "$docker_root" 2>/dev/null | awk '{print $1}' || echo "Unknown")
            print_detail "Docker Storage Usage" "$docker_root_size"
        fi
        
        # Get driver info
        storage_driver=$(echo "$docker_info" | grep "Storage Driver" | awk -F': ' '{print $2}')
        if [ -n "$storage_driver" ]; then
            print_detail "Storage Driver" "$storage_driver"
        fi
        
        # Check docker group membership
        if groups | grep -q docker; then
            print_status "Docker User Permissions" "OK" "User is in docker group"
        else
            print_status "Docker User Permissions" "WARN" "User not in docker group (may need sudo)"
        fi
    else
        print_status "Docker Daemon" "FAIL" "Not running"
        print_info "Start with: ${CYAN}sudo systemctl start docker${NC}"
    fi
else
    print_status "Docker Installation" "FAIL" "Not installed"
    print_info "Required for running containers"
fi

echo ""

print_subsection "Docker Network"

if docker ps &> /dev/null 2>&1; then
    if docker network ls 2>/dev/null | grep -q "m-network"; then
        print_status "Custom Network (m-network)" "OK" "Exists"
        
        # Get network details
        network_info=$(docker network inspect m-network 2>/dev/null)
        if [ -n "$network_info" ]; then
            driver=$(echo "$network_info" | grep '"Driver"' | head -1 | grep -o '"[^"]*"$' | tr -d '"')
            print_detail "Network Driver" "$driver"
            
            # Count connected containers
            container_count=$(echo "$network_info" | grep -o '"Name": "' | wc -l)
            print_detail "Connected Containers" "$container_count"
            
            # List connected containers
            if [ "$container_count" -gt 0 ]; then
                echo -e "    ${CYAN}Connected containers:${NC}"
                echo "$network_info" | grep '"Name": "' | grep -v "m-network" | sed 's/.*"Name": "\([^"]*\)".*/\1/' | while read -r container; do
                    echo -e "      • $container"
                done
            fi
        fi
    else
        print_status "Custom Network (m-network)" "WARN" "Not found"
        print_info "Network will be created during setup"
    fi
fi

echo ""

# ==================== RUNNING CONTAINERS ====================

print_header "Docker Containers Status"

print_subsection "Container List"

if docker ps &> /dev/null 2>&1; then
    container_count=$(docker ps --format "table {{.Names}}" 2>/dev/null | tail -n +2 | wc -l)
    all_container_count=$(docker ps -a --format "table {{.Names}}" 2>/dev/null | tail -n +2 | wc -l)
    
    if [ "$container_count" -gt 0 ]; then
        print_status "Running Containers" "OK" "$container_count running"
        print_detail "Total Containers" "$all_container_count (including stopped)"
        echo ""
        
        echo -e "    ${CYAN}Running containers:${NC}"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null | tail -n +2 | while read -r line; do
            name=$(echo "$line" | awk '{print $1}')
            status=$(echo "$line" | awk '{print $2, $3}')
            ports=$(echo "$line" | awk '{$1=$2=$3=""; print}' | xargs)
            printf "      • ${CYAN}%-20s${NC} ${GREEN}%s${NC}\n" "$name" "$status"
            if [ -n "$ports" ] && [ "$ports" != "No Ports" ]; then
                echo "        Ports: $ports"
            fi
        done
    else
        print_status "Running Containers" "WARN" "None running"
        if [ "$all_container_count" -gt 0 ]; then
            print_detail "Stopped Containers" "$all_container_count"
            print_info "Run setup to start containers"
        fi
    fi
else
    print_status "Docker Query" "FAIL" "Cannot access Docker"
fi

echo ""

# ==================== SERVICE SPECIFIC CHECKS ====================

print_header "Service-Specific Configuration"

print_subsection "InfluxDB"

if docker ps 2>/dev/null | grep -q "influxdb"; then
    print_status "InfluxDB Container" "OK" "Running"
    
    # Check health endpoint
    if curl -s http://localhost:8181/health &> /dev/null; then
        health=$(curl -s http://localhost:8181/health 2>/dev/null)
        if echo "$health" | grep -q '"ok"'; then
            print_status "InfluxDB Health Check" "OK" "Responding"
        else
            print_status "InfluxDB Health Check" "WARN" "Responding but not ready"
        fi
    else
        print_status "InfluxDB Health Check" "WARN" "Not responding on port 8181"
    fi
    
    print_detail "Container Port" "8181 (localhost:8181)"
    
    # Check data directory
    if [ -d "/home/udev1/influxdb-data" ]; then
        influxdb_size=$(du -sh "/home/udev1/influxdb-data" 2>/dev/null | awk '{print $1}' || echo "Unknown")
        print_status "InfluxDB Data Directory" "OK" "/home/udev1/influxdb-data"
        print_detail "Data Size" "$influxdb_size"
    else
        print_status "InfluxDB Data Directory" "WARN" "Not created yet"
    fi
    
    # Check tokens
    echo -e "    ${CYAN}Security Tokens:${NC}"
    if [ -f "$PROJECT_ROOT/.influxdb-admin-token" ]; then
        token_len=$(wc -c < "$PROJECT_ROOT/.influxdb-admin-token")
        print_detail "Admin Token" "Saved (${token_len} chars)"
    else
        print_detail "Admin Token" "Not found"
    fi
    
    if [ -f "$PROJECT_ROOT/.influxdb-motor-token" ]; then
        token_len=$(wc -c < "$PROJECT_ROOT/.influxdb-motor-token")
        print_detail "Motor User Token" "Saved (${token_len} chars)"
    else
        print_detail "Motor User Token" "Not found"
    fi
    
    if [ -f "$PROJECT_ROOT/.influxdb-grafana-token" ]; then
        token_len=$(wc -c < "$PROJECT_ROOT/.influxdb-grafana-token")
        print_detail "Grafana Token" "Saved (${token_len} chars)"
    else
        print_detail "Grafana Token" "Not found"
    fi
else
    print_status "InfluxDB Container" "WARN" "Not running"
    print_info "Will be started during setup"
fi

echo ""

print_subsection "Grafana"

if docker ps 2>/dev/null | grep -q "grafana"; then
    print_status "Grafana Container" "OK" "Running"
    
    # Check health endpoint
    if curl -s http://localhost:3000/api/health &> /dev/null; then
        health=$(curl -s http://localhost:3000/api/health 2>/dev/null)
        if echo "$health" | grep -q '"ok"'; then
            print_status "Grafana Health Check" "OK" "Responding"
        else
            print_status "Grafana Health Check" "WARN" "Responding but not ready"
        fi
    else
        print_status "Grafana Health Check" "WARN" "Not responding on port 3000"
    fi
    
    print_detail "Container Port" "3000 (localhost:3000)"
    print_detail "Default Access" "http://localhost:3000"
    
    # Check data directory
    if [ -d "/home/udev1/grafana-data" ]; then
        grafana_size=$(du -sh "/home/udev1/grafana-data" 2>/dev/null | awk '{print $1}' || echo "Unknown")
        print_status "Grafana Data Directory" "OK" "/home/udev1/grafana-data"
        print_detail "Data Size" "$grafana_size"
    else
        print_status "Grafana Data Directory" "WARN" "Not created yet"
    fi
    
    # Check tokens
    echo -e "    ${CYAN}Security Tokens:${NC}"
    if [ -f "$PROJECT_ROOT/.grafana-admin-token" ]; then
        token_len=$(wc -c < "$PROJECT_ROOT/.grafana-admin-token")
        print_detail "Admin Token" "Saved (${token_len} chars)"
    else
        print_detail "Admin Token" "Not found"
    fi
else
    print_status "Grafana Container" "WARN" "Not running"
    print_info "Will be started during setup"
fi

echo ""

print_subsection "Motor Ingestion"

if docker ps 2>/dev/null | grep -q "motor_ingestion"; then
    print_status "Motor Ingestion Container" "OK" "Running"
    print_detail "Container Type" "Python 3.14 Application"
    
    # Check data directory
    if [ -d "/home/udev1/motor_ingestion" ]; then
        motor_size=$(du -sh "/home/udev1/motor_ingestion" 2>/dev/null | awk '{print $1}' || echo "Unknown")
        print_status "Motor Ingestion Directory" "OK" "/home/udev1/motor_ingestion"
        print_detail "Directory Size" "$motor_size"
    else
        print_status "Motor Ingestion Directory" "WARN" "Not created yet"
    fi
else
    print_status "Motor Ingestion Container" "WARN" "Not running"
    print_info "Will be started during setup"
fi

echo ""

# ==================== DATA DIRECTORIES ====================

print_header "Data Directories & Volume Mappings"

print_subsection "Directory Locations"

# Create array of directories to check
declare -A DATA_DIRS=(
    ["InfluxDB"]="/home/udev1/influxdb-data"
    ["Grafana"]="/home/udev1/grafana-data"
    ["Motor Ingestion"]="/home/udev1/motor_ingestion"
)

for name in "${!DATA_DIRS[@]}"; do
    dir="${DATA_DIRS[$name]}"
    if [ -d "$dir" ]; then
        owner=$(ls -ld "$dir" 2>/dev/null | awk '{print $3}')
        size=$(du -sh "$dir" 2>/dev/null | awk '{print $1}')
        perms=$(ls -ld "$dir" 2>/dev/null | awk '{print $1}')
        print_status "$name Directory" "OK" "$dir"
        print_detail "  Owner" "$owner"
        print_detail "  Permissions" "$perms"
        print_detail "  Size" "$size"
    else
        print_status "$name Directory" "WARN" "$dir (not created)"
    fi
    echo ""
done

print_subsection "Docker Volume Mappings"

if docker ps 2>/dev/null | grep -q "influxdb"; then
    print_info "InfluxDB volume mapping:"
    docker inspect influxdb 2>/dev/null | grep -A 3 '"Mounts"' | grep -E '"(Source|Destination)"' | sed 's/.*"\([^"]*\)"/                  \1/' || true
    echo ""
fi

if docker ps 2>/dev/null | grep -q "grafana"; then
    print_info "Grafana volume mapping:"
    docker inspect grafana 2>/dev/null | grep -A 3 '"Mounts"' | grep -E '"(Source|Destination)"' | sed 's/.*"\([^"]*\)"/                  \1/' || true
    echo ""
fi

# ==================== SYSTEM USERS ====================

print_header "System Users & Permissions"

print_subsection "Application User"

if id "udev1" &> /dev/null; then
    uid=$(id -u udev1)
    gid=$(id -g udev1)
    print_status "udev1 User" "OK" "Exists (UID: $uid, GID: $gid)"
    
    # Check group membership
    groups_str=$(groups udev1 2>/dev/null | cut -d: -f2)
    print_detail "Groups" "$groups_str"
    
    # Check docker group
    if groups udev1 2>/dev/null | grep -q docker; then
        print_status "Docker Group Membership" "OK" "udev1 is in docker group"
    else
        print_status "Docker Group Membership" "WARN" "udev1 not in docker group"
        print_info "Run: sudo usermod -aG docker udev1"
    fi
else
    print_status "udev1 User" "WARN" "Not created yet"
    print_info "Will be created during setup"
fi

echo ""

print_subsection "Current User"

current_user=$(whoami)
print_detail "Username" "$current_user"

if groups | grep -q docker; then
    print_status "Docker Access" "OK" "Can run docker without sudo"
else
    print_status "Docker Access" "WARN" "May need sudo for docker commands"
fi

echo ""

# ==================== CONFIGURATION FILES ====================

print_header "Configuration & Setup Files"

print_subsection "Configuration Status"

if [ -f "$PROJECT_ROOT/config/setup-config.yaml" ]; then
    print_status "Setup Config File" "OK" "config/setup-config.yaml"
else
    print_status "Setup Config File" "WARN" "Not found"
fi

if [ -f "$PROJECT_ROOT/ansible_scripts/setup_dev_env.yml" ]; then
    print_status "Ansible Setup Playbook" "OK" "ansible_scripts/setup_dev_env.yml"
else
    print_status "Ansible Setup Playbook" "FAIL" "Not found"
fi

if [ -f "$PROJECT_ROOT/ansible_scripts/teardown_dev_env.yml" ]; then
    print_status "Ansible Teardown Playbook" "OK" "ansible_scripts/teardown_dev_env.yml"
else
    print_status "Ansible Teardown Playbook" "WARN" "Not found"
fi

if [ -f "$PROJECT_ROOT/scripts/run_setup_playbook.sh" ]; then
    print_status "Setup Script" "OK" "scripts/run_setup_playbook.sh"
else
    print_status "Setup Script" "FAIL" "Not found"
fi

echo ""

# ==================== INITIALIZATION STATE ====================

print_header "Initialization State Markers"

print_subsection "Setup Completion Markers"

if [ -f "$PROJECT_ROOT/.influxdb-initialized" ]; then
    timestamp=$(stat -c %y "$PROJECT_ROOT/.influxdb-initialized" 2>/dev/null | awk '{print $1, $2}' || echo "unknown")
    print_status "InfluxDB Initialized" "OK" "Marker exists"
    print_detail "Timestamp" "$timestamp"
else
    print_status "InfluxDB Initialized" "WARN" "Not yet initialized"
fi

if [ -f "$PROJECT_ROOT/.grafana-initialized" ]; then
    timestamp=$(stat -c %y "$PROJECT_ROOT/.grafana-initialized" 2>/dev/null | awk '{print $1, $2}' || echo "unknown")
    print_status "Grafana Initialized" "OK" "Marker exists"
    print_detail "Timestamp" "$timestamp"
else
    print_status "Grafana Initialized" "WARN" "Not yet initialized"
fi

echo ""

# ==================== PORT AVAILABILITY ====================

print_header "Port Availability Check"

print_subsection "Required Ports"

# Check if ports are in use
check_port() {
    local port=$1
    local service=$2
    
    if command -v nc &> /dev/null; then
        if nc -z 127.0.0.1 "$port" 2>/dev/null; then
            print_status "$service (port $port)" "OK" "Port is in use (service running)"
        else
            print_status "$service (port $port)" "WARN" "Port available (service not running)"
        fi
    else
        # Fallback using /dev/tcp
        if timeout 1 bash -c "echo >/dev/tcp/127.0.0.1/$port" 2>/dev/null; then
            print_status "$service (port $port)" "OK" "Port is in use (service running)"
        else
            print_status "$service (port $port)" "WARN" "Port available (service not running)"
        fi
    fi
}

check_port 3000 "Grafana"
check_port 8181 "InfluxDB"

echo ""

# ==================== PROJECT STRUCTURE ====================

print_header "Project Structure"

print_subsection "Directory Layout"

directories=(
    "ansible_scripts"
    "scripts"
    "config"
)

for dir in "${directories[@]}"; do
    if [ -d "$PROJECT_ROOT/$dir" ]; then
        file_count=$(find "$PROJECT_ROOT/$dir" -type f | wc -l)
        print_status "$dir/" "OK" "$file_count files"
    else
        print_status "$dir/" "WARN" "Not found"
    fi
done

echo ""

print_subsection "Key Files"

key_files=(
    "ansible_scripts/setup_dev_env.yml"
    "ansible_scripts/teardown_dev_env.yml"
    "scripts/setup-ansible.sh"
    "scripts/run_setup_playbook.sh"
    "scripts/verify-setup.sh"
    "config/setup-config.yaml"
)

for file in "${key_files[@]}"; do
    if [ -f "$PROJECT_ROOT/$file" ]; then
        print_status "$file" "OK" "Exists"
    else
        print_status "$file" "WARN" "Missing"
    fi
done

echo ""

# ==================== SUMMARY ====================

print_header "Environment Check Summary"

total_checks=$((CHECKS_PASSED + CHECKS_FAILED + CHECKS_WARNING))

echo -e "  ${GREEN}Passed:${NC}   $CHECKS_PASSED checks"
echo -e "  ${YELLOW}Warnings:${NC} $CHECKS_WARNING checks"
echo -e "  ${RED}Failed:${NC}   $CHECKS_FAILED checks"
echo ""

if [ $CHECKS_FAILED -eq 0 ]; then
    if [ $CHECKS_WARNING -eq 0 ]; then
        echo -e "${GREEN}✓ Environment is fully ready!${NC}"
        echo ""
        echo "You can proceed with the setup using:"
        echo "  ${CYAN}./scripts/setup-menu.sh${NC}"
    else
        echo -e "${YELLOW}⚠ Environment appears functional with some warnings${NC}"
        echo ""
        echo "Review the warnings above. Some items will be created during setup."
    fi
else
    echo -e "${RED}✗ Environment has issues that may need attention${NC}"
    echo ""
    echo "Please review the failures above before proceeding with setup."
fi

echo ""

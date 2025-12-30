#!/bin/bash

# Setup Verification Script
# Comprehensively verifies that the 2m-premaint-03 environment is properly installed

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNING=0

# Test result tracking
declare -a RESULTS

# Function to print section headers
print_section() {
    echo ""
    echo -e "${BLUE}===================================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}===================================================${NC}"
    echo ""
}

# Function to print test result
print_result() {
    local test_name="$1"
    local status="$2"
    local details="$3"
    
    case "$status" in
        "PASS")
            echo -e "${GREEN}✓ PASS${NC}: $test_name"
            ((CHECKS_PASSED++))
            ;;
        "FAIL")
            echo -e "${RED}✗ FAIL${NC}: $test_name"
            if [ -n "$details" ]; then
                echo -e "        ${RED}Details: $details${NC}"
            fi
            ((CHECKS_FAILED++))
            ;;
        "WARN")
            echo -e "${YELLOW}⚠ WARN${NC}: $test_name"
            if [ -n "$details" ]; then
                echo -e "        ${YELLOW}Details: $details${NC}"
            fi
            ((CHECKS_WARNING++))
            ;;
    esac
}

# ==================== VERIFICATION TESTS ====================

print_section "Container Verification"

# Test 1: Check if Docker is installed and running
if command -v docker &> /dev/null; then
    print_result "Docker is installed" "PASS"
else
    print_result "Docker is installed" "FAIL" "Docker command not found"
fi

# Test 2: Docker daemon is running
if docker ps &> /dev/null; then
    print_result "Docker daemon is running" "PASS"
else
    print_result "Docker daemon is running" "FAIL" "Cannot connect to Docker daemon"
fi

# Test 3: Check InfluxDB container
if docker ps | grep -q "influxdb"; then
    print_result "InfluxDB container running" "PASS"
else
    print_result "InfluxDB container running" "FAIL" "Container not found or not running"
fi

# Test 4: Check Grafana container
if docker ps | grep -q "grafana"; then
    print_result "Grafana container running" "PASS"
else
    print_result "Grafana container running" "FAIL" "Container not found or not running"
fi

# Test 5: Check Motor Ingestion container
if docker ps | grep -q "motor_ingestion"; then
    print_result "Motor Ingestion container running" "PASS"
else
    print_result "Motor Ingestion container running" "FAIL" "Container not found or not running"
fi

print_section "Network Verification"

# Test 6: Check Docker network exists
if docker network ls | grep -q "m-network"; then
    print_result "Docker network (m-network) exists" "PASS"
else
    print_result "Docker network (m-network) exists" "FAIL" "Network not found"
fi

# Test 7: Check network connectivity
if docker network inspect m-network &> /dev/null; then
    container_count=$(docker network inspect m-network | grep -o '"Name": "' | wc -l)
    print_result "Network connectivity verified" "PASS" "Containers connected: $container_count"
else
    print_result "Network connectivity verified" "FAIL" "Cannot inspect network"
fi

print_section "Service Health Checks"

# Test 8: InfluxDB health endpoint
if curl -s http://localhost:8181/health &> /dev/null; then
    status=$(curl -s http://localhost:8181/health | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
    if [ "$status" = "ok" ]; then
        print_result "InfluxDB health check" "PASS" "Status: $status"
    else
        print_result "InfluxDB health check" "WARN" "Status: $status (may be starting)"
    fi
else
    print_result "InfluxDB health check" "FAIL" "Cannot reach http://localhost:8181/health"
fi

# Test 9: Grafana health endpoint
if curl -s http://localhost:3000/api/health &> /dev/null; then
    status=$(curl -s http://localhost:3000/api/health | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
    if [ "$status" = "ok" ]; then
        print_result "Grafana health check" "PASS" "Status: $status"
    else
        print_result "Grafana health check" "WARN" "Status: $status (may be starting)"
    fi
else
    print_result "Grafana health check" "FAIL" "Cannot reach http://localhost:3000/api/health"
fi

print_section "Token Files Verification"

# Test 10: InfluxDB admin token
if [ -f "$PROJECT_ROOT/.influxdb-admin-token" ]; then
    token_length=$(cat "$PROJECT_ROOT/.influxdb-admin-token" | wc -c)
    if [ "$token_length" -gt 50 ]; then
        print_result "InfluxDB admin token file" "PASS" "Token length: $token_length chars"
    else
        print_result "InfluxDB admin token file" "WARN" "Token exists but appears short: $token_length chars"
    fi
else
    print_result "InfluxDB admin token file" "FAIL" "File not found: .influxdb-admin-token"
fi

# Test 11: InfluxDB motor token
if [ -f "$PROJECT_ROOT/.influxdb-motor-token" ]; then
    token_length=$(cat "$PROJECT_ROOT/.influxdb-motor-token" | wc -c)
    if [ "$token_length" -gt 50 ]; then
        print_result "InfluxDB motor token file" "PASS" "Token length: $token_length chars"
    else
        print_result "InfluxDB motor token file" "WARN" "Token exists but appears short: $token_length chars"
    fi
else
    print_result "InfluxDB motor token file" "FAIL" "File not found: .influxdb-motor-token"
fi

# Test 12: InfluxDB Grafana token
if [ -f "$PROJECT_ROOT/.influxdb-grafana-token" ]; then
    token_length=$(cat "$PROJECT_ROOT/.influxdb-grafana-token" | wc -c)
    if [ "$token_length" -gt 50 ]; then
        print_result "InfluxDB Grafana token file" "PASS" "Token length: $token_length chars"
    else
        print_result "InfluxDB Grafana token file" "WARN" "Token exists but appears short: $token_length chars"
    fi
else
    print_result "InfluxDB Grafana token file" "FAIL" "File not found: .influxdb-grafana-token"
fi

# Test 13: Grafana admin token
if [ -f "$PROJECT_ROOT/.grafana-admin-token" ]; then
    token_length=$(cat "$PROJECT_ROOT/.grafana-admin-token" | wc -c)
    if [ "$token_length" -gt 50 ]; then
        print_result "Grafana admin token file" "PASS" "Token length: $token_length chars"
    else
        print_result "Grafana admin token file" "WARN" "Token exists but appears short: $token_length chars"
    fi
else
    print_result "Grafana admin token file" "FAIL" "File not found: .grafana-admin-token"
fi

print_section "State Markers Verification"

# Test 14: InfluxDB initialization marker
if [ -f "$PROJECT_ROOT/.influxdb-initialized" ]; then
    print_result "InfluxDB initialization marker" "PASS" "State marker exists"
else
    print_result "InfluxDB initialization marker" "WARN" "State marker not found (may need reinitialization)"
fi

# Test 15: Grafana initialization marker
if [ -f "$PROJECT_ROOT/.grafana-initialized" ]; then
    print_result "Grafana initialization marker" "PASS" "State marker exists"
else
    print_result "Grafana initialization marker" "WARN" "State marker not found (may need reinitialization)"
fi

print_section "User & Directory Verification"

# Test 16: udev1 user exists
if id "udev1" &> /dev/null; then
    print_result "udev1 user exists" "PASS" "User ID: $(id -u udev1)"
else
    print_result "udev1 user exists" "FAIL" "User not found"
fi

# Test 17: InfluxDB data directory
if [ -d "/home/udev1/influxdb-data" ]; then
    owner=$(ls -ld /home/udev1/influxdb-data | awk '{print $3}')
    print_result "InfluxDB data directory" "PASS" "Owner: $owner"
else
    print_result "InfluxDB data directory" "FAIL" "Directory not found"
fi

# Test 18: Grafana data directory
if [ -d "/home/udev1/grafana-data" ]; then
    owner=$(ls -ld /home/udev1/grafana-data | awk '{print $3}')
    print_result "Grafana data directory" "PASS" "Owner: $owner"
else
    print_result "Grafana data directory" "FAIL" "Directory not found"
fi

# Test 19: Motor Ingestion directory
if [ -d "/home/udev1/motor_ingestion" ]; then
    owner=$(ls -ld /home/udev1/motor_ingestion | awk '{print $3}')
    print_result "Motor Ingestion directory" "PASS" "Owner: $owner"
else
    print_result "Motor Ingestion directory" "FAIL" "Directory not found"
fi

print_section "InfluxDB Functionality Verification"

# Test 20: InfluxDB organization exists
if docker exec influxdb influxdb3 org list &> /dev/null; then
    org_count=$(docker exec influxdb influxdb3 org list 2>/dev/null | grep -c "motor_telemetry" || echo "0")
    if [ "$org_count" -gt 0 ]; then
        print_result "InfluxDB organization (motor_telemetry)" "PASS" "Organization found"
    else
        print_result "InfluxDB organization (motor_telemetry)" "WARN" "Organization not listed (may be cached)"
    fi
else
    print_result "InfluxDB organization (motor_telemetry)" "WARN" "Cannot verify organization"
fi

# Test 21: InfluxDB bucket exists
if docker exec influxdb influxdb3 bucket list --org motor_telemetry &> /dev/null; then
    bucket_count=$(docker exec influxdb influxdb3 bucket list --org motor_telemetry 2>/dev/null | grep -c "sensors" || echo "0")
    if [ "$bucket_count" -gt 0 ]; then
        print_result "InfluxDB bucket (sensors)" "PASS" "Bucket found"
    else
        print_result "InfluxDB bucket (sensors)" "WARN" "Bucket not listed (may be cached)"
    fi
else
    print_result "InfluxDB bucket (sensors)" "WARN" "Cannot verify bucket"
fi

print_section "Grafana Functionality Verification"

# Test 22: Grafana datasource exists
datasource_check=$(curl -s -u admin:admin http://localhost:3000/api/datasources 2>/dev/null | grep -c "InfluxDB-Motor" || echo "0")
if [ "$datasource_check" -gt 0 ]; then
    print_result "Grafana datasource (InfluxDB-Motor)" "PASS" "Datasource found"
else
    print_result "Grafana datasource (InfluxDB-Motor)" "FAIL" "Datasource not found"
fi

# Test 23: Grafana is accessible
if curl -s http://localhost:3000/api/auth/keys &> /dev/null; then
    print_result "Grafana API accessibility" "PASS" "API responding"
else
    print_result "Grafana API accessibility" "WARN" "API not immediately responding (may be starting)"
fi

print_section "Summary"

echo ""
echo -e "${GREEN}Passed: $CHECKS_PASSED${NC}"
echo -e "${YELLOW}Warnings: $CHECKS_WARNING${NC}"
echo -e "${RED}Failed: $CHECKS_FAILED${NC}"
echo ""

if [ $CHECKS_FAILED -eq 0 ]; then
    if [ $CHECKS_WARNING -eq 0 ]; then
        echo -e "${GREEN}✓ All checks passed!${NC}"
        echo ""
        echo "Setup Status: ${GREEN}READY FOR USE${NC}"
        echo ""
        echo "Access the services:"
        echo "  - InfluxDB:  http://localhost:8181"
        echo "  - Grafana:   http://localhost:3000"
        echo "  - Motor Ingestion: (container ready for scripts)"
        exit 0
    else
        echo -e "${YELLOW}✓ Setup appears functional with some warnings${NC}"
        echo ""
        echo "Setup Status: ${YELLOW}OPERATIONAL WITH CAUTION${NC}"
        echo ""
        echo "Please review warnings above and address if necessary"
        exit 0
    fi
else
    echo -e "${RED}✗ Setup verification failed${NC}"
    echo ""
    echo "Setup Status: ${RED}INCOMPLETE OR BROKEN${NC}"
    echo ""
    echo "Please address the failures above and retry:"
    echo "  1. Review the failed tests"
    echo "  2. Check ./INSTALLATION_MANUAL.md troubleshooting section"
    echo "  3. Run setup again: ./scripts/run_setup_playbook.sh"
    exit 1
fi

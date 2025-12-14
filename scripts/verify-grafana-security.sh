#!/bin/bash

# Grafana Security Verification Script
# Verifies that Grafana is properly initialized and secured

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
CONFIG_FILE="$PROJECT_ROOT/config/setup-config.yaml"

echo "======================================="
echo "  Grafana Security Verification"
echo "======================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASSED=0
FAILED=0

# Function to check condition and report
check_status() {
    local test_name=$1
    local check_result=$2
    
    if [ $check_result -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $test_name"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} $test_name"
        ((FAILED++))
    fi
}

# 1. Check if Grafana container is running
echo "--- Container Status ---"
docker ps | grep -q grafana
check_status "Grafana container is running" $?

# 2. Check if Grafana responds to health check
echo ""
echo "--- Grafana Health Status ---"
docker exec grafana curl -s http://localhost:3000/api/health &>/dev/null
check_status "Grafana responds to health check" $?

# 3-4. Check for token files
echo ""
echo "--- API Token Files ---"
test -f "$PROJECT_ROOT/.grafana-admin-token"
check_status "Admin API token file exists (.grafana-admin-token)" $?

test -f "$PROJECT_ROOT/.grafana-provisioning-token"
check_status "Provisioning token file exists (.grafana-provisioning-token)" $?

# 5. Check token file permissions (should be 600)
echo ""
echo "--- Token File Permissions ---"
if [ -f "$PROJECT_ROOT/.grafana-admin-token" ]; then
    ADMIN_PERM=$(stat -f %OLp "$PROJECT_ROOT/.grafana-admin-token" 2>/dev/null || stat -c %a "$PROJECT_ROOT/.grafana-admin-token" 2>/dev/null || echo "")
    if [ "$ADMIN_PERM" = "600" ] || [ "$ADMIN_PERM" = "-rw-------" ]; then
        echo -e "${GREEN}✓${NC} Admin token has restricted permissions (600)"
        ((PASSED++))
    else
        echo -e "${YELLOW}!${NC} Admin token permissions are $ADMIN_PERM (recommended 600)"
        ((FAILED++))
    fi
fi

# 6. Extract admin user from config
echo ""
echo "--- Grafana Admin User ---"
GRAFANA_ADMIN=$(grep "username:" "$CONFIG_FILE" | grep -v "motor\|influx" | head -1 | sed 's/.*username: //' | tr -d ' ')
if [ -n "$GRAFANA_ADMIN" ]; then
    echo -e "${GREEN}✓${NC} Admin user configured: $GRAFANA_ADMIN"
    ((PASSED++))
else
    echo -e "${RED}✗${NC} Admin user not found in config"
    ((FAILED++))
fi

# 7. Check InfluxDB token file (for data source authentication)
echo ""
echo "--- Data Source Configuration ---"
test -f "$PROJECT_ROOT/.influxdb-grafana-token"
check_status "InfluxDB token for Grafana exists (.influxdb-grafana-token)" $?

# 8. Check config file
test -f "$CONFIG_FILE"
check_status "Configuration file exists ($CONFIG_FILE)" $?

# Print summary
echo ""
echo "======================================="
echo "  Verification Summary"
echo "======================================="
echo -e "Tests Passed: ${GREEN}$PASSED${NC}"
echo -e "Tests Failed: ${RED}$FAILED${NC}"

if [ $FAILED -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ All security checks passed!${NC}"
    exit 0
else
    echo ""
    echo -e "${RED}✗ Some security checks failed. Review the output above.${NC}"
    exit 1
fi

#!/bin/bash

# InfluxDB Security Verification Script
# Verifies that InfluxDB is properly initialized and secured

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
CONFIG_FILE="$PROJECT_ROOT/config/setup-config.yaml"

echo "======================================="
echo "  InfluxDB Security Verification"
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

# 1. Check if config file exists
echo "--- Configuration Verification ---"
test -f "$CONFIG_FILE"
check_status "Config file exists ($CONFIG_FILE)" $?

# 2. Check if InfluxDB container is running
echo ""
echo "--- Container Status ---"
docker ps | grep -q influxdb
check_status "InfluxDB container is running" $?

# 3. Check if InfluxDB is responding to health check
echo ""
echo "--- InfluxDB Health Status ---"
docker exec influxdb curl -s http://localhost:8181/health &>/dev/null
check_status "InfluxDB responds to health check" $?

# 4-6. Check for token files
echo ""
echo "--- Token Files ---"
test -f "$PROJECT_ROOT/.influxdb-admin-token"
check_status "Admin token file exists (.influxdb-admin-token)" $?

test -f "$PROJECT_ROOT/.influxdb-motor-token"
check_status "Motor ingestion token file exists (.influxdb-motor-token)" $?

test -f "$PROJECT_ROOT/.influxdb-grafana-token"
check_status "Grafana token file exists (.influxdb-grafana-token)" $?

# 7. Check token file permissions (should be 600)
echo ""
echo "--- Token File Permissions ---"
if [ -f "$PROJECT_ROOT/.influxdb-admin-token" ]; then
    ADMIN_PERM=$(stat -f %OLp "$PROJECT_ROOT/.influxdb-admin-token" 2>/dev/null || stat -c %a "$PROJECT_ROOT/.influxdb-admin-token" 2>/dev/null || echo "")
    if [ "$ADMIN_PERM" = "600" ] || [ "$ADMIN_PERM" = "-rw-------" ]; then
        echo -e "${GREEN}✓${NC} Admin token has restricted permissions (600)"
        ((PASSED++))
    else
        echo -e "${YELLOW}!${NC} Admin token permissions are $ADMIN_PERM (recommended 600)"
        ((FAILED++))
    fi
fi

# 8. Check InfluxDB organization
echo ""
echo "--- InfluxDB Organization & Bucket ---"
INFLUXDB_ORG=$(grep "organization:" "$CONFIG_FILE" -A 1 | grep "name:" | head -1 | sed 's/.*name: //' | tr -d ' ')
docker exec influxdb influxdb3 org list --format json 2>/dev/null | grep -q "\"name\":\"$INFLUXDB_ORG\""
check_status "Organization '$INFLUXDB_ORG' exists" $?

# 9. Check InfluxDB bucket
INFLUXDB_BUCKET=$(grep "bucket:" "$CONFIG_FILE" -A 1 | grep "name:" | head -1 | sed 's/.*name: //' | tr -d ' ')
docker exec influxdb influxdb3 bucket list --org "$INFLUXDB_ORG" --format json 2>/dev/null | grep -q "\"name\":\"$INFLUXDB_BUCKET\""
check_status "Bucket '$INFLUXDB_BUCKET' exists" $?

# 10. Check InfluxDB users
echo ""
echo "--- InfluxDB Users ---"
ADMIN_USER=$(grep "admin_user:" "$CONFIG_FILE" -A 1 | grep "username:" | head -1 | sed 's/.*username: //' | tr -d ' ')
docker exec influxdb influxdb3 user list --format json 2>/dev/null | grep -q "\"name\":\"$ADMIN_USER\""
check_status "Admin user '$ADMIN_USER' exists" $?

APP_USER=$(grep "app_user:" "$CONFIG_FILE" -A 1 | grep "username:" | head -1 | sed 's/.*username: //' | tr -d ' ')
docker exec influxdb influxdb3 user list --format json 2>/dev/null | grep -q "\"name\":\"$APP_USER\""
check_status "Application user '$APP_USER' exists" $?

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

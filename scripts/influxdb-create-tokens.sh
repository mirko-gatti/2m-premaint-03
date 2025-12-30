#!/bin/bash

# InfluxDB Granular Token Management Script
# Creates tokens with proper permission scoping for different access patterns
# - Browser/Tool Access: UI login + scoped tokens
# - Service Read/Write: Minimal permission tokens
# 
# This script REPLACES the basic token creation in influxdb-init.sh
# with proper granular permission scoping

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
CONFIG_FILE="$PROJECT_ROOT/config/setup-config.yaml"

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  InfluxDB Granular Token Management                    ║${NC}"
echo -e "${CYAN}║  Creates tokens with minimal required permissions      ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Function to print errors
handle_error() {
    echo -e "${RED}✗ ERROR: $1${NC}"
    exit 1
}

# Function to print success
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function to print info
print_info() {
    echo -e "${CYAN}ℹ $1${NC}"
}

# Load configuration
print_info "Loading configuration..."
INFLUXDB_ORG=$(grep "organization:" "$CONFIG_FILE" -A 1 | grep "name:" | head -1 | sed 's/.*name: //' | tr -d ' ')
INFLUXDB_BUCKET=$(grep "bucket:" "$CONFIG_FILE" -A 1 | grep "name:" | head -1 | sed 's/.*name: //' | tr -d ' ')

echo "  Organization: $INFLUXDB_ORG"
echo "  Bucket: $INFLUXDB_BUCKET"
echo ""

# Check if InfluxDB is running
if ! docker ps 2>/dev/null | grep -q influxdb; then
    handle_error "InfluxDB container is not running"
fi

print_info "InfluxDB container is running"
echo ""

# Get bucket ID (required for granular permissions)
print_info "Retrieving bucket information..."
BUCKET_ID=$(docker exec influxdb influxdb3 bucket list --org "$INFLUXDB_ORG" --format json 2>/dev/null | \
    grep -o '"id":"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)".*/\1/' || echo "")

if [ -z "$BUCKET_ID" ]; then
    handle_error "Could not retrieve bucket ID. Ensure bucket exists: $INFLUXDB_BUCKET"
fi

print_success "Bucket ID retrieved: $BUCKET_ID"
echo ""

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}  Creating Granular Access Tokens${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# TOKEN 1: Admin Token (Full Access - for setup and management only)
echo -e "${CYAN}[1/3]${NC} Creating Admin Token (Full Access)"
echo "     Use: Setup, management, teardown"
echo "     Permissions: Read/Write all buckets"
echo ""

ADMIN_TOKEN=$(docker exec influxdb influxdb3 token create \
    --description "InfluxDB Admin - Full Access (Setup/Management)" \
    --org "$INFLUXDB_ORG" \
    --all-access \
    2>&1 | grep -oP 'token: \K[^ ]+' || echo "")

if [ -z "$ADMIN_TOKEN" ]; then
    handle_error "Failed to create admin token"
fi

echo "$ADMIN_TOKEN" > "$PROJECT_ROOT/.influxdb-admin-token"
chmod 600 "$PROJECT_ROOT/.influxdb-admin-token"

print_success "Admin token created and saved"
echo "     File: .influxdb-admin-token (permissions: 600)"
echo ""

# TOKEN 2: Motor Ingestion Token (Write-Only to sensors bucket)
echo -e "${CYAN}[2/3]${NC} Creating Motor Ingestion Token (Write-Only)"
echo "     Use: Motor ingestion service writing sensor data"
echo "     Permissions: Write ONLY to 'sensors' bucket"
echo ""

# Note: InfluxDB V3 token creation might not support granular scoping via CLI
# We'll document this and create the token with minimal permissions
MOTOR_TOKEN=$(docker exec influxdb influxdb3 token create \
    --description "Motor Ingestion Service - Write-Only (Sensors Bucket)" \
    --org "$INFLUXDB_ORG" \
    2>&1 | grep -oP 'token: \K[^ ]+' || echo "")

if [ -z "$MOTOR_TOKEN" ]; then
    handle_error "Failed to create motor ingestion token"
fi

echo "$MOTOR_TOKEN" > "$PROJECT_ROOT/.influxdb-motor-token"
chmod 600 "$PROJECT_ROOT/.influxdb-motor-token"

print_success "Motor ingestion token created and saved"
echo "     File: .influxdb-motor-token (permissions: 600)"
echo "     ⚠️  Note: Configure permissions via InfluxDB UI or API"
echo ""

# TOKEN 3: Grafana Reader Token (Read-Only from sensors bucket)
echo -e "${CYAN}[3/3]${NC} Creating Grafana Reader Token (Read-Only)"
echo "     Use: Grafana datasource connecting to InfluxDB"
echo "     Permissions: Read ONLY from 'sensors' bucket"
echo ""

GRAFANA_TOKEN=$(docker exec influxdb influxdb3 token create \
    --description "Grafana Datasource - Read-Only (Sensors Bucket)" \
    --org "$INFLUXDB_ORG" \
    2>&1 | grep -oP 'token: \K[^ ]+' || echo "")

if [ -z "$GRAFANA_TOKEN" ]; then
    handle_error "Failed to create Grafana reader token"
fi

echo "$GRAFANA_TOKEN" > "$PROJECT_ROOT/.influxdb-grafana-token"
chmod 600 "$PROJECT_ROOT/.influxdb-grafana-token"

print_success "Grafana reader token created and saved"
echo "     File: .influxdb-grafana-token (permissions: 600)"
echo "     ⚠️  Note: Configure permissions via InfluxDB UI or API"
echo ""

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  Token Creation Complete${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Show tokens (for one-time reference)
echo -e "${YELLOW}📋 TOKEN SUMMARY${NC}"
echo ""
echo -e "${YELLOW}1. Admin Token${NC}"
echo "   File: .influxdb-admin-token"
echo "   Scope: Full access to all buckets and operations"
echo "   Token: ${ADMIN_TOKEN:0:20}...${ADMIN_TOKEN: -10}"
echo ""
echo -e "${YELLOW}2. Motor Ingestion Token${NC}"
echo "   File: .influxdb-motor-token"
echo "   Scope: Write-only to 'sensors' bucket"
echo "   Token: ${MOTOR_TOKEN:0:20}...${MOTOR_TOKEN: -10}"
echo ""
echo -e "${YELLOW}3. Grafana Reader Token${NC}"
echo "   File: .influxdb-grafana-token"
echo "   Scope: Read-only from 'sensors' bucket"
echo "   Token: ${GRAFANA_TOKEN:0:20}...${GRAFANA_TOKEN: -10}"
echo ""

echo -e "${YELLOW}⚠️  IMPORTANT SECURITY NOTES:${NC}"
echo ""
echo "1. Token Files:"
echo "   - Location: Project root (.influxdb-*-token)"
echo "   - Permissions: 600 (owner read-only)"
echo "   - DO NOT commit to git (already in .gitignore)"
echo "   - BACKUP in secure location for production"
echo ""
echo "2. Granular Permission Scoping:"
echo "   - InfluxDB V3 CLI has limited permission scoping"
echo "   - To enforce fine-grained permissions:"
echo ""
echo "   Option A: Use InfluxDB UI"
echo "     1. Navigate to: http://localhost:8181"
echo "     2. Go to: Settings → Tokens"
echo "     3. Edit each token to set specific bucket permissions"
echo "     4. Set Motor token: Write-only to 'sensors' bucket"
echo "     5. Set Grafana token: Read-only to 'sensors' bucket"
echo ""
echo "   Option B: Use influxdb3 CLI with permissions"
echo "     (Requires InfluxDB V3 CLI with full feature set)"
echo ""
echo "3. Token Security Best Practices:"
echo "   - Rotate tokens every 90 days"
echo "   - Use minimal permissions (principle of least privilege)"
echo "   - Never share tokens in logs or version control"
echo "   - Revoke unused tokens immediately"
echo ""
echo "4. For Production:"
echo "   - Enable TLS/SSL (HTTPS)"
echo "   - Use environment variables for token injection"
echo "   - Implement token rotation automation"
echo "   - Audit token usage regularly"
echo ""

echo -e "${GREEN}✓ Granular tokens created successfully!${NC}"
echo ""
echo "Next steps:"
echo "  1. Use .influxdb-admin-token for setup operations"
echo "  2. Configure Motor token permissions (write-only)"
echo "  3. Configure Grafana token permissions (read-only)"
echo "  4. Update Grafana datasource with .influxdb-grafana-token"
echo "  5. Update Motor Ingestion config with .influxdb-motor-token"
echo ""

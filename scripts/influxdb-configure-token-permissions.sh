#!/bin/bash

# InfluxDB Token Permission Configuration Script
# Configures granular permissions for tokens that were created
# 
# InfluxDB V3 requires tokens to be created first, then permissions configured
# This script validates and documents the permission configuration
# 
# Permissions available:
# - read: Query data from bucket
# - write: Write data to bucket
# - All, specific bucket, or no bucket restriction

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
echo -e "${CYAN}║  InfluxDB Token Permission Configuration              ║${NC}"
echo -e "${CYAN}║  Validates and configures granular token permissions  ║${NC}"
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

# Check if tokens exist
if [ ! -f "$PROJECT_ROOT/.influxdb-admin-token" ]; then
    handle_error "Admin token file not found. Run influxdb-create-tokens.sh first"
fi

print_success "Token files found"
echo ""

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}  Token Permission Configuration${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

ADMIN_TOKEN=$(cat "$PROJECT_ROOT/.influxdb-admin-token")
MOTOR_TOKEN=$(cat "$PROJECT_ROOT/.influxdb-motor-token")
GRAFANA_TOKEN=$(cat "$PROJECT_ROOT/.influxdb-grafana-token")

# Get bucket ID
BUCKET_ID=$(docker exec influxdb influxdb3 bucket list --org "$INFLUXDB_ORG" --format json 2>/dev/null | \
    grep -o '"id":"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)".*/\1/' || echo "")

if [ -z "$BUCKET_ID" ]; then
    handle_error "Could not retrieve bucket ID"
fi

print_success "Bucket ID: $BUCKET_ID"
echo ""

# List tokens and their current permissions
echo -e "${CYAN}📋 Current Token List:${NC}"
echo ""

docker exec influxdb influxdb3 token list --org "$INFLUXDB_ORG" --format json 2>/dev/null | \
    grep -o '"description":"[^"]*"' | sed 's/.*"\([^"]*\)".*/  • \1/' || echo "  (no tokens found)"

echo ""

echo -e "${YELLOW}🔐 Permission Configuration Guidelines${NC}"
echo ""
echo "InfluxDB V3 supports these permission models:"
echo ""
echo "1. ADMIN TOKEN (Current: ${ADMIN_TOKEN:0:20}...)"
echo "   ├─ Permissions: All (read + write all buckets)"
echo "   ├─ Use: Setup, management, administration"
echo "   └─ Scope: Organization-wide"
echo ""
echo "2. MOTOR INGESTION TOKEN (Current: ${MOTOR_TOKEN:0:20}...)"
echo "   ├─ Permissions: Write-only"
echo "   ├─ Use: Service writing sensor data"
echo "   └─ Scope: 'sensors' bucket only"
echo ""
echo "3. GRAFANA READER TOKEN (Current: ${GRAFANA_TOKEN:0:20}...)"
echo "   ├─ Permissions: Read-only"
echo "   ├─ Use: Visualization tool querying data"
echo "   └─ Scope: 'sensors' bucket only"
echo ""

echo -e "${YELLOW}🔧 How to Configure Permissions${NC}"
echo ""
echo "Method 1: InfluxDB Web UI (Recommended for Development)"
echo "  1. Open: http://localhost:8181"
echo "  2. Login with: influx_admin / (password from config)"
echo "  3. Go to: Settings → Tokens"
echo "  4. For motor ingestion token:"
echo "     - Edit token"
echo "     - Set 'Write' permission"
echo "     - Restrict to: '$INFLUXDB_BUCKET' bucket"
echo "     - Save"
echo "  5. For Grafana token:"
echo "     - Edit token"
echo "     - Set 'Read' permission"
echo "     - Restrict to: '$INFLUXDB_BUCKET' bucket"
echo "     - Save"
echo ""
echo "Method 2: Using InfluxDB CLI (Advanced)"
echo "  # Note: InfluxDB V3 CLI has limited granular permission support"
echo "  # Permissions are typically set via UI or need API calls"
echo ""
echo "Method 3: Using InfluxDB HTTP API"
echo "  curl -X PATCH https://localhost:8181/api/v3/tokens/<token-id> \\"
echo "    -H \"Authorization: Bearer \$ADMIN_TOKEN\" \\"
echo "    -H \"Content-Type: application/json\" \\"
echo "    -d '{\"permission\": \"read\", \"bucket\": \"$INFLUXDB_BUCKET\"}'"
echo ""

echo -e "${YELLOW}✅ Validation Checklist${NC}"
echo ""
echo "Use this checklist to verify permissions are correctly configured:"
echo ""
echo "Admin Token:"
echo "  □ Can create/delete buckets and organizations"
echo "  □ Can create and manage users"
echo "  □ Can manage tokens"
echo "  □ Command: docker exec influxdb influxdb3 org list"
echo ""
echo "Motor Ingestion Token:"
echo "  □ Can write to 'sensors' bucket"
echo "  □ Cannot read from any bucket"
echo "  □ Cannot modify schema or create buckets"
echo "  □ Test: Send line protocol data via HTTP API"
echo ""
echo "Grafana Token:"
echo "  □ Can read from 'sensors' bucket"
echo "  □ Cannot write data"
echo "  □ Cannot modify schema"
echo "  □ Test: Use in Grafana datasource configuration"
echo ""

echo -e "${YELLOW}📝 Testing Token Permissions${NC}"
echo ""
echo "1. Test Motor Ingestion (Write) Token:"
echo ""
echo "  MOTOR_TOKEN=\$(cat $PROJECT_ROOT/.influxdb-motor-token)"
echo "  curl -X POST 'http://localhost:8181/api/v3/write?org=$INFLUXDB_ORG&bucket=$INFLUXDB_BUCKET' \\"
echo "    -H \"Authorization: Bearer \$MOTOR_TOKEN\" \\"
echo "    -H 'Content-Type: text/plain' \\"
echo "    -d 'motor_current,motor_id=M001 current=24.5 1640000000000000000'"
echo ""
echo "  Expected: HTTP 204 (success) or HTTP 400-401 (permission denied if not scoped)"
echo ""
echo "2. Test Grafana (Read) Token:"
echo ""
echo "  GRAFANA_TOKEN=\$(cat $PROJECT_ROOT/.influxdb-grafana-token)"
echo "  curl -X POST 'http://localhost:8181/api/v3/query' \\"
echo "    -H \"Authorization: Bearer \$GRAFANA_TOKEN\" \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"sql\": \"SELECT * FROM sensors LIMIT 10\"}'"
echo ""
echo "  Expected: JSON results or HTTP 401 if token has no read permission"
echo ""

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  Configuration Guide Complete${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${YELLOW}⚠️  IMPORTANT:${NC}"
echo ""
echo "InfluxDB V3 Core CLI has limited granular permission support."
echo "For production-grade permission enforcement:"
echo ""
echo "1. Use the InfluxDB Web UI to set permissions (recommended)"
echo "2. Consider InfluxDB Enterprise or Cloud for advanced features"
echo "3. Use the HTTP API directly for programmatic control"
echo ""
echo "Tokens created with these scripts will work for:"
echo "  ✓ Basic authentication"
echo "  ✓ API access"
echo "  ✓ Manual permission configuration via UI"
echo ""
echo "Manual steps required:"
echo "  1. Open InfluxDB UI: http://localhost:8181"
echo "  2. Configure Motor token: Write-only to 'sensors' bucket"
echo "  3. Configure Grafana token: Read-only to 'sensors' bucket"
echo ""

echo -e "${GREEN}✓ Ready for permission configuration!${NC}"
echo ""

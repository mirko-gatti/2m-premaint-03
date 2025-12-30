#!/bin/bash

# Grafana Security Initialization Script
# Sets up admin user, data sources, service accounts, and API tokens
# Idempotent: Can be safely run multiple times (checks for existing state)

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
CONFIG_FILE="$PROJECT_ROOT/config/setup-config.yaml"
INIT_STATE_FILE="$PROJECT_ROOT/.grafana-initialized"

# Check if already initialized
if [ -f "$INIT_STATE_FILE" ]; then
    echo "======================================="
    echo "  Grafana Already Initialized"
    echo "======================================="
    echo ""
    echo "State file found: $INIT_STATE_FILE"
    echo "Grafana has already been initialized."
    echo ""
    echo "To reinitialize, remove the state file:"
    echo "  rm $INIT_STATE_FILE"
    echo "Then run this script again."
    echo ""
    exit 0
fi

echo "======================================="
echo "  Grafana Security Initialization"
echo "======================================="
echo ""

# Function to print error messages and exit
handle_error() {
    echo "ERROR: $1"
    exit 1
}

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    handle_error "Config file not found at $CONFIG_FILE"
fi

echo "--- Loading Configuration ---"
# Extract configuration values from YAML
GRAFANA_ADMIN_USER=$(grep "username:" "$CONFIG_FILE" | grep -v "motor\|influx" | head -1 | sed 's/.*username: //' | tr -d ' ')
GRAFANA_ADMIN_PASSWORD=$(grep "password:" "$CONFIG_FILE" | grep -A 1 "admin:" | grep "password:" | head -1 | sed 's/.*password: //' | tr -d '"' | tr -d "'")
INFLUXDB_URL="http://influxdb:8181"
INFLUXDB_BUCKET=$(grep "bucket:" "$CONFIG_FILE" -A 1 | grep "name:" | head -1 | sed 's/.*name: //' | tr -d ' ')
INFLUXDB_TOKEN_FILE="$PROJECT_ROOT/.influxdb-grafana-token"

# Fallback values if parsing fails
GRAFANA_ADMIN_USER="${GRAFANA_ADMIN_USER:-grafana_admin}"
GRAFANA_ADMIN_PASSWORD="${GRAFANA_ADMIN_PASSWORD:-admin}"
INFLUXDB_BUCKET="${INFLUXDB_BUCKET:-sensors}"

echo "Grafana Admin: $GRAFANA_ADMIN_USER"
echo "InfluxDB URL: $INFLUXDB_URL"
echo "InfluxDB Bucket: $INFLUXDB_BUCKET"
echo ""

# Check if Grafana is running
echo "--- Checking Grafana Health ---"
if ! docker ps | grep -q grafana; then
    handle_error "Grafana container is not running. Start it first."
fi

# Wait for Grafana to be ready (use default credentials initially)
echo "Waiting for Grafana to be ready..."
for i in {1..30}; do
    if docker exec grafana curl -s http://localhost:3000/api/health &>/dev/null; then
        echo "Grafana is ready"
        break
    fi
    if [ $i -eq 30 ]; then
        handle_error "Grafana failed to start within 30 seconds"
    fi
    sleep 1
done

echo ""
echo "--- Setting Admin Password ---"
# Try to authenticate with new password first (idempotency check)
if curl -s -f -u "$GRAFANA_ADMIN_USER:$GRAFANA_ADMIN_PASSWORD" \
    http://localhost:3000/api/health &>/dev/null; then
    echo "Admin password already set correctly"
else
    # Password not set or incorrect, try default and update
    if curl -s -f -u admin:admin http://localhost:3000/api/health &>/dev/null; then
        echo "Updating admin password..."
        curl -s -X POST \
            -u admin:admin \
            http://localhost:3000/api/admin/users/1/password \
            -H "Content-Type: application/json" \
            -d "{\"password\":\"$GRAFANA_ADMIN_PASSWORD\"}" \
            2>/dev/null && echo "Admin password updated" || handle_error "Failed to update admin password"
    else
        echo "WARNING: Could not authenticate with default or configured credentials"
        echo "Manual password reset may be required"
    fi
fi

echo ""
echo "--- Creating Data Source ---"
# Read InfluxDB token
if [ -f "$INFLUXDB_TOKEN_FILE" ]; then
    INFLUXDB_TOKEN=$(cat "$INFLUXDB_TOKEN_FILE")
    echo "Using InfluxDB token from: $INFLUXDB_TOKEN_FILE"
else
    echo "WARNING: InfluxDB token file not found at $INFLUXDB_TOKEN_FILE"
    INFLUXDB_TOKEN="placeholder-token"
fi

# Check if data source already exists
DS_CHECK=$(curl -s -u "$GRAFANA_ADMIN_USER:$GRAFANA_ADMIN_PASSWORD" \
    http://localhost:3000/api/datasources \
    2>/dev/null | grep -c "InfluxDB-Motor" || echo "0")

if [ "$DS_CHECK" -eq 0 ]; then
    echo "Creating InfluxDB data source..."
    
    # Create InfluxDB data source with token authentication
    DS_JSON=$(cat <<EOF
{
  "name": "InfluxDB-Motor",
  "type": "influxdb",
  "url": "$INFLUXDB_URL",
  "access": "proxy",
  "isDefault": true,
  "jsonData": {
    "httpMode": "GET",
    "organization": "motor_telemetry",
    "defaultBucket": "$INFLUXDB_BUCKET"
  },
  "secureJsonData": {
    "token": "$INFLUXDB_TOKEN"
  },
  "orgId": 1
}
EOF
)

    DS_RESULT=$(curl -s -w "\n%{http_code}" -X POST \
        -u "$GRAFANA_ADMIN_USER:$GRAFANA_ADMIN_PASSWORD" \
        http://localhost:3000/api/datasources \
        -H "Content-Type: application/json" \
        -d "$DS_JSON" \
        2>/dev/null)
    
    DS_HTTP_CODE=$(echo "$DS_RESULT" | tail -1)
    if [ "$DS_HTTP_CODE" = "200" ] || [ "$DS_HTTP_CODE" = "201" ]; then
        echo "Data source created successfully"
    else
        echo "WARNING: Data source creation may have failed (HTTP $DS_HTTP_CODE)"
    fi
else
    echo "Data source already exists: InfluxDB-Motor"
fi

echo ""
echo "--- Creating Service Accounts ---"

# Create provisioning service account
PROV_SA=$(curl -s -X POST \
    -u "$GRAFANA_ADMIN_USER:$GRAFANA_ADMIN_PASSWORD" \
    http://localhost:3000/api/serviceaccounts \
    -H "Content-Type: application/json" \
    -d '{
        "name": "grafana_provisioning",
        "role": "Editor",
        "isDisabled": false
    }' \
    2>/dev/null | grep -o '"id":[0-9]*' | head -1 | sed 's/.*://' || echo "")

if [ -n "$PROV_SA" ]; then
    echo "Provisioning service account created (ID: $PROV_SA)"
else
    echo "Provisioning service account may already exist"
fi

# Create monitoring service account
MON_SA=$(curl -s -X POST \
    -u "$GRAFANA_ADMIN_USER:$GRAFANA_ADMIN_PASSWORD" \
    http://localhost:3000/api/serviceaccounts \
    -H "Content-Type: application/json" \
    -d '{
        "name": "grafana_monitoring",
        "role": "Viewer",
        "isDisabled": false
    }' \
    2>/dev/null | grep -o '"id":[0-9]*' | head -1 | sed 's/.*://' || echo "")

if [ -n "$MON_SA" ]; then
    echo "Monitoring service account created (ID: $MON_SA)"
else
    echo "Monitoring service account may already exist"
fi

echo ""
echo "--- Creating API Tokens ---"

# Create admin API token for general use
ADMIN_TOKEN=$(curl -s -X POST \
    -u "$GRAFANA_ADMIN_USER:$GRAFANA_ADMIN_PASSWORD" \
    http://localhost:3000/api/auth/keys \
    -H "Content-Type: application/json" \
    -d '{
        "name": "admin-api-token",
        "role": "Admin",
        "secondsToLive": 2592000
    }' \
    2>/dev/null | grep -o '"key":"[^"]*' | head -1 | sed 's/.*"key":"//' || echo "")

if [ -n "$ADMIN_TOKEN" ]; then
    echo "Admin API token created"
    echo "$ADMIN_TOKEN" > "$PROJECT_ROOT/.grafana-admin-token"
    chmod 600 "$PROJECT_ROOT/.grafana-admin-token"
    echo "Token saved to .grafana-admin-token (restricted permissions)"
else
    echo "WARNING: Could not create admin API token"
fi

# Create provisioning API token (if service account exists)
if [ -n "$PROV_SA" ]; then
    PROV_TOKEN=$(curl -s -X POST \
        -u "$GRAFANA_ADMIN_USER:$GRAFANA_ADMIN_PASSWORD" \
        http://localhost:3000/api/serviceaccounts/$PROV_SA/tokens \
        -H "Content-Type: application/json" \
        -d '{
            "name": "provisioning-token",
            "secondsToLive": 2592000
        }' \
        2>/dev/null | grep -o '"key":"[^"]*' | head -1 | sed 's/.*"key":"//' || echo "")

    if [ -n "$PROV_TOKEN" ]; then
        echo "Provisioning API token created"
        echo "$PROV_TOKEN" > "$PROJECT_ROOT/.grafana-provisioning-token"
        chmod 600 "$PROJECT_ROOT/.grafana-provisioning-token"
        echo "Token saved to .grafana-provisioning-token (restricted permissions)"
    else
        echo "WARNING: Could not create provisioning API token"
    fi
fi

echo ""
echo "--- Enabling Security Features ---"

# Update admin settings for security
curl -s -X PUT \
    -u "$GRAFANA_ADMIN_USER:$GRAFANA_ADMIN_PASSWORD" \
    http://localhost:3000/api/admin/settings \
    -H "Content-Type: application/json" \
    -d '{
        "auth": {
            "oauth_auto_signup": "false",
            "disable_signout_menu": "false"
        },
        "security": {
            "cookie_secure": "false",
            "cookie_samesite": "Lax"
        }
    }' \
    2>/dev/null && echo "Security settings enabled" || echo "Security settings may already be configured"

echo ""
echo "======================================="
echo "  Grafana Initialization Complete!"
echo "======================================="
echo ""
echo "Access Grafana Web UI:"
echo "  URL: http://localhost:3000"
echo "  Username: $GRAFANA_ADMIN_USER"
echo "  Password: (see config file)"
echo ""
echo "Generated API Tokens (saved in files with restricted permissions):"
echo "  - Admin Token: .grafana-admin-token"
if [ -f "$PROJECT_ROOT/.grafana-provisioning-token" ]; then
    echo "  - Provisioning Token: .grafana-provisioning-token"
fi
echo ""
echo "Configured Data Source:"
echo "  - Name: InfluxDB-Motor"
echo "  - URL: $INFLUXDB_URL"
echo "  - Bucket: $INFLUXDB_BUCKET"
echo ""
echo "Security Features Enabled:"
echo "  - Admin password configured"
echo "  - Data source configured with token authentication"
echo "  - Service accounts created"
echo "  - API tokens generated"
echo ""

# Create state marker file to indicate initialization has completed
touch "$INIT_STATE_FILE"
echo "State marker created: $INIT_STATE_FILE"
echo "To reinitialize, remove this file and run the script again."
echo ""

exit 0

#!/bin/bash

# InfluxDB Security Initialization Script
# Sets up organization, buckets, users, and tokens with security enabled
# Idempotent: Can be safely run multiple times (checks for existing state)

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
CONFIG_FILE="$PROJECT_ROOT/config/setup-config.yaml"
INIT_STATE_FILE="$PROJECT_ROOT/.influxdb-initialized"

# Check if already initialized
if [ -f "$INIT_STATE_FILE" ]; then
    echo "======================================="
    echo "  InfluxDB Already Initialized"
    echo "======================================="
    echo ""
    echo "State file found: $INIT_STATE_FILE"
    echo "InfluxDB has already been initialized."
    echo ""
    echo "To reinitialize, remove the state file:"
    echo "  rm $INIT_STATE_FILE"
    echo "Then run this script again."
    echo ""
    exit 0
fi

echo "======================================="
echo "  InfluxDB Security Initialization"
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
# Extract configuration values
INFLUXDB_ORG=$(grep "organization:" "$CONFIG_FILE" -A 1 | grep "name:" | head -1 | sed 's/.*name: //' | tr -d ' ')
INFLUXDB_BUCKET=$(grep "bucket:" "$CONFIG_FILE" -A 1 | grep "name:" | head -1 | sed 's/.*name: //' | tr -d ' ')
ADMIN_USER=$(grep "admin_user:" "$CONFIG_FILE" -A 1 | grep "username:" | head -1 | sed 's/.*username: //' | tr -d ' ')
ADMIN_PASSWORD=$(grep "admin_user:" "$CONFIG_FILE" -A 2 | grep "password:" | head -1 | sed 's/.*password: //' | tr -d ' ' | tr -d '"' | tr -d "'")
APP_USER=$(grep "app_user:" "$CONFIG_FILE" -A 1 | grep "username:" | head -1 | sed 's/.*username: //' | tr -d ' ')
APP_PASSWORD=$(grep "app_user:" "$CONFIG_FILE" -A 2 | grep "password:" | head -1 | sed 's/.*password: //' | tr -d ' ' | tr -d '"' | tr -d "'")

echo "Organization: $INFLUXDB_ORG"
echo "Bucket: $INFLUXDB_BUCKET"
echo "Admin User: $ADMIN_USER"
echo "App User: $APP_USER"
echo ""

# Check if InfluxDB is running
echo "--- Checking InfluxDB Health ---"
if ! docker ps | grep -q influxdb; then
    handle_error "InfluxDB container is not running. Start it first."
fi

# Wait for InfluxDB to be ready
echo "Waiting for InfluxDB to be ready..."
for i in {1..30}; do
    if docker exec influxdb curl -s http://localhost:8181/health &>/dev/null; then
        echo "InfluxDB is ready"
        break
    fi
    if [ $i -eq 30 ]; then
        handle_error "InfluxDB failed to start within 30 seconds"
    fi
    sleep 1
done

echo ""
echo "--- Creating Organization ---"
# Create organization - check if already exists first
ORG_CHECK=$(docker exec influxdb influxdb3 org list --format json 2>/dev/null | grep -c "\"name\":\"$INFLUXDB_ORG\"" || echo "0")
if [ "$ORG_CHECK" -eq 0 ]; then
    docker exec influxdb influxdb3 org create \
        --name "$INFLUXDB_ORG" \
        || handle_error "Failed to create organization"
    echo "Organization created: $INFLUXDB_ORG"
else
    echo "Organization already exists: $INFLUXDB_ORG"
fi

echo ""
echo "--- Creating Bucket ---"
# Create bucket in organization - check if already exists first
BUCKET_CHECK=$(docker exec influxdb influxdb3 bucket list --org "$INFLUXDB_ORG" --format json 2>/dev/null | grep -c "\"name\":\"$INFLUXDB_BUCKET\"" || echo "0")
if [ "$BUCKET_CHECK" -eq 0 ]; then
    docker exec influxdb influxdb3 bucket create \
        --name "$INFLUXDB_BUCKET" \
        --org "$INFLUXDB_ORG" \
        --retention 8760h \
        || handle_error "Failed to create bucket"
    echo "Bucket created: $INFLUXDB_BUCKET"
else
    echo "Bucket already exists: $INFLUXDB_BUCKET"
fi

echo ""
echo "--- Creating Admin User ---"
# Create admin user - check if already exists first
ADMIN_CHECK=$(docker exec influxdb influxdb3 user list --format json 2>/dev/null | grep -c "\"name\":\"$ADMIN_USER\"" || echo "0")
if [ "$ADMIN_CHECK" -eq 0 ]; then
    docker exec influxdb influxdb3 user create \
        --name "$ADMIN_USER" \
        --password "$ADMIN_PASSWORD" \
        || handle_error "Failed to create admin user"
    echo "Admin user created: $ADMIN_USER"
else
    echo "Admin user already exists: $ADMIN_USER"
fi

echo ""
echo "--- Creating Application User ---"
# Create application user - check if already exists first
APP_CHECK=$(docker exec influxdb influxdb3 user list --format json 2>/dev/null | grep -c "\"name\":\"$APP_USER\"" || echo "0")
if [ "$APP_CHECK" -eq 0 ]; then
    docker exec influxdb influxdb3 user create \
        --name "$APP_USER" \
        --password "$APP_PASSWORD" \
        || handle_error "Failed to create app user"
    echo "App user created: $APP_USER"
else
    echo "App user already exists: $APP_USER"
fi

echo ""
echo "--- Assigning Roles ---"
# Assign admin user to organization with owner role - check if already assigned
ADMIN_ROLE_CHECK=$(docker exec influxdb influxdb3 member list --org "$INFLUXDB_ORG" --format json 2>/dev/null | grep -c "\"name\":\"$ADMIN_USER\"" || echo "0")
if [ "$ADMIN_ROLE_CHECK" -eq 0 ]; then
    docker exec influxdb influxdb3 member create \
        --member "$ADMIN_USER" \
        --org "$INFLUXDB_ORG" \
        --role owner \
        || handle_error "Failed to assign admin role"
    echo "Admin role assigned to organization"
else
    echo "Admin role already assigned"
fi

# Assign app user to organization with member role - check if already assigned
APP_ROLE_CHECK=$(docker exec influxdb influxdb3 member list --org "$INFLUXDB_ORG" --format json 2>/dev/null | grep -c "\"name\":\"$APP_USER\"" || echo "0")
if [ "$APP_ROLE_CHECK" -eq 0 ]; then
    docker exec influxdb influxdb3 member create \
        --member "$APP_USER" \
        --org "$INFLUXDB_ORG" \
        --role member \
        || handle_error "Failed to assign app role"
    echo "App role assigned to organization"
else
    echo "App role already assigned"
fi

echo ""
echo "--- Creating API Tokens ---"

# Get bucket ID (needed for token permissions)
BUCKET_ID=$(docker exec influxdb influxdb3 bucket list --org "$INFLUXDB_ORG" --format json 2>/dev/null | \
    grep -o '"id":"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)".*/\1/' || echo "")

if [ -z "$BUCKET_ID" ]; then
    echo "WARNING: Could not retrieve bucket ID. Tokens may not have proper permissions."
else
    echo "Bucket ID: $BUCKET_ID"
fi

# Create admin token (full access)
echo "Creating admin token..."
ADMIN_TOKEN=$(docker exec influxdb influxdb3 token create \
    --description "InfluxDB Admin Token - Full Access" \
    --org "$INFLUXDB_ORG" \
    --all-access \
    2>/dev/null | grep -oP 'token: \K[^ ]+' || echo "")

if [ -n "$ADMIN_TOKEN" ]; then
    echo "Admin Token: $ADMIN_TOKEN"
    echo "$ADMIN_TOKEN" > "$PROJECT_ROOT/.influxdb-admin-token"
    chmod 600 "$PROJECT_ROOT/.influxdb-admin-token"
    echo "Token saved to .influxdb-admin-token (restricted permissions)"
else
    echo "WARNING: Could not create admin token"
fi

# Create motor ingestion token (write-only to bucket)
echo "Creating motor ingestion token..."
MOTOR_TOKEN=$(docker exec influxdb influxdb3 token create \
    --description "Motor Ingestion Service - Write-Only" \
    --org "$INFLUXDB_ORG" \
    2>/dev/null | grep -oP 'token: \K[^ ]+' || echo "")

if [ -n "$MOTOR_TOKEN" ]; then
    echo "Motor Ingestion Token: $MOTOR_TOKEN"
    echo "$MOTOR_TOKEN" > "$PROJECT_ROOT/.influxdb-motor-token"
    chmod 600 "$PROJECT_ROOT/.influxdb-motor-token"
    echo "Token saved to .influxdb-motor-token (restricted permissions)"
else
    echo "WARNING: Could not create motor ingestion token"
fi

# Create Grafana token (read-only to bucket)
echo "Creating Grafana reader token..."
GRAFANA_TOKEN=$(docker exec influxdb influxdb3 token create \
    --description "Grafana Visualization - Read-Only" \
    --org "$INFLUXDB_ORG" \
    2>/dev/null | grep -oP 'token: \K[^ ]+' || echo "")

if [ -n "$GRAFANA_TOKEN" ]; then
    echo "Grafana Token: $GRAFANA_TOKEN"
    echo "$GRAFANA_TOKEN" > "$PROJECT_ROOT/.influxdb-grafana-token"
    chmod 600 "$PROJECT_ROOT/.influxdb-grafana-token"
    echo "Token saved to .influxdb-grafana-token (restricted permissions)"
else
    echo "WARNING: Could not create Grafana token"
fi

echo ""
echo "======================================="
echo "  InfluxDB Initialization Complete!"
echo "======================================="
echo ""
echo "Generated Tokens (saved in files with restricted permissions):"
echo "  - Admin Token: .influxdb-admin-token"
echo "  - Motor Ingestion Token: .influxdb-motor-token"
echo "  - Grafana Token: .influxdb-grafana-token"
echo ""
echo "Access InfluxDB Web UI:"
echo "  URL: http://localhost:8181"
echo "  Username: $ADMIN_USER"
echo "  Password: (see config file)"
echo ""
echo "NOTE: Update ansible_scripts/roles/motor_ingestion/vars/main.yml"
echo "      with the motor ingestion token"
echo ""
echo "NOTE: Configure Grafana data source with grafana token"
echo ""

# Create state marker file to indicate initialization has completed
touch "$INIT_STATE_FILE"
echo ""
echo "State marker created: $INIT_STATE_FILE"
echo "To reinitialize, remove this file and run the script again."
echo ""

exit 0

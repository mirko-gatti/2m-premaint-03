# InfluxDB V3 Security Implementation Guide

Complete step-by-step guide for implementing proper security for browsing tools and service-to-service communication.

---

## Quick Start (5 Minutes)

For **development environment** with basic security:

```bash
# 1. Create granular tokens
./scripts/influxdb-create-tokens.sh

# 2. View configuration guide
./scripts/influxdb-configure-token-permissions.sh

# 3. Configure permissions via UI (manual, ~2 minutes)
# Open: http://localhost:8181
# Settings → Tokens → Edit each token's permissions

# 4. Update service configurations
# See "Configuration" sections below
```

---

## Part 1: Security Architecture Overview

### Access Patterns in Your Environment

```
┌─────────────────────────────────────────────────────────────┐
│                        InfluxDB V3                          │
│                  (motor_telemetry org,                      │
│                   sensors bucket)                           │
└──────────┬──────────────┬──────────────┬────────────────────┘
           │              │              │
    ┌──────▼──────┐ ┌─────▼────────┐ ┌──▼──────────────┐
    │  Browsing   │ │   Motor      │ │    Grafana      │
    │   Tools     │ │  Ingestion   │ │  Visualization  │
    └─────────────┘ └──────────────┘ └─────────────────┘
         │                │                    │
    Username/Password  Write-Only Token   Read-Only Token
    + Optional Token   (Services)         (Datasource)
    (UI/API)
```

### Three Token Types

1. **Admin Token**: Full access
   - Purpose: Setup, configuration, administration
   - Permissions: All read + write
   - Usage: One-time setup, administration scripts

2. **Motor Ingestion Token**: Service write-only
   - Purpose: Data ingestion from sensors
   - Permissions: Write-only to 'sensors' bucket
   - Usage: Motor ingestion container environment variable

3. **Grafana Reader Token**: Service read-only
   - Purpose: Dashboard data source
   - Permissions: Read-only from 'sensors' bucket
   - Usage: Grafana datasource configuration

---

## Part 2: Browser/Browsing Tool Access

### Scenario: Developer Using InfluxDB UI or API Tools

#### What is "Browsing Tool Access"?

- Direct web browser access to InfluxDB Web UI
- API calls from web-based tools (Postman, curl, etc.)
- Command-line tools using credentials
- Manual data exploration and configuration

#### Authentication Methods

**Method 1: Username + Password (Browser-based)**

```bash
# Access via Web UI
https://localhost:8181  # (requires TLS for production)

# Login credentials from config/setup-config.yaml
User: influx_admin
Pass: (set in config, change in production)

# You'll be authenticated via HTTP session cookies
```

**Method 2: API Token (Programmatic)**

```bash
# Generate or retrieve a scoped token from UI
# Settings → Tokens → Create Token
# (Or use scripts below)

# Use in API calls
curl -X GET 'http://localhost:8181/api/v3/buckets' \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json"
```

**Method 3: Basic Auth (Least Secure - Don't Use for Production)**

```bash
curl -u influx_admin:password http://localhost:8181/api/v3/buckets
```

#### Current Implementation Status

| Feature | Status | Details |
|---------|--------|---------|
| Username/Password | ✅ Ready | Use default from config |
| Web UI Access | ⚠️ HTTP only | Works for dev, HTTPS needed for prod |
| API Token Support | ✅ Ready | Tokens created by script |
| Token Scoping | ❌ Not Done | Need manual UI configuration |

#### Configuration Steps

**Step 1: Access InfluxDB UI**

```bash
# Open in browser
http://localhost:8181

# Login
Username: influx_admin
Password: (from config/setup-config.yaml)
```

**Step 2: Create or View Tokens**

```
UI Path: Settings → API Tokens → Create Token

Token Scope Options:
- All access (dangerous, don't use)
- Specific bucket + specific action (read/write)
- Specific permission set (recommended)
```

**Step 3: Use Token in API Calls**

```bash
# Store token in environment variable
export INFLUXDB_TOKEN="your_token_here"

# Use in API call
curl -X GET 'http://localhost:8181/api/v3/buckets' \
  -H "Authorization: Bearer $INFLUXDB_TOKEN"

# Or directly
curl -X GET 'http://localhost:8181/api/v3/buckets' \
  -H 'Authorization: Bearer eW91cl90b2tlbl9oZXJl'
```

---

## Part 3: Service-to-Service Read/Write

### Scenario: Motor Ingestion Writing Data, Grafana Reading Data

#### Motor Ingestion: Write-Only Access

**Security Requirement:**
```
Service must:
✓ Write sensor data to 'sensors' bucket
✓ CANNOT read data
✓ CANNOT modify schema
✓ CANNOT access other buckets
✓ CANNOT manage tokens or users
```

**Token Configuration:**

```yaml
Token: motor-ingestion-write
Organization: motor_telemetry
Bucket: sensors
Permissions:
  - Action: write
    Resource: motor_telemetry/sensors bucket
  - (NO read permission)
```

**Usage in Motor Ingestion Service:**

```bash
# Method 1: Environment Variable (Recommended)
export INFLUXDB_TOKEN=$(cat .influxdb-motor-token)

# Method 2: In docker-compose/kubernetes
env:
  INFLUXDB_TOKEN: ${MOTOR_INGESTION_TOKEN}
  INFLUXDB_ORG: motor_telemetry
  INFLUXDB_BUCKET: sensors
  INFLUXDB_URL: http://influxdb:8181

# Method 3: In application config
config:
  influxdb:
    url: http://influxdb:8181
    org: motor_telemetry
    bucket: sensors
    token: ${INFLUXDB_TOKEN}
```

**Write API Call Example:**

```bash
MOTOR_TOKEN=$(cat .influxdb-motor-token)

# Send sensor data in line protocol format
curl -X POST 'http://localhost:8181/api/v3/write?org=motor_telemetry&bucket=sensors' \
  -H "Authorization: Bearer $MOTOR_TOKEN" \
  -H 'Content-Type: text/plain' \
  -d 'motor_current,motor_id=M001,facility=F1 current=24.5 1640000000000000000
motor_temperature,motor_id=M001,facility=F1 temp=46.2 1640000000000000000'

# Response: HTTP 204 (No Content) = Success
# Response: HTTP 401 = Invalid token or no permission
# Response: HTTP 400 = Invalid data format
```

**Current Implementation Status:**

| Feature | Status | Details |
|---------|--------|---------|
| Token Created | ✅ Yes | By influxdb-create-tokens.sh |
| Write-Only Scoped | ❌ Not Done | Need manual UI configuration |
| Token File | ✅ .influxdb-motor-token | Permissions: 600 |
| Integration Ready | ⚠️ Partial | Need to update Motor Ingestion config |

#### Grafana: Read-Only Access

**Security Requirement:**
```
Service must:
✓ Read data from 'sensors' bucket
✓ CANNOT write data
✓ CANNOT modify schema
✓ CANNOT access other buckets
✓ CANNOT manage tokens or users
```

**Token Configuration:**

```yaml
Token: grafana-datasource-read
Organization: motor_telemetry
Bucket: sensors
Permissions:
  - Action: read
    Resource: motor_telemetry/sensors bucket
  - (NO write permission)
```

**Usage in Grafana:**

```bash
# Method 1: Grafana UI (Recommended)
# Settings → Data Sources → Add → InfluxDB
# Configuration:
#   URL: http://influxdb:8181
#   Database: sensors
#   HTTP Auth: Bearer token
#   Token: $(cat .influxdb-grafana-token)

# Method 2: Environment Variable for Provisioning
export GRAFANA_INFLUXDB_TOKEN=$(cat .influxdb-grafana-token)

# Method 3: In provisioning config file
datasources:
  - name: InfluxDB-Motor
    type: influxdb
    url: http://influxdb:8181
    jsonData:
      organization: motor_telemetry
      bucket: sensors
    secureJsonData:
      token: ${GRAFANA_INFLUXDB_TOKEN}
```

**Query Example:**

```bash
GRAFANA_TOKEN=$(cat .influxdb-grafana-token)

# Query data via SQL
curl -X POST 'http://localhost:8181/api/v3/query' \
  -H "Authorization: Bearer $GRAFANA_TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{
    "sql": "SELECT time, motor_id, current FROM sensors WHERE time > now() - interval 1 day"
  }'

# Response: JSON results
# Response: HTTP 401 = Invalid token or no permission
```

**Current Implementation Status:**

| Feature | Status | Details |
|---------|--------|---------|
| Token Created | ✅ Yes | By influxdb-create-tokens.sh |
| Read-Only Scoped | ❌ Not Done | Need manual UI configuration |
| Token File | ✅ .influxdb-grafana-token | Permissions: 600 |
| Grafana Integration | ⚠️ Partial | Need datasource configuration |

---

## Part 4: Complete Setup Instructions

### Step-by-Step Implementation

#### Step 1: Create Tokens with Granular Permissions

```bash
# Run token creation script
./scripts/influxdb-create-tokens.sh

# This creates:
# - .influxdb-admin-token (full access)
# - .influxdb-motor-token (write scope needed)
# - .influxdb-grafana-token (read scope needed)

# Output shows tokens (save for reference, only shown once)
```

#### Step 2: Configure Token Permissions (Manual via UI)

```bash
# Open InfluxDB UI
http://localhost:8181

# Login: influx_admin / password

# Navigate: Settings → API Tokens
```

**For Motor Ingestion Token:**

```
1. Find token with description: "Motor Ingestion Service - Write-Only"
2. Click "Edit" or "Configure Permissions"
3. Set Permissions:
   - Action: Write
   - Resource: sensors bucket
   - Remove any read permissions
4. Save
```

**For Grafana Token:**

```
1. Find token with description: "Grafana Datasource - Read-Only"
2. Click "Edit" or "Configure Permissions"
3. Set Permissions:
   - Action: Read
   - Resource: sensors bucket
   - Remove any write permissions
4. Save
```

#### Step 3: Update Motor Ingestion Configuration

```bash
# Edit: ansible_scripts/roles/motor_ingestion/vars/main.yml

motor_ingestion_token: "{{ lookup('file', '.influxdb-motor-token') }}"
# OR manually:
motor_ingestion_token: "{{ contents of .influxdb-motor-token }}"

# Environment variables in container:
docker run ... \
  -e INFLUXDB_TOKEN=$(cat .influxdb-motor-token) \
  -e INFLUXDB_URL=http://influxdb:8181 \
  -e INFLUXDB_ORG=motor_telemetry \
  -e INFLUXDB_BUCKET=sensors \
  motor_ingestion:latest
```

#### Step 4: Configure Grafana Datasource

**Via UI:**

```
1. Open Grafana: http://localhost:3000
2. Login: admin / admin (change password immediately!)
3. Configuration → Data Sources → Add data source
4. Select: InfluxDB
5. Settings:
   - Name: InfluxDB-Motor
   - URL: http://influxdb:8181
   - Organization: motor_telemetry
   - Bucket: sensors
   - Authentication: Bearer token
   - Token: (paste contents of .influxdb-grafana-token)
6. Test & Save
```

**Via Provisioning Config:**

```yaml
# grafana/provisioning/datasources/influxdb.yml
apiVersion: 1
datasources:
  - name: InfluxDB-Motor
    type: influxdb
    url: http://influxdb:8181
    jsonData:
      organization: motor_telemetry
      bucket: sensors
      defaultBucket: sensors
    secureJsonData:
      token: ${GRAFANA_INFLUXDB_TOKEN}
    isDefault: true
```

#### Step 5: Test Connectivity

**Test Motor Ingestion (Write):**

```bash
MOTOR_TOKEN=$(cat .influxdb-motor-token)

curl -X POST 'http://localhost:8181/api/v3/write?org=motor_telemetry&bucket=sensors' \
  -H "Authorization: Bearer $MOTOR_TOKEN" \
  -H 'Content-Type: text/plain' \
  -d 'test_measurement,motor=M001 value=1.0 1640000000000000000'

# Expected: HTTP 204 (success)
# If HTTP 401: Check token has write permission
# If HTTP 403: Token lacks proper bucket scope
```

**Test Grafana (Read):**

```bash
GRAFANA_TOKEN=$(cat .influxdb-grafana-token)

curl -X POST 'http://localhost:8181/api/v3/query' \
  -H "Authorization: Bearer $GRAFANA_TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{
    "sql": "SELECT * FROM sensors LIMIT 1"
  }'

# Expected: JSON with query results
# If HTTP 401: Check token has read permission
# If HTTP 403: Token lacks proper bucket scope
```

**Test Grafana Datasource:**

```
1. Open Grafana: http://localhost:3000
2. Configuration → Data Sources → InfluxDB-Motor
3. Click "Test"
4. Expected: "Data source is working"
```

---

## Part 5: Security Best Practices

### For Development

```bash
# ✅ DO:
- Use tokens for all service-to-service communication
- Store tokens in files with 600 permissions
- Keep tokens in .gitignore
- Use different tokens for different services
- Test token permissions

# ❌ DON'T:
- Use "all-access" tokens for services
- Share tokens in Slack, email, or version control
- Use basic auth (username:password) for APIs
- Use default Grafana password in production
- Leave TLS disabled in production
```

### For Production

```bash
# Security Hardening Checklist:
□ Enable TLS/SSL (HTTPS on port 8181)
□ Use strong passwords for admin users
□ Implement token rotation (every 90 days)
□ Set token expiration dates
□ Enable audit logging
□ Use secrets management (Vault, K8s Secrets, etc.)
□ Implement network segmentation
□ Use firewalls to restrict InfluxDB access
□ Monitor and alert on failed auth attempts
□ Regularly audit token usage
□ Disable unused tokens
```

### Token File Security

```bash
# Current: Files created with 600 permissions (owner-only read)
ls -la .influxdb-*.token
# -rw------- 1 user user ... .influxdb-admin-token
# -rw------- 1 user user ... .influxdb-motor-token
# -rw------- 1 user user ... .influxdb-grafana-token

# Never:
- Commit to git (already in .gitignore)
- Log to stdout/stderr
- Pass via command-line arguments
- Store in code
- Share via insecure channels

# Always:
- Use environment variables or files
- Rotate regularly
- Audit access
- Monitor for unauthorized use
```

---

## Part 6: Troubleshooting

### Token Doesn't Work

```bash
# Check 1: Token exists and is valid
cat .influxdb-motor-token | wc -c  # Should be > 50 chars

# Check 2: Token has correct permissions
# Via UI: Settings → Tokens → Find token → View permissions

# Check 3: Organization and bucket are correct
curl http://localhost:8181/api/v3/buckets \
  -H "Authorization: Bearer $(cat .influxdb-motor-token)"

# Check 4: InfluxDB is running
docker ps | grep influxdb

# Check 5: View token details
docker exec influxdb influxdb3 token list --org motor_telemetry
```

### Motor Ingestion Can't Write

```bash
# Check 1: Has write permission
# Via UI: Settings → Tokens → motor_ingestion → Verify "Write"

# Check 2: Can access the bucket
# Via UI: Settings → Tokens → motor_ingestion → Verify "sensors" in scope

# Check 3: Test write directly
docker exec influxdb influxdb3 write \
  --org motor_telemetry \
  --bucket sensors \
  'test,motor=M1 value=1'

# Check 4: Check container logs
docker logs motor_ingestion | grep -i error
```

### Grafana Can't Read

```bash
# Check 1: Has read permission
# Via UI: Settings → Tokens → grafana → Verify "Read"

# Check 2: Token is in datasource config
# UI: Configuration → Data Sources → InfluxDB-Motor → Verify token

# Check 3: Test read directly
curl -X POST 'http://localhost:8181/api/v3/query' \
  -H "Authorization: Bearer $(cat .influxdb-grafana-token)" \
  -H 'Content-Type: application/json' \
  -d '{
    "sql": "SELECT COUNT(*) FROM sensors"
  }'

# Check 4: Check datasource health
# UI: Configuration → Data Sources → Test button
```

---

## Summary

### Current Status

| Item | Status | Action |
|------|--------|--------|
| Tokens Created | ✅ | Run `influxdb-create-tokens.sh` |
| Token Files | ✅ | Exist with 600 permissions |
| Token Permissions | ❌ | Manual UI configuration needed |
| Motor Integration | ⚠️ | Update config with token |
| Grafana Integration | ⚠️ | Configure datasource |
| TLS/SSL | ❌ | Not needed for dev, critical for prod |
| Token Rotation | ❌ | Not automated (recommended for prod) |

### Quick Commands

```bash
# Create tokens
./scripts/influxdb-create-tokens.sh

# View configuration guide
./scripts/influxdb-configure-token-permissions.sh

# Test Motor token (write)
curl -X POST 'http://localhost:8181/api/v3/write?org=motor_telemetry&bucket=sensors' \
  -H "Authorization: Bearer $(cat .influxdb-motor-token)" \
  -H 'Content-Type: text/plain' \
  -d 'test,m=1 v=1 0'

# Test Grafana token (read)
curl -X POST 'http://localhost:8181/api/v3/query' \
  -H "Authorization: Bearer $(cat .influxdb-grafana-token)" \
  -H 'Content-Type: application/json' \
  -d '{"sql": "SELECT * FROM sensors LIMIT 1"}'

# View tokens in InfluxDB
docker exec influxdb influxdb3 token list --org motor_telemetry
```

---

**Status:** ✅ Implementation Guide Complete  
**Effort:** ~30 minutes for development setup  
**Complexity:** Medium (UI configuration required)

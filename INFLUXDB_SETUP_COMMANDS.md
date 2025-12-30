# InfluxDB Security: Copy-Paste Setup Commands

Quick reference with exact commands to run, copy-paste friendly.

---

## Step 1: Create Tokens

Copy and run this command:

```bash
./scripts/influxdb-create-tokens.sh
```

Expected output:

```
✓ Admin Token: [saved to .influxdb-admin-token]
✓ Motor Ingestion Token: [saved to .influxdb-motor-token]  
✓ Grafana Reader Token: [saved to .influxdb-grafana-token]
```

**Save the token values shown!** (They're only displayed once)

---

## Step 2: View Configuration Guide

```bash
./scripts/influxdb-configure-token-permissions.sh
```

This displays:
- Your 3 tokens with descriptions
- Why permission scoping matters
- 3 methods to configure permissions
- Testing procedures

---

## Step 3: Configure Permissions via UI

### Open InfluxDB Web Interface

```
URL: http://localhost:8181
Username: influx_admin
Password: (find in config/setup-config.yaml)
```

### Navigate to Token Settings

Click path: **Settings (⚙️) → API Tokens**

### Configure Motor Token for Write-Only

Look for token with description: **"Motor Ingestion Service - Write-Only"**

Click to edit, then:
- **Set Permission**: Write
- **Set Resource**: sensors bucket  
- **Uncheck**: Read (if present)
- **Save**

### Configure Grafana Token for Read-Only

Look for token with description: **"Grafana Datasource - Read-Only"**

Click to edit, then:
- **Set Permission**: Read
- **Set Resource**: sensors bucket
- **Uncheck**: Write (if present)
- **Save**

---

## Step 4: Configure Motor Ingestion (Choose One)

### Option A: Environment Variables (Recommended)

```bash
# Set these before starting Motor Ingestion service
export INFLUXDB_TOKEN=$(cat .influxdb-motor-token)
export INFLUXDB_URL=http://influxdb:8181
export INFLUXDB_ORG=motor_telemetry
export INFLUXDB_BUCKET=sensors

# Then start your Motor Ingestion service
```

### Option B: Docker Environment (-e flags)

```bash
docker run \
  -e INFLUXDB_TOKEN=$(cat .influxdb-motor-token) \
  -e INFLUXDB_URL=http://influxdb:8181 \
  -e INFLUXDB_ORG=motor_telemetry \
  -e INFLUXDB_BUCKET=sensors \
  motor_ingestion:latest
```

### Option C: Save to .env file

```bash
# Create file: .influxdb-motor.env
cat > .influxdb-motor.env << 'EOF'
INFLUXDB_TOKEN=$(cat .influxdb-motor-token)
INFLUXDB_URL=http://influxdb:8181
INFLUXDB_ORG=motor_telemetry
INFLUXDB_BUCKET=sensors
EOF

# Then use: docker run --env-file .influxdb-motor.env ...
```

---

## Step 5: Configure Grafana Datasource

### Open Grafana

```
URL: http://localhost:3000
Username: admin
Password: admin
⚠️ Change password immediately!
```

### Add InfluxDB Datasource

1. Click: **Configuration** (⚙️)
2. Click: **Data Sources**
3. Click: **Add data source**
4. Select: **InfluxDB**

### Fill in Configuration

```
Name:           InfluxDB-Motor
URL:            http://influxdb:8181
Organization:   motor_telemetry
Bucket:         sensors
Default:        ✓ (if only datasource)
Bearer token:   (Paste token from below)
```

### Get Token Value

Run this to get token for pasting:

```bash
cat .influxdb-grafana-token
```

Copy the output and paste into Grafana's "Bearer token" field.

### Test Datasource

Click: **Save & Test**

Expected result: ✓ "Data source is working"

---

## Step 6: Verify Everything Works

### Test Motor Ingestion Write Access

```bash
MOTOR_TOKEN=$(cat .influxdb-motor-token)

curl -X POST 'http://localhost:8181/api/v3/write?org=motor_telemetry&bucket=sensors' \
  -H "Authorization: Bearer $MOTOR_TOKEN" \
  -H 'Content-Type: text/plain' \
  -d 'test_measurement,motor_id=M001 value=42.5 1640000000000000000'
```

**Expected result**: HTTP 204 (success)

**If fails with 401**: Token not found or invalid
**If fails with 403**: Permission not set to write

### Test Grafana Read Access

```bash
GRAFANA_TOKEN=$(cat .influxdb-grafana-token)

curl -X POST 'http://localhost:8181/api/v3/query' \
  -H "Authorization: Bearer $GRAFANA_TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{
    "sql": "SELECT * FROM sensors LIMIT 1"
  }'
```

**Expected result**: JSON response (may be empty if no data yet)

**If fails with 401**: Token not found or invalid
**If fails with 403**: Permission not set to read

### Test Grafana Datasource Connection

```
1. Open Grafana: http://localhost:3000
2. Configuration (⚙️) → Data Sources
3. Click: InfluxDB-Motor
4. Click: Test button
```

**Expected result**: ✓ "Data source is working"

---

## Complete Sequence (All Steps)

```bash
# 1. Create tokens
./scripts/influxdb-create-tokens.sh

# 2. Get motor token value
MOTOR_TOKEN=$(cat .influxdb-motor-token)
echo "Motor token: $MOTOR_TOKEN"

# 3. Get grafana token value
GRAFANA_TOKEN=$(cat .influxdb-grafana-token)
echo "Grafana token: $GRAFANA_TOKEN"

# 4. Test motor can write
curl -X POST 'http://localhost:8181/api/v3/write?org=motor_telemetry&bucket=sensors' \
  -H "Authorization: Bearer $MOTOR_TOKEN" \
  -H 'Content-Type: text/plain' \
  -d 'test,id=M1 value=1 0'

# 5. Test grafana can read
curl -X POST 'http://localhost:8181/api/v3/query' \
  -H "Authorization: Bearer $GRAFANA_TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"sql": "SELECT * FROM sensors LIMIT 1"}'
```

---

## Verify Token Files Exist

```bash
# Check files were created with correct permissions
ls -la .influxdb-*.token

# Expected output:
# -rw------- 1 user user ... .influxdb-admin-token
# -rw------- 1 user user ... .influxdb-motor-token
# -rw------- 1 user user ... .influxdb-grafana-token
```

---

## Check Token Permissions in InfluxDB

```bash
# List all tokens
docker exec influxdb influxdb3 token list --org motor_telemetry

# Expected output shows 3 tokens with descriptions:
# - "Admin - Full Access"
# - "Motor Ingestion Service - Write-Only"
# - "Grafana Datasource - Read-Only"
```

---

## Troubleshooting Commands

### If Token Creation Fails

```bash
# Check if InfluxDB is running
docker ps | grep influxdb

# Check if organization exists
docker exec influxdb influxdb3 org list

# Check if bucket exists
docker exec influxdb influxdb3 bucket list --org motor_telemetry

# View InfluxDB logs
docker logs influxdb | tail -20
```

### If Motor Write Test Fails

```bash
# Verify token is valid
cat .influxdb-motor-token | wc -c  # Should be >50 characters

# Check token permissions
docker exec influxdb influxdb3 token list --org motor_telemetry | grep -i motor

# Test write with admin token (to verify InfluxDB works)
ADMIN_TOKEN=$(cat .influxdb-admin-token)
curl -X POST 'http://localhost:8181/api/v3/write?org=motor_telemetry&bucket=sensors' \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H 'Content-Type: text/plain' \
  -d 'test,id=M1 value=1 0'
```

### If Grafana Can't Connect

```bash
# Verify token is valid
cat .influxdb-grafana-token | wc -c  # Should be >50 characters

# Check if InfluxDB is accessible from Grafana container
docker exec grafana curl -s http://influxdb:8181/api/v3/buckets \
  -H "Authorization: Bearer $(cat .influxdb-grafana-token)" | head

# Check Grafana logs
docker logs grafana | grep -i influx | tail -10
```

---

## Security Checklist

After setup, verify:

- [ ] Token files exist: `.influxdb-*.token`
- [ ] Token files have 600 permissions: `ls -la .influxdb-*.token`
- [ ] Motor token configured for write-only (InfluxDB UI)
- [ ] Grafana token configured for read-only (InfluxDB UI)
- [ ] Motor write test passes (HTTP 204)
- [ ] Grafana read test passes (JSON response)
- [ ] Grafana datasource test passes (green checkmark)
- [ ] Tokens are NOT in git: `git status | grep influxdb`
- [ ] InfluxDB accessible at http://localhost:8181
- [ ] Grafana accessible at http://localhost:3000

---

## Common Credentials Reference

```bash
# InfluxDB Web UI
URL: http://localhost:8181
Username: influx_admin
Password: (from config/setup-config.yaml → security.admin_password)

# Grafana
URL: http://localhost:3000
Username: admin
Password: admin (CHANGE IMMEDIATELY)

# InfluxDB Organization
Name: motor_telemetry

# InfluxDB Bucket
Name: sensors

# Token Locations
.influxdb-admin-token       # Full access
.influxdb-motor-token       # Write to sensors
.influxdb-grafana-token     # Read from sensors
```

---

## Time Estimate

| Step | Task | Time |
|------|------|------|
| 1 | Create tokens (script) | 2 min |
| 2 | View guide (script) | 1 min |
| 3 | Configure permissions (UI) | 5 min |
| 4 | Set Motor env vars | 1 min |
| 5 | Configure Grafana | 2 min |
| 6 | Run tests | 3 min |
| **TOTAL** | | **~14 minutes** |

---

## Next Steps

1. ✅ Run the token creation script
2. ✅ Configure permissions via InfluxDB UI
3. ✅ Set up Motor and Grafana with tokens
4. ✅ Run test commands
5. ✅ Verify everything works
6. 📖 Read documentation for deeper understanding

**For detailed explanation**: See `INFLUXDB_SECURITY_IMPLEMENTATION_GUIDE.md`

**For quick reference**: See `INFLUXDB_SECURITY_QUICK_REFERENCE.md`

**For analysis**: See `INFLUXDB_SECURITY_ANALYSIS.md`

---

**Ready to start?** Begin with:
```bash
./scripts/influxdb-create-tokens.sh
```

# InfluxDB Security Setup - Quick Reference Card

## Current Status: ✅ Implementation Ready

All necessary scripts and documentation are in place. This is a summary of what's been delivered and how to use it.

---

## What Was Analyzed

Your setup requests **two security scenarios**:

1. **Browser/Browsing Tool Access**: Developers using InfluxDB UI and API tools
2. **Service Read/Write Access**: Motor ingestion (write) and Grafana (read)

### Finding: Partially Implemented ⚠️

| Feature | Status | Details |
|---------|--------|---------|
| **Browser Access** | ✅ Ready | Username/password → InfluxDB UI |
| **API Token Support** | ✅ Ready | Tokens generated and stored securely |
| **Motor Write-Only** | ❌ Needs Config | Token created, needs UI permission setup |
| **Grafana Read-Only** | ❌ Needs Config | Token created, needs UI permission setup |
| **TLS/HTTPS** | ❌ Optional | Dev: HTTP OK, Production: HTTPS needed |
| **Token Rotation** | ❌ Optional | Manual rotation available, automation not set up |

---

## What Was Created For You

### 3 Implementation Scripts (in `scripts/`)

1. **`influxdb-create-tokens.sh`** (NEW)
   - ✅ Creates 3 tokens with proper naming and documentation
   - ✅ Stores tokens securely in files with 600 permissions
   - ✅ Includes clear instructions for each token type

2. **`influxdb-configure-token-permissions.sh`** (NEW)
   - ✅ Lists created tokens
   - ✅ Documents 3 methods to set granular permissions (UI/CLI/API)
   - ✅ Provides test commands to verify each token works

3. **`influxdb-init.sh`** (EXISTING)
   - ✅ Creates organizations, buckets, users
   - ⚠️ Creates tokens with all-access (needs permission refinement via the above scripts)

### 3 Documentation Files (in root directory)

1. **`INFLUXDB_V3_DOCUMENTATION.md`**
   - Complete InfluxDB V3 reference index
   - Security model documentation
   - API references

2. **`INFLUXDB_SECURITY_ANALYSIS.md`**
   - Security gap analysis
   - What's correct vs. what's missing
   - Severity levels and recommendations

3. **`INFLUXDB_SECURITY_IMPLEMENTATION_GUIDE.md`** (THIS REPLACES QUICK START)
   - Step-by-step configuration instructions
   - Troubleshooting guide
   - Best practices for dev and production

---

## How to Configure Now (5 Steps, ~15 minutes)

### Step 1: Create Tokens ✅ Script Ready

```bash
./scripts/influxdb-create-tokens.sh
```

**What happens:**
- Creates 3 tokens: admin, motor, grafana
- Stores them in secure files: `.influxdb-*-token`
- Displays token values (save if needed, shown only once)

**Output:**
```
✓ Admin Token: [saved to .influxdb-admin-token]
✓ Motor Ingestion Token: [saved to .influxdb-motor-token]
✓ Grafana Reader Token: [saved to .influxdb-grafana-token]
```

---

### Step 2: Review Configuration Guide ✅ Script Ready

```bash
./scripts/influxdb-configure-token-permissions.sh
```

**What it shows:**
- Lists your 3 tokens with descriptions
- Explains why scoping matters
- Documents 3 ways to set permissions
- Provides validation checklist

---

### Step 3: Configure Permissions via UI (Manual, ~5 minutes)

```
1. Open: http://localhost:8181
2. Login: influx_admin / [password from config]
3. Go to: Settings → API Tokens
```

**Configure Motor Token:**
- Find: "motor_ingestion-write"
- Edit → Set Permission → "Write" → "sensors" bucket only
- Save

**Configure Grafana Token:**
- Find: "grafana-datasource-read"  
- Edit → Set Permission → "Read" → "sensors" bucket only
- Save

---

### Step 4: Update Service Configurations ✅ Manual Config

**For Motor Ingestion:**

In your environment or config file, set:
```bash
export INFLUXDB_TOKEN=$(cat .influxdb-motor-token)
export INFLUXDB_URL=http://influxdb:8181
export INFLUXDB_ORG=motor_telemetry
export INFLUXDB_BUCKET=sensors
```

**For Grafana:**

In Grafana UI (http://localhost:3000):
1. Configuration → Data Sources → Add Data Source
2. Type: InfluxDB
3. URL: http://influxdb:8181
4. Organization: motor_telemetry
5. Bucket: sensors
6. Token: (paste from `.influxdb-grafana-token` file)
7. Test & Save

---

### Step 5: Test Everything ✅ Validation Commands

**Test Motor Write Access:**

```bash
curl -X POST 'http://localhost:8181/api/v3/write?org=motor_telemetry&bucket=sensors' \
  -H "Authorization: Bearer $(cat .influxdb-motor-token)" \
  -H 'Content-Type: text/plain' \
  -d 'motor_test,id=M1 value=42 0'

# Expected: HTTP 204 (success)
```

**Test Grafana Read Access:**

```bash
curl -X POST 'http://localhost:8181/api/v3/query' \
  -H "Authorization: Bearer $(cat .influxdb-grafana-token)" \
  -H 'Content-Type: application/json' \
  -d '{"sql": "SELECT * FROM sensors LIMIT 1"}'

# Expected: JSON results (empty or with data)
```

**Test Grafana Datasource:**

```
1. Open: http://localhost:3000 (Grafana)
2. Configuration → Data Sources → InfluxDB-Motor
3. Click "Test"
4. Expected: "Data source is working"
```

---

## Browser Access (Already Working)

For accessing InfluxDB directly:

```
URL: http://localhost:8181
Username: influx_admin
Password: [from config/setup-config.yaml]
```

Or use a token for API access:

```bash
ADMIN_TOKEN=$(cat .influxdb-admin-token)
curl -H "Authorization: Bearer $ADMIN_TOKEN" \
  http://localhost:8181/api/v3/buckets
```

---

## Security Summary

### What You Get with This Setup

✅ **Browser Access:**
- Username/password authentication
- Web UI for exploration and configuration
- API token support for programmatic access

✅ **Motor Ingestion:**
- Write-only token (restricted to sensors bucket)
- Cannot read or modify data outside scope
- Secure token storage (600 file permissions)

✅ **Grafana:**
- Read-only token (restricted to sensors bucket)
- Cannot write or modify data
- Secure token storage

✅ **Token Security:**
- Tokens stored in files with 600 permissions (owner-only)
- Tokens excluded from git (.gitignore)
- Clear separation of concerns (admin/write/read)

### What You Should Do for Production

⚠️ **Required for Production:**
- [ ] Enable TLS/HTTPS (not needed for dev)
- [ ] Change default password for admin user
- [ ] Set up automated token rotation (every 90 days)
- [ ] Enable audit logging
- [ ] Restrict network access via firewall

ℹ️ **Optional for Production:**
- [ ] Implement secrets management (Vault, K8s, etc.)
- [ ] Set token expiration dates
- [ ] Network segmentation for InfluxDB
- [ ] Monitoring and alerting for auth failures

---

## File Locations Reference

```
├── scripts/
│   ├── influxdb-init.sh           ← Initial setup (already run)
│   ├── influxdb-create-tokens.sh   ← Create tokens (run after init)
│   └── influxdb-configure-token-permissions.sh ← Configuration guide
│
├── config/
│   └── setup-config.yaml           ← Base configuration with credentials
│
├── .gitignore                       ← Includes *.token patterns
│
├── INFLUXDB_V3_DOCUMENTATION.md     ← Complete reference
├── INFLUXDB_SECURITY_ANALYSIS.md    ← Gap analysis
└── INFLUXDB_SECURITY_IMPLEMENTATION_GUIDE.md ← This detailed guide
```

---

## Common Questions

### Q: Can I change the token permissions after creating them?

**A:** Yes! You can edit token permissions anytime via:
- **InfluxDB UI**: Settings → Tokens → Edit
- **HTTP API**: Use token management endpoints
- **CLI**: Limited support in InfluxDB V3 Core

### Q: What if I lose a token file?

**A:** Tokens are stored in InfluxDB. You can regenerate them:

```bash
# Delete old token (via UI): Settings → Tokens → Delete
# Recreate with script
./scripts/influxdb-create-tokens.sh
```

### Q: Can I use the same token for Motor and Grafana?

**A:** Technically yes, but **NOT RECOMMENDED**. Best practice:
- Different tokens for each service
- Each token has minimal required permissions
- If one token is compromised, others are unaffected

### Q: Why is TLS disabled by default?

**A:** Development convenience. For production:

```yaml
# Edit: config/setup-config.yaml
influxdb:
  tls:
    enabled: true
    cert_path: /etc/certs/influxdb.crt
    key_path: /etc/certs/influxdb.key
```

### Q: How do I rotate tokens?

**A:** Manual process:

```bash
# 1. Create new token
./scripts/influxdb-create-tokens.sh

# 2. Configure permissions for new token
# (Via UI as before)

# 3. Update service configs to use new token

# 4. Test new token works

# 5. Delete old token (UI: Settings → Tokens → Delete)
```

---

## Next Steps

1. **Immediate (Now):**
   - [ ] Read `INFLUXDB_SECURITY_IMPLEMENTATION_GUIDE.md`
   - [ ] Run `influxdb-create-tokens.sh`
   - [ ] Configure permissions via UI (5 minutes)
   - [ ] Test with provided curl commands

2. **Short-term (This Week):**
   - [ ] Integrate tokens into Motor Ingestion config
   - [ ] Configure Grafana datasource with token
   - [ ] Verify end-to-end data flow

3. **Medium-term (Before Production):**
   - [ ] Enable TLS/HTTPS
   - [ ] Implement token rotation procedure
   - [ ] Set up monitoring/alerting
   - [ ] Document your security procedures

4. **Long-term (Maintenance):**
   - [ ] Review token usage monthly
   - [ ] Rotate tokens every 90 days
   - [ ] Monitor for unauthorized access
   - [ ] Update as security practices evolve

---

## Support Files

All documentation is in the workspace root:

- **Technical Details**: INFLUXDB_SECURITY_IMPLEMENTATION_GUIDE.md
- **Gap Analysis**: INFLUXDB_SECURITY_ANALYSIS.md  
- **V3 Reference**: INFLUXDB_V3_DOCUMENTATION.md
- **Scripts**: scripts/influxdb-*.sh

**Start with**: INFLUXDB_SECURITY_IMPLEMENTATION_GUIDE.md (Part 4)

---

**Status**: ✅ Ready to Configure  
**Effort**: ~15 minutes for complete setup  
**Complexity**: Low (mostly clicking UI buttons)

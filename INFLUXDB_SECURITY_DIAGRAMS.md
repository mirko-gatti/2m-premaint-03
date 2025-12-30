# InfluxDB Security Architecture Diagrams

Visual reference for understanding the security setup.

---

## 1. Three Access Patterns

```
┌────────────────────────────────────────────────────────────────┐
│                    InfluxDB V3 (Core)                          │
│              Organization: motor_telemetry                      │
│              Bucket: sensors                                    │
│              Users: influx_admin, motor_app, grafana_app        │
└──────────┬──────────────────────┬────────────────────┬──────────┘
           │                      │                    │
    ┌──────▼──────┐       ┌──────▼────────┐   ┌──────▼──────┐
    │  Developer  │       │    Motor      │   │   Grafana   │
    │  Browser    │       │  Ingestion    │   │ Dashboards  │
    │   Access    │       │  Service      │   │  Service    │
    └─────────────┘       └───────────────┘   └─────────────┘
         │                       │                    │
    Credentials:            Token:              Token:
    • Username          • .influxdb-motor-     • .influxdb-
    • Password            token                  grafana-token
    • Optional Token    • Write-Only            • Read-Only
                        • To sensors bucket     • From sensors
                                                 bucket
```

---

## 2. Token Permission Hierarchy

```
BEFORE Configuration (All-Access):
┌─────────────────────────────────────────────┐
│  Token: motor_ingestion_write               │
│  Permission: ALL-ACCESS ⚠️                  │
│  - Can READ any bucket                      │
│  - Can WRITE any bucket                     │
│  - Can DELETE any bucket                    │
│  - Can manage users/orgs                    │
│  Security Risk: OVER-PRIVILEGED             │
└─────────────────────────────────────────────┘

AFTER Configuration (Least Privilege):
┌─────────────────────────────────────────────┐
│  Token: motor_ingestion_write               │
│  Permission: WRITE-ONLY ✅                  │
│  - Can WRITE to sensors bucket              │
│  - Cannot READ data                         │
│  - Cannot DELETE data                       │
│  - Cannot manage anything else              │
│  Security: LEAST PRIVILEGE                  │
└─────────────────────────────────────────────┘
```

---

## 3. Browser Access Flow

```
Developer
   │
   ├─ Option 1: Web Browser
   │     │
   │     └─→ http://localhost:8181
   │           ├─ (Redirects to login)
   │           └─ Username/Password
   │                 │
   │                 └─→ InfluxDB UI
   │                     (Session cookie)
   │
   └─ Option 2: API Tools (curl, Postman)
         │
         └─→ http://localhost:8181/api/v3/...
              ├─ HTTP Header: Authorization: Bearer TOKEN
              └─ Response: JSON data

Legend:
- Username/Password: From setup-config.yaml
- Bearer Token: From .influxdb-admin-token file
```

---

## 4. Motor Ingestion Write Flow

```
Motor Sensor Data
     │
     └─→ Motor Ingestion Service
          │
          ├─ Reads Token: .influxdb-motor-token
          │
          └─→ HTTP POST to InfluxDB
               │
               GET /api/v3/write?org=motor_telemetry&bucket=sensors
               │
               Header: Authorization: Bearer <MOTOR_TOKEN>
               Body: Line protocol format
                     motor_current,id=M001 current=24.5
               │
               └─→ InfluxDB Processes
                    ├─ Validates token
                    ├─ Checks permissions: WRITE on sensors bucket ✅
                    ├─ Parses line protocol
                    └─→ Stores in sensors bucket
                         │
                         └─→ Available for Grafana to read

HTTP 204: Success
HTTP 401: Invalid/missing token
HTTP 403: No write permission
```

---

## 5. Grafana Read Flow

```
Grafana Dashboard
     │
     └─→ Grafana Datasource: InfluxDB
          │
          ├─ Configuration:
          │  ├─ URL: http://influxdb:8181
          │  ├─ Organization: motor_telemetry
          │  ├─ Bucket: sensors
          │  └─ Token: <GRAFANA_TOKEN>
          │
          └─→ When user views dashboard:
               │
               HTTP POST to /api/v3/query
               │
               Header: Authorization: Bearer <GRAFANA_TOKEN>
               Body: SQL query
                     SELECT time, current FROM sensors
                           WHERE time > now() - 1h
               │
               └─→ InfluxDB Processes
                    ├─ Validates token
                    ├─ Checks permissions: READ on sensors bucket ✅
                    ├─ Executes query
                    └─→ Returns JSON results
                         │
                         └─→ Grafana renders chart

HTTP 200: Success with data
HTTP 401: Invalid/missing token
HTTP 403: No read permission
```

---

## 6. Security Boundary Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                       INFLUXDB                              │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Organization: motor_telemetry                       │   │
│  │                                                      │   │
│  │  ┌──────────────────────────────────────────────┐   │   │
│  │  │  Bucket: sensors                             │   │   │
│  │  │                                              │   │   │
│  │  │  Data (time-series)                          │   │   │
│  │  │  ├─ motor_current readings                   │   │   │
│  │  │  ├─ motor_temperature readings               │   │   │
│  │  │  └─ ...other metrics                         │   │   │
│  │  │                                              │   │   │
│  │  └──────────────────────────────────────────────┘   │   │
│  │                                                      │   │
│  │  Access Control:                                    │   │
│  │  ├─ motor_ingestion_write: WRITE ONLY              │   │
│  │  │  (Cannot read anything)                         │   │
│  │  │                                                 │   │
│  │  ├─ grafana_datasource_read: READ ONLY            │   │
│  │  │  (Cannot write anything)                        │   │
│  │  │                                                 │   │
│  │  └─ influx_admin: ALL ACCESS                       │   │
│  │     (Administration only)                          │   │
│  │                                                      │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
│  Network Isolation: motor_telemetry org                     │
│  Cannot access: other orgs, buckets, users                  │
└─────────────────────────────────────────────────────────────┘
```

---

## 7. Token Types and Scope

```
┌─────────────────────────────────────────────────────────────┐
│                       TOKEN TYPES                            │
└─────────────────────────────────────────────────────────────┘

ADMIN TOKEN (Full Access)
┌────────────────────────────────────────────────────────────┐
│ Name:        influx_admin_all_access                       │
│ Permissions: ALL-ACCESS                                    │
│ Scope:       Organization: motor_telemetry                 │
│ Use Cases:   • One-time setup                              │
│              • Administration tasks                        │
│              • Creating users/buckets                      │
│ Security:    Keep private, short-lived if possible         │
│ File:        .influxdb-admin-token                         │
└────────────────────────────────────────────────────────────┘

MOTOR INGESTION TOKEN (Write-Only)
┌────────────────────────────────────────────────────────────┐
│ Name:        motor_ingestion_write                         │
│ Permissions: WRITE                                         │
│ Scope:       Bucket: sensors only                          │
│ Use Cases:   • Data ingestion from sensors                 │
│              • Writing metrics to bucket                   │
│ Restrictions: Cannot read, delete, or manage               │
│ Security:    Service-specific, least privilege             │
│ File:        .influxdb-motor-token                         │
└────────────────────────────────────────────────────────────┘

GRAFANA READER TOKEN (Read-Only)
┌────────────────────────────────────────────────────────────┐
│ Name:        grafana_datasource_read                       │
│ Permissions: READ                                          │
│ Scope:       Bucket: sensors only                          │
│ Use Cases:   • Grafana dashboard queries                   │
│              • Data visualization                          │
│ Restrictions: Cannot write, delete, or modify              │
│ Security:    Service-specific, least privilege             │
│ File:        .influxdb-grafana-token                       │
└────────────────────────────────────────────────────────────┘

Permission Comparison:
┌──────────────────────┬────────┬──────────┬─────────┐
│ Action               │ Admin  │ Motor    │ Grafana │
├──────────────────────┼────────┼──────────┼─────────┤
│ Read data            │   ✅   │    ❌    │   ✅    │
│ Write data           │   ✅   │    ✅    │   ❌    │
│ Delete data          │   ✅   │    ❌    │   ❌    │
│ Create buckets       │   ✅   │    ❌    │   ❌    │
│ Delete buckets       │   ✅   │    ❌    │   ❌    │
│ Manage users         │   ✅   │    ❌    │   ❌    │
│ Manage tokens        │   ✅   │    ❌    │   ❌    │
└──────────────────────┴────────┴──────────┴─────────┘
```

---

## 8. Configuration Steps Flow

```
START: InfluxDB V3 Running
  │
  ├─ STEP 1: Create Tokens
  │  └─ Run: ./scripts/influxdb-create-tokens.sh
  │     Output: 3 token files created
  │            • .influxdb-admin-token
  │            • .influxdb-motor-token
  │            • .influxdb-grafana-token
  │
  ├─ STEP 2: Configure Permissions (UI)
  │  ├─ Open: http://localhost:8181
  │  ├─ Motor Token: Set to WRITE-ONLY
  │  │  ├─ Action: Write
  │  │  └─ Resource: sensors bucket
  │  │
  │  └─ Grafana Token: Set to READ-ONLY
  │     ├─ Action: Read
  │     └─ Resource: sensors bucket
  │
  ├─ STEP 3: Integrate with Services
  │  ├─ Motor: Export INFLUXDB_TOKEN=$(cat .influxdb-motor-token)
  │  └─ Grafana: Configure datasource with token
  │
  ├─ STEP 4: Test Access
  │  ├─ Motor Write Test: curl ... POST /api/v3/write ...
  │  ├─ Grafana Read Test: curl ... POST /api/v3/query ...
  │  └─ Grafana Datasource: UI health check
  │
  └─ END: Secure Setup Complete ✅
```

---

## 9. Security Timeline

```
Timeline of Security Strength:

BEFORE Setup:
├─ No tokens: ✅ (no access needed)
└─ No encryption: ✅ (ok for localhost)

AFTER Token Creation (Step 1):
├─ All-Access tokens: ⚠️ (overprivileged)
└─ HTTP only: ⚠️ (ok for dev, not prod)

AFTER Permission Configuration (Step 2):
├─ Granular permissions: ✅ (least privilege)
└─ Motor write-only: ✅ (restricted)
└─ Grafana read-only: ✅ (restricted)

DEVELOPMENT READY (After Step 3):
├─ Proper tokens: ✅
├─ Proper permissions: ✅
├─ Service integration: ✅
└─ Testing passed: ✅

PRODUCTION READY (Add These):
├─ TLS/HTTPS: ❌ → ✅ (encrypt traffic)
├─ Token expiration: ❌ → ✅ (limit lifetime)
├─ Token rotation: ❌ → ✅ (refresh periodically)
├─ Audit logging: ❌ → ✅ (track access)
└─ Secrets management: ❌ → ✅ (vault tokens)
```

---

## 10. Permission Matrix

```
Resource Access Control:

           │ motor_telemetry org │ sensors bucket │ other buckets │ admin ops
───────────┼─────────────────────┼────────────────┼───────────────┼──────────
admin      │        ✅ (all)     │     ✅ (all)   │   ✅ (all)    │  ✅ (all)
───────────┼─────────────────────┼────────────────┼───────────────┼──────────
motor      │      ✅ (write)     │  ✅ (write)    │    ❌ (no)    │  ❌ (no)
           │    ❌ (no read)     │ ❌ (no read)   │               │
───────────┼─────────────────────┼────────────────┼───────────────┼──────────
grafana    │      ✅ (read)      │  ✅ (read)     │    ❌ (no)    │  ❌ (no)
           │   ❌ (no write)     │ ❌ (no write)  │               │
───────────┴─────────────────────┴────────────────┴───────────────┴──────────

✅ = Access granted
❌ = Access denied
```

---

## 11. Implementation Status Summary

```
┌─ COMPLETED ─────────────────────────────────────────────────┐
│                                                              │
│ ✅ Security Research                                         │
│    └─ InfluxDB V3 documentation analyzed                    │
│    └─ Token-based auth model understood                     │
│    └─ Permission scoping documented                         │
│                                                              │
│ ✅ Gap Analysis                                              │
│    └─ Current setup reviewed                                │
│    └─ Missing permission scoping identified                 │
│    └─ Severity levels assigned                              │
│                                                              │
│ ✅ Scripts Created                                           │
│    └─ influxdb-create-tokens.sh (ready to run)             │
│    └─ influxdb-configure-token-permissions.sh (ready)       │
│                                                              │
│ ✅ Documentation Written                                     │
│    └─ 6 complete guides (5 min to 30 min read)             │
│    └─ Copy-paste commands provided                          │
│    └─ Troubleshooting guide included                        │
│                                                              │
└──────────────────────────────────────────────────────────────┘

┌─ PENDING (YOUR ACTION) ──────────────────────────────────────┐
│                                                              │
│ ⏳ Run Token Creation (2 min)                                │
│    └─ Execute: ./scripts/influxdb-create-tokens.sh         │
│                                                              │
│ ⏳ Configure Permissions (5 min)                             │
│    └─ Motor: set to write-only                              │
│    └─ Grafana: set to read-only                             │
│                                                              │
│ ⏳ Integrate Services (3 min)                                │
│    └─ Motor: add token env var                              │
│    └─ Grafana: configure datasource                         │
│                                                              │
│ ⏳ Test (3 min)                                              │
│    └─ Motor write test                                      │
│    └─ Grafana read test                                     │
│    └─ Datasource health check                               │
│                                                              │
└──────────────────────────────────────────────────────────────┘

TOTAL EFFORT: ~15 MINUTES
```

---

## 12. Security Comparison: Before vs. After

```
BEFORE (Current State):
┌──────────────────────────────────────────────────────┐
│ Motor Token:      ALL-ACCESS to everything 🔴        │
│ Grafana Token:    ALL-ACCESS to everything 🔴        │
│ Admin Token:      ALL-ACCESS (correct) ✅             │
│ Encryption:       HTTP only ⚠️ (ok for dev)          │
│ File Security:    600 permissions ✅                  │
│ Token Storage:    Secure files ✅                     │
│                                                      │
│ Risk Level: MEDIUM (dev ok, prod critical)          │
│ Compliance: DEV (not prod-ready)                      │
└──────────────────────────────────────────────────────┘

AFTER (After Configuration):
┌──────────────────────────────────────────────────────┐
│ Motor Token:      WRITE-ONLY to sensors ✅            │
│ Grafana Token:    READ-ONLY from sensors ✅           │
│ Admin Token:      ALL-ACCESS (correct) ✅             │
│ Encryption:       HTTP (ok for dev) ⚠️                │
│ File Security:    600 permissions ✅                  │
│ Token Storage:    Secure files ✅                     │
│ Least Privilege:  Enforced ✅                         │
│                                                      │
│ Risk Level: LOW (dev ready)                          │
│ Compliance: DEV (add TLS for prod)                    │
└──────────────────────────────────────────────────────┘
```

---

## Quick Reference Legend

```
✅ Implemented / Secure
⚠️ Warning / Needs attention
❌ Not done / Risk
🔴 Critical
🟡 Important
🟢 Good to have
❓ Optional / Future
```

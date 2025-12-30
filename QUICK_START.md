# Quick Start Guide

**For the impatient:** Get up and running in 10 minutes

---

## TL;DR - Installation (30-60 seconds reading, 5-10 minutes execution)

```bash
# 1. Clone (if not already done)
git clone git@github.com:<org>/2m-premaint-03.git
cd 2m-premaint-03

# 2. Run setup (prompts for sudo password)
./scripts/run_setup_playbook.sh
# Answer: type 'yes' when prompted

# 3. Verify (after setup completes)
./scripts/verify-setup.sh

# 4. Access services
# InfluxDB:  http://localhost:8181
# Grafana:   http://localhost:3000
# Login: admin / admin
```

**Done!** ✅

---

## What Just Happened?

The setup script:
1. ✓ Installed Docker (if needed)
2. ✓ Created Docker network
3. ✓ Started 3 containers (InfluxDB, Grafana, Motor Ingestion)
4. ✓ Created security users and tokens
5. ✓ Configured Grafana datasource
6. ✓ Generated API tokens (saved in `.influxdb-*-token` and `.grafana-*-token`)

---

## Verify It Worked

```bash
# Quick check
./scripts/verify-setup.sh

# Or manually:
docker ps                    # Shows 3 running containers
curl http://localhost:8181   # InfluxDB responds
curl http://localhost:3000   # Grafana responds
```

---

## First-Time Password Changes (Recommended)

### InfluxDB Password

1. Open http://localhost:8181
2. Default credentials: `influx_admin` / `ChangeMe!InfluxAdmin123` (see config)
3. Change password in UI

### Grafana Password

1. Open http://localhost:3000
2. Default credentials: `admin` / `admin`
3. It will prompt to change on first login
4. Set a new password

### For Production: Update Config

Before first setup, edit `config/setup-config.yaml`:

```bash
nano config/setup-config.yaml

# Find and update these sections:
# - influxdb_security.admin_user.password
# - influxdb_security.app_user.password
# - grafana_security.admin.password

# Save and run setup
./scripts/run_setup_playbook.sh
```

---

## Common Tasks

### Re-run Setup (Safe - Idempotent)

```bash
./scripts/run_setup_playbook.sh
# All tasks will report "ok" (no changes)
```

### Check Container Logs

```bash
docker logs influxdb
docker logs grafana
docker logs motor_ingestion
```

### Access Container Shell

```bash
docker exec -it influxdb /bin/bash
docker exec -it grafana /bin/bash
docker exec -it motor_ingestion /bin/bash
```

### Completely Remove Everything

```bash
./scripts/run_teardown_playbook.sh
# Type 'yes' when prompted
```

### Reinstall from Scratch

```bash
./scripts/run_teardown_playbook.sh   # Full removal
./scripts/run_setup_playbook.sh      # Fresh install
```

---

## Useful URLs & Commands

| What | How |
|------|-----|
| **InfluxDB Web UI** | http://localhost:8181 |
| **Grafana Dashboard** | http://localhost:3000 |
| **Check Containers** | `docker ps` |
| **View Logs** | `docker logs <container-name>` |
| **Stop Containers** | `docker stop <container-name>` |
| **Restart Containers** | `docker restart <container-name>` |
| **Delete Container** | `docker rm <container-name>` (stops first if running) |

---

## Troubleshooting (30 seconds)

### "Permission denied docker"

```bash
# Docker daemon needs access. Just rerun:
./scripts/run_setup_playbook.sh
```

### "Port already in use"

```bash
# Another service is on port 3000 or 8181
lsof -i :3000   # Check Grafana port
lsof -i :8181   # Check InfluxDB port

# Either stop that service or change port in config/setup-config.yaml
```

### "Container not running"

```bash
docker ps           # Check if it's running
docker logs <name>  # See why it stopped
docker start <name> # Restart it
```

### Verification script fails

```bash
# Check the detailed failures
./scripts/verify-setup.sh

# Most common: containers still starting (takes 30-60 seconds)
# Just wait a bit and run verify again
```

---

## Next Steps

1. ✓ **Setup Complete** - You have running containers
2. **Create Data** - Write test data to InfluxDB
3. **Visualize** - Create dashboards in Grafana
4. **Integrate** - Connect your motor telemetry applications
5. **Configure** - Update security settings for production

---

## Documentation Files

| File | Purpose |
|------|---------|
| **INSTALLATION_MANUAL.md** | Complete step-by-step guide |
| **SETUP_IDEMPOTENCY_AUDIT.md** | Technical issue analysis |
| **SETUP_IDEMPOTENCY_FIXES.md** | Implementation details |
| **SETUP_SCRIPT_REVIEW_COMPLETE.md** | Comprehensive review |

---

## Key Files

```
2m-premaint-03/
  ├── scripts/
  │   ├── run_setup_playbook.sh      ← Start here
  │   ├── run_teardown_playbook.sh   ← Stop & remove
  │   └── verify-setup.sh            ← Verify it works
  ├── config/
  │   └── setup-config.yaml          ← Change passwords here
  ├── ansible_scripts/
  │   ├── setup_dev_env.yml
  │   └── roles/                     ← Individual components
  └── INSTALLATION_MANUAL.md         ← Full docs
```

---

## Support

**Something not working?**

1. Run verification: `./scripts/verify-setup.sh`
2. Check logs: `docker logs <container-name>`
3. See full manual: `cat INSTALLATION_MANUAL.md`
4. Reinstall: `./scripts/run_teardown_playbook.sh && ./scripts/run_setup_playbook.sh`

---

**That's it! 🎉**

You now have:
- ✅ Docker environment
- ✅ InfluxDB time-series database
- ✅ Grafana visualization dashboard
- ✅ Motor ingestion container ready
- ✅ Security tokens configured
- ✅ API access ready

**Start using it:**
- Open http://localhost:3000 for Grafana
- Open http://localhost:8181 for InfluxDB
- Deploy your Python scripts to motor_ingestion container

# Quick Reference Card

## 🚀 Start Here After Cloning

```bash
cd 2m-premaint-03
./scripts/setup-menu.sh
```

This opens an interactive menu with all setup options.

---

## 📋 Scripts Overview

| Script | Purpose | Time | Requires Sudo |
|--------|---------|------|---|
| `setup-menu.sh` | Interactive menu for all operations | Variable | Depends |
| `check-prerequisites.sh` | Check/install system packages | 1-5 min | Yes |
| `check-ansible.sh` | Check/install Ansible | 1-3 min | Yes |
| `run_setup_playbook.sh` | Deploy all containers | 5-10 min | Yes |
| `check-environment.sh` | Detailed environment report | 1 min | No |

---

## 🎯 Setup Menu Options

1. **Check Prerequisites**
   - Verifies: curl, git, Python, Docker, sudo
   - Offers to install missing packages
   - Time: 1-5 minutes

2. **Check Ansible**
   - Verifies: Ansible installation
   - Checks: community.docker collection
   - Time: 1-3 minutes

3. **Setup Environment**
   - Runs Ansible playbook
   - Creates: Users, directories, containers, networks
   - Creates: Security tokens
   - Time: 5-10 minutes (first run)
   - ⚠️ **Requires sudo**

4. **Check Environment**
   - Detailed environment report
   - Shows: System info, tools, Docker, containers, services
   - Shows: Data directories, tokens, users, ports
   - Shows: Project structure and initialization state
   - Time: 1 minute

5. **Quick Start Guide**
   - Service access URLs
   - Docker commands reference
   - Data locations
   - Security tokens info
   - Workflow overview

6. **Exit**
   - Close the menu

---

## 🌐 Service Access

After setup completes:

| Service | URL | Default | Notes |
|---------|-----|---------|-------|
| **Grafana** | http://localhost:3000 | admin/admin | Change password! |
| **InfluxDB** | http://localhost:8181 | Token auth | See `.influxdb-admin-token` |
| **Motor Ingestion** | Docker container | Python 3.14 | View logs: `docker logs -f motor_ingestion` |

---

## 📁 Important Directories

```
/home/udev1/
├── influxdb-data/          # Database files
├── influxdb-config/        # Configuration
├── grafana-data/           # Dashboards & settings
├── grafana-provisioning/   # Provisioning configs
└── motor_ingestion/        # Application code
```

---

## 🔐 Security Tokens

Generated during setup and saved to project root:

```
.influxdb-admin-token      # InfluxDB admin access
.influxdb-motor-token      # Motor user access
.influxdb-grafana-token    # Grafana's InfluxDB access
.grafana-admin-token       # Grafana admin token
```

⚠️ **Protect these files!** Never commit to git.

---

## 🐳 Docker Quick Commands

```bash
# See all containers
docker ps -a

# View container logs
docker logs -f <name>

# Stop service
docker stop <name>

# Start service
docker start <name>

# Network info
docker network ls
docker network inspect m-network

# Container details
docker inspect <name>
```

---

## ✅ Verify Setup

```bash
# Full environment check
./scripts/check-environment.sh

# Quick setup verification
./scripts/verify-setup.sh
```

Expected results:
- ✓ All containers running
- ✓ Health checks passing
- ✓ Data directories exist
- ✓ Tokens saved
- ✓ Ports available (3000, 8181)

---

## 🆘 Quick Troubleshooting

### Docker not running
```bash
sudo systemctl start docker
sudo systemctl enable docker
```

### Can't use docker without sudo
```bash
sudo usermod -aG docker $USER
newgrp docker
```

### Port already in use
```bash
sudo lsof -i :3000    # Grafana
sudo lsof -i :8181    # InfluxDB
```

### Container won't start
```bash
docker logs <name>    # Check error messages
docker inspect <name> # View configuration
```

### Setup failed
```bash
./scripts/check-environment.sh  # Run diagnostics
./scripts/check-prerequisites.sh # Verify prerequisites
./scripts/run_setup_playbook.sh  # Try again
```

---

## 📚 Full Documentation

| Document | Purpose |
|----------|---------|
| **POST_CLONE_SETUP.md** | Main setup guide (you are here!) |
| **SETUP_GUIDE.md** | Detailed documentation |
| **INSTALLATION_MANUAL.md** | Installation details & troubleshooting |
| **QUICK_START.md** | Quick reference |
| **IMPLEMENTATION_STATUS_REPORT.md** | Implementation details |

---

## 🚀 Typical Workflow

```
1. Clone repository
   ↓
2. Run: ./scripts/setup-menu.sh
   ↓
3. Select: Check Prerequisites
   ↓
4. Select: Check Ansible
   ↓
5. Select: Setup Environment (wait 5-10 minutes)
   ↓
6. Select: Check Environment (verify all ✓)
   ↓
7. Access services:
   - Grafana: http://localhost:3000
   - InfluxDB: http://localhost:8181
   ↓
8. Configure and use!
```

---

## 💡 Pro Tips

1. **First time setup?** Use the interactive menu (`setup-menu.sh`)
2. **Need to verify?** Run `./scripts/check-environment.sh` anytime
3. **Docker issues?** Check `docker logs <container>` for details
4. **Stuck?** Script output has detailed error messages
5. **Change Grafana password** immediately after first login
6. **Backup tokens** in a secure location
7. **Monitor services** with: `docker logs -f <name>`

---

## ⏱️ Time Estimates

| Operation | First Run | Subsequent Runs |
|-----------|-----------|---|
| Prerequisites check | 1-5 min | <1 min |
| Ansible check | 1-3 min | <1 min |
| Setup environment | 5-10 min | 2-5 min |
| Environment check | 1 min | 1 min |
| **Total first setup** | **8-19 min** | — |

---

## 📞 Getting Help

1. **Check for errors** - Script output is descriptive
2. **Run diagnostics** - `./scripts/check-environment.sh`
3. **View logs** - `docker logs -f <container>`
4. **Read docs** - Check SETUP_GUIDE.md and INSTALLATION_MANUAL.md
5. **Check status** - `docker ps` and `docker ps -a`

---

**Version:** 1.0  
**Last Updated:** December 2025  
**Status:** ✓ Production Ready

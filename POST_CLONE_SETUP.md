# Post-Clone Setup Guide

## 🚀 Quick Start

After cloning this repository, run the interactive setup menu to guide you through all necessary setup steps:

```bash
cd 2m-premaint-03
./scripts/setup-menu.sh
```

This will display an interactive menu that walks you through each step of the setup process.

---

## 📋 What's New

Four new comprehensive setup scripts have been created to guide you through the entire setup process:

### 1. **setup-menu.sh** - Interactive Setup Menu (START HERE!)
The main entry point. Provides a user-friendly interactive menu with all available options.

### 2. **check-prerequisites.sh** - System Dependencies Check
Verifies all required system packages (curl, git, Docker, Python) and offers to install missing ones.

### 3. **check-ansible.sh** - Ansible Installation Check
Verifies Ansible is installed and that required collections (community.docker) are available.

### 4. **check-environment.sh** - Comprehensive Environment Verification
Provides detailed information about your entire setup with human-readable, color-coded output.

---

## 📚 Complete Documentation

See **[SETUP_GUIDE.md](SETUP_GUIDE.md)** for comprehensive documentation including:
- Detailed script descriptions
- Full workflow walkthrough
- Service access information
- Data directory locations
- Docker commands reference
- Security and token information
- Troubleshooting guide
- Maintenance tips

---

## 🎯 Typical Setup Workflow

### Option 1: Interactive Menu (Recommended for First Time)

```bash
./scripts/setup-menu.sh
```

Then follow the menu:
1. **Check Prerequisites** → Install missing system packages
2. **Check Ansible** → Ensure Ansible is ready
3. **Setup Environment** → Deploy all containers (takes 5-10 minutes)
4. **Check Environment** → Verify everything is working
5. **Quick Start Guide** → See how to access services

### Option 2: Manual Steps

```bash
# Check and install prerequisites
./scripts/check-prerequisites.sh

# Check and install Ansible
./scripts/check-ansible.sh

# Run the setup playbook
./scripts/run_setup_playbook.sh

# Verify everything is working
./scripts/check-environment.sh
```

---

## ✨ Script Features

### Color-Coded Output
All scripts use consistent color coding for easy reading:
- 🟢 **Green** - Success ✓
- 🔴 **Red** - Failure ✗
- 🟡 **Yellow** - Warning ⚠
- 🔵 **Blue** - Sections
- 🔷 **Cyan** - Details

### Interactive Features
- Clear prompts and confirmations
- Detailed error messages
- Helpful next-step recommendations
- Progress indicators

### Comprehensive Checks
The environment check includes:
- System information (OS, CPU, memory)
- Tool availability (git, curl, Python, Ansible)
- Docker installation and configuration
- Running containers and their status
- Service health (InfluxDB, Grafana, Motor Ingestion)
- Data directories and sizes
- Security tokens
- User permissions
- Port availability
- Project structure

---

## 🐳 Services After Setup

Once setup is complete, these services will be running:

| Service | URL | Purpose | Default Creds |
|---------|-----|---------|---|
| **InfluxDB** | http://localhost:8181 | Time-series database | Token in `.influxdb-admin-token` |
| **Grafana** | http://localhost:3000 | Visualization & dashboards | admin / admin ⚠️ |
| **Motor Ingestion** | Container: `motor_ingestion` | Data ingestion | Python 3.14 app |

---

## 📁 Data Locations

All persistent data is stored under `/home/udev1/`:

```
/home/udev1/
├── influxdb-data/        # InfluxDB time-series data
├── influxdb-config/      # InfluxDB configuration
├── grafana-data/         # Grafana dashboards and configuration
├── grafana-provisioning/ # Grafana provisioning configs
└── motor_ingestion/      # Motor ingestion application code
```

---

## 🔐 Security

⚠️ **Important Security Notes:**

1. **Tokens are generated automatically** during setup
2. **Token files** (`.influxdb-*-token`, `.grafana-admin-token`) are saved locally
3. **Default Grafana credentials** are admin/admin - **change on first login!**
4. **Never commit tokens to git** - they're in `.gitignore`
5. **Backup your tokens** in a secure location if needed

---

## 📊 Environment Verification Example

Running `./scripts/check-environment.sh` shows detailed output like:

```
╔════════════════════════════════════════════════════════════════╗
║  Docker Containers Status                                      ║
╚════════════════════════════════════════════════════════════════╝

▶ Container List
─────────────────────────────────────────────────────────────────
  Running Containers                       [✓ OK]  3 running
    Total Containers:                    3 (including stopped)

    Running containers:
      • motor_ingestion      [✓ OK]
      • grafana              [✓ OK]  Healthy, Port 3000
      • influxdb             [✓ OK]  Healthy, Port 8181

╔════════════════════════════════════════════════════════════════╗
║  Environment Check Summary                                     ║
╚════════════════════════════════════════════════════════════════╝

  Passed:   42 checks
  Warnings: 0 checks
  Failed:   0 checks

✓ Environment is fully ready!
```

---

## 🐳 Docker Commands

Common Docker commands for working with the setup:

```bash
# View running containers
docker ps

# View all containers
docker ps -a

# Follow container logs
docker logs -f <container-name>

# Stop a service
docker stop <container-name>

# Start a service
docker start <container-name>

# View network details
docker network inspect m-network

# View container details
docker inspect <container-name>
```

---

## 🔧 Troubleshooting

### Issue: "Docker daemon not running"
```bash
sudo systemctl start docker
sudo systemctl enable docker
```

### Issue: "Permission denied" when running docker
```bash
# Add your user to docker group
sudo usermod -aG docker $USER
# Activate group membership (logout/login or)
newgrp docker
```

### Issue: Containers won't start
```bash
# Check Docker daemon
sudo systemctl status docker

# Check for port conflicts
sudo lsof -i :3000  # Grafana
sudo lsof -i :8181  # InfluxDB

# View container logs
docker logs <container-name>
```

### Issue: Setup playbook fails
```bash
# Run diagnostic check
./scripts/check-environment.sh

# Check prerequisites
./scripts/check-prerequisites.sh

# Try setup again
./scripts/run_setup_playbook.sh
```

---

## 📖 Full Documentation

For complete documentation including detailed descriptions of each script, workflow, and troubleshooting:

👉 **See [SETUP_GUIDE.md](SETUP_GUIDE.md)**

Other important documentation:
- **INSTALLATION_MANUAL.md** - Detailed installation guide
- **QUICK_START.md** - Quick reference
- **IMPLEMENTATION_STATUS_REPORT.md** - Implementation details

---

## ✅ Verification Checklist

After running setup, verify everything is working:

- [ ] Run `./scripts/check-environment.sh` and confirm all checks pass
- [ ] Can access Grafana at http://localhost:3000
- [ ] Can access InfluxDB at http://localhost:8181
- [ ] Docker containers are running: `docker ps`
- [ ] Data directories exist: `ls -la /home/udev1/`
- [ ] Security tokens are saved: `ls -la | grep token`

---

## 🚦 Next Steps

1. **Run the menu:** `./scripts/setup-menu.sh`
2. **Follow the prompts** to install prerequisites and run setup
3. **Access your services** using the URLs above
4. **Configure Grafana** - change admin password and set up dashboards
5. **Start ingesting data** using Motor Ingestion container

---

## 📞 Need Help?

1. Run `./scripts/check-environment.sh` for detailed diagnostics
2. Check error messages in script output - they're very descriptive
3. Review the SETUP_GUIDE.md troubleshooting section
4. Check Docker container logs: `docker logs <container-name>`

---

**Version:** 1.0  
**Last Updated:** December 2025

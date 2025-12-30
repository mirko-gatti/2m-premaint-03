# Setup Script Idempotency Audit Report

**Date:** December 30, 2025  
**Scope:** run_setup_playbook.sh and all supporting playbooks/scripts  
**Status:** ANALYSIS COMPLETE - ISSUES IDENTIFIED

---

## Executive Summary

The setup infrastructure has **9 major idempotency issues** that prevent safe re-execution and create incomplete/inconsistent deployments on second runs. These issues span:

1. **Non-idempotent initialization scripts** - InfluxDB/Grafana initialization assumes fresh state
2. **Container removal + recreation** - Forces stop-and-restart even when healthy
3. **Udev1 user creation logic** - Has edge cases for existing users/home directories
4. **Data directory permissions** - Potential permission conflicts on re-run
5. **Error suppression without validation** - Initialization scripts ignore critical failures
6. **No state preservation checks** - Can't distinguish between "already done" and "needs doing"
7. **Confirmation prompt improvements** - Should match enhanced teardown warning format
8. **Setup playbook lacks idempotency markers** - No changed_when, `check_mode` considerations
9. **Init scripts have brittle parsing** - grep-based YAML parsing fails on format variations

---

## Detailed Issue Analysis

### ISSUE 1: InfluxDB/Grafana Initialization Scripts Are Non-Idempotent

**Severity:** HIGH - Blocks second setup run  
**Affected Files:**
- scripts/influxdb-init.sh (194 lines)
- scripts/grafana-init.sh (249 lines)

**Problem:**
Both initialization scripts use `ignore_errors: true` in the setup playbook but they are themselves NOT idempotent. They:
- Attempt to create organization/bucket/user/token on every run
- Suppress errors with `|| echo "already exists"` pattern (no actual idempotency)
- Have no way to detect if initialization already completed
- Will fail or misbehave if run twice without complete teardown
- Grafana initialization overwrites admin password every time (line 66-71)

**Impact:**
- Second setup run may fail or create duplicate resources
- Security tokens get recreated even if already configured
- Data source configuration may fail due to duplicate attempts

**Specific Code Issues:**

**influxdb-init.sh lines 96-99:**
```bash
docker exec influxdb influxdb3 org create \
    --name "$INFLUXDB_ORG" \
    2>/dev/null || echo "Organization may already exist"
```

**grafana-init.sh lines 72-80:**
```bash
curl -s -X POST \
    -u admin:admin \
    http://localhost:3000/api/admin/users/1/password \
    -H "Content-Type: application/json" \
    -d "{\"password\":\"$GRAFANA_ADMIN_PASSWORD\"}" \
    2>/dev/null && echo "Admin password set" || echo "Password may already be set"
```

This overwrites password every run - not idempotent.

**Fix Strategy:**
- Add checks before create operations (e.g., `list | grep` to see if exists)
- Store initialization state flag in /home/udev1/.setup-initialized
- Skip initialization if state flag exists
- Add `--force` flag to run playbook to bypass cache

---

### ISSUE 2: Container Removal Pattern Is Non-Idempotent

**Severity:** MEDIUM - Forces unnecessary restarts  
**Affected Files:**
- ansible_scripts/roles/run_influxdb/tasks/main.yml (line 20-24)
- ansible_scripts/roles/run_grafana/tasks/main.yml (line 17-21)
- ansible_scripts/roles/motor_ingestion/tasks/main.yml (line 25-28)

**Problem:**
All three container roles remove existing containers before running them:

```yaml
- name: Remove existing InfluxDB container (if any)
  become: true
  community.docker.docker_container:
    name: "{{ influxdb_container_name }}"
    state: absent
  ignore_errors: true
```

This means:
- Running setup twice kills and recreates all containers
- Any in-flight data processing is lost
- Persistent volumes survive but containers are destroyed
- With `restart_policy: always`, containers should restart on their own - no removal needed

**Impact:**
- Data loss if containers have buffered operations
- Downtime during second setup run
- Non-idempotent behavior (containers get killed, not verified alive)

**Fix Strategy:**
- Remove the `state: absent` tasks from all three roles
- Let containers restart via `restart_policy: always`
- Change tasks to use `state: started` instead
- Let Ansible manage container state idempotently (only restart if config changes)

---

### ISSUE 3: Udev1 User Creation Has Edge Cases

**Severity:** MEDIUM - May fail on re-run or with existing home directory  
**Affected File:** ansible_scripts/roles/setup_udev_user/tasks/main.yml

**Problem:**
The user creation logic is overly complex and has edge cases:

```yaml
- name: Create udev1 user (home directory does not exist)
  when: not udev_home_stat.stat.exists
  
- name: Create udev1 user with existing home directory
  when: udev_home_stat.stat.exists and udev_user_info.failed
```

Issues:
- Two separate create tasks create complexity
- Getent check uses `ignore_errors: true` which suppresses real failures
- If user exists but home doesn't, may fail
- If user doesn't exist but home is a file (not dir), creates incorrect state
- No validation that user was actually created

**Impact:**
- Edge case failures on re-run
- Unclear state after execution
- May leave system in partially configured state

**Fix Strategy:**
- Single user creation task with proper validation
- Use `ansible.builtin.user` module's built-in idempotency
- Add handler to verify user creation succeeded
- Remove the awkward `ignore_errors: true` pattern

---

### ISSUE 4: Data Directory Permissions On Re-run

**Severity:** MEDIUM - May cause permission conflicts  
**Affected Files:**
- ansible_scripts/roles/run_influxdb/tasks/main.yml (line 7-16)
- ansible_scripts/roles/run_grafana/tasks/main.yml (line 7-16)
- ansible_scripts/roles/motor_ingestion/tasks/main.yml (line 6-22)

**Problem:**
Data directories are created with ownership and mode:

```yaml
- name: Create InfluxDB data directory on host
  become: true
  ansible.builtin.file:
    path: "{{ influxdb_data_host_path }}"
    state: directory
    mode: '0755'
    owner: "udev1"
    group: "udev1"
```

On second run:
- If directory exists with different permissions (e.g., from docker engine)
- Ansible will correct them, but this is disruptive
- Volume mounts may have different ownership than expected

**Impact:**
- Permission mismatches on second run
- May need to fix permissions after container restart
- Containers may fail to write if ownership is wrong

**Fix Strategy:**
- Use `recurse: true` on file module to fix ownership deeply
- Add `force: true` to override any existing ownership
- Validate permissions after container start
- Document expected ownership in config

---

### ISSUE 5: Error Suppression Without Validation

**Severity:** HIGH - Hides failures silently  
**Affected Files:**
- setup_dev_env.yml (line 41-43, 48-50)
- influxdb-init.sh (multiple locations)
- grafana-init.sh (multiple locations)

**Problem:**
Setup playbook runs init scripts with:

```yaml
- name: Run InfluxDB security initialization
  ansible.builtin.command: "{{ playbook_dir }}/../scripts/influxdb-init.sh"
  register: influxdb_init_result
  changed_when: false
  ignore_errors: true   ← ❌ Hides critical failures!
  tags:
    - influxdb_security
```

Issues:
- If script fails, it's silently ignored
- `influxdb_init_result` is registered but never checked
- Initialization could partially complete without anyone knowing
- Security tokens may not be created
- Grafana datasource may not be configured

**Impact:**
- Setup appears successful but is partially broken
- Tokens not created means applications can't authenticate
- Grafana can't read InfluxDB data
- Debugging is very difficult

**Fix Strategy:**
- Remove `ignore_errors: true`
- Check exit codes before registering
- Add explicit validation tasks after initialization
- Verify tokens were created
- Verify Grafana datasource is configured
- Fail playbook if any critical step fails

---

### ISSUE 6: No State Preservation Between Runs

**Severity:** MEDIUM - Can't detect if setup partially completed  
**Affected Files:**
- All setup roles
- Both init scripts

**Problem:**
There's no way to know:
- Has setup run before on this system?
- Did InfluxDB init complete?
- Are Grafana tokens valid?
- Are containers healthy?

Setup simply repeats all steps every time with no checks.

**Impact:**
- Can't do incremental setup (fix broken part only)
- Can't validate setup completed correctly
- Operators don't know system state without manual inspection

**Fix Strategy:**
- Create state marker file: `/home/udev1/.setup-completed`
- Create init completion marker: `/home/udev1/.influxdb-initialized`
- Add setup status script to check current state
- Allow `--force` flag to skip state checks
- Make all setup roles idempotent (check before creating)

---

### ISSUE 7: Setup Confirmation Prompt Needs Enhancement

**Severity:** LOW - UX improvement  
**Affected File:** scripts/run_setup_playbook.sh (line 66-71)

**Problem:**
Current prompt:
```bash
read -p "Do you want to proceed? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]
```

This is weaker than the enhanced teardown confirmation which requires explicit "yes" and shows warnings.

**Impact:**
- Inconsistent UX between setup and teardown
- Easier to accidentally proceed with setup

**Fix Strategy:**
- Match teardown script's enhanced warning format
- Show what will happen
- Require explicit "yes" (not just any input)
- Add visual indicators like ✓ and ⚠️

---

### ISSUE 8: Setup Playbook Lacks Idempotency Markers

**Severity:** MEDIUM - Ansible can't track changes correctly  
**Affected File:** ansible_scripts/setup_dev_env.yml

**Problem:**
Most tasks don't have `changed_when: false` when they shouldn't report changes:
- Debug tasks always report changed (not a problem, just verbose)
- No `check_mode` testing considerations
- Some tasks don't validate their actual state

**Impact:**
- Confusing output on second run (appears to make changes when it shouldn't)
- Unclear what changed between runs
- Can't use with `--check` mode for safe preview

**Fix Strategy:**
- Add `changed_when: false` to read-only tasks
- Add `check_mode` support where appropriate
- Use `register` + `when: result.failed` pattern for validation

---

### ISSUE 9: Init Scripts Have Brittle YAML Parsing

**Severity:** MEDIUM - Fails on config format changes  
**Affected Files:**
- scripts/influxdb-init.sh (lines 31-40)
- scripts/grafana-init.sh (lines 27-36)

**Problem:**
Uses grep-based parsing to extract config:

```bash
INFLUXDB_ORG=$(grep "organization:" "$CONFIG_FILE" -A 1 | grep "name:" | head -1 | sed 's/.*name: //' | tr -d ' ')
```

Issues:
- Brittle - fails if YAML formatting changes
- No quotes handling (includes quotes in value)
- Comments confuse the parser
- Won't handle nested structure changes
- Different quoting styles break parsing

**Impact:**
- Minor config changes break initialization
- Hard to maintain scripts
- Values may be parsed incorrectly

**Fix Strategy:**
- Use proper YAML parser (yq if available)
- Fall back to python yaml if needed
- Improve variable validation
- Add error checking for parsing failures

---

## Summary Table

| Issue # | Category | Severity | Affects | Impact |
|---------|----------|----------|---------|--------|
| 1 | Init Scripts | HIGH | 2 files | Setup can't run twice |
| 2 | Container Logic | MEDIUM | 3 roles | Unnecessary downtime |
| 3 | User Creation | MEDIUM | 1 role | Edge case failures |
| 4 | Permissions | MEDIUM | 3 roles | Permission conflicts |
| 5 | Error Handling | HIGH | 2 files | Silent failures |
| 6 | State | MEDIUM | All | Can't verify setup |
| 7 | UX | LOW | 1 script | Inconsistent with teardown |
| 8 | Idempotency Markers | MEDIUM | 1 playbook | Confusing output |
| 9 | YAML Parsing | MEDIUM | 2 scripts | Brittle configuration |

**TOTAL ISSUES: 9**  
**HIGH SEVERITY: 2**  
**MEDIUM SEVERITY: 6**  
**LOW SEVERITY: 1**

---

## Recommended Actions

### Phase 1: Critical Fixes (Must Do)
- [ ] Fix initialization script idempotency (Issue 1)
- [ ] Remove container state: absent pattern (Issue 2)
- [ ] Fix error suppression (Issue 5)

### Phase 2: Important Improvements (Should Do)
- [ ] Add state preservation markers (Issue 6)
- [ ] Simplify udev1 user creation (Issue 3)
- [ ] Fix data directory permissions handling (Issue 4)
- [ ] Improve YAML parsing (Issue 9)

### Phase 3: UX Enhancements (Nice to Have)
- [ ] Enhance confirmation prompt (Issue 7)
- [ ] Add idempotency markers (Issue 8)

---

## Testing Strategy

After fixes are applied:

1. **First Setup Run**
   ```bash
   ./scripts/run_setup_playbook.sh
   # Expect: All containers running, tokens created, datasource configured
   ```

2. **Verify Setup Completeness**
   ```bash
   docker ps  # All 3 containers running
   ls -la /home/udev1/.influxdb-*-token  # 3 token files
   ls -la /home/udev1/.grafana-*-token   # 2 token files
   ```

3. **Second Setup Run (Idempotency Test)**
   ```bash
   ./scripts/run_setup_playbook.sh
   # Expect: All tasks report "ok" (no changes)
   # Expect: No containers killed/recreated
   # Expect: Init scripts detect already-complete state
   ```

4. **Complete Teardown-Setup Cycle**
   ```bash
   ./scripts/run_teardown_playbook.sh
   ./scripts/run_setup_playbook.sh
   # Expect: Clean deployment with all resources created
   ```

5. **Verify Data Persistence**
   ```bash
   docker exec influxdb influxdb3 bucket list --org motor_telemetry
   # Data should be accessible (volumes preserved across teardown)
   ```

---

## Notes for Implementation

- Keep backward compatibility where possible
- Document any new prerequisites (e.g., yq for YAML parsing)
- Add migration guide for existing deployments
- Test on clean Fedora 40+ system
- Verify with both sudo and non-sudo execution paths

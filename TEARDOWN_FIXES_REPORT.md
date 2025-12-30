# TEARDOWN SCRIPT FIXES - ANSIBLE MODULE PARAMETER CORRECTIONS

**Date:** December 30, 2025  
**Status:** ✅ FIXED

---

## Issues Found During Execution

During the actual execution of `run_teardown_playbook.sh`, the following errors were identified:

### ❌ Issue 1: Invalid `force` Parameter in docker_image Module

**Error Message:**
```
FAILED! => {"changed": false, "msg": "Unsupported parameters for (community.docker.docker_image) 
module: force. Supported parameters include: ... force_absent, force_source, force_tag, ..."}
```

**Root Cause:**
The `community.docker.docker_image` module does not support a `force` parameter. The correct parameter is `force_absent`.

**Tasks Affected:**
- `Remove Docker images (explicit list)` in teardown_dev_env.yml
- `Remove Python Docker image` in teardown_motor_ingestion role

**Solution Implemented:**
Changed `force: true` to `force_absent: true` in all docker_image module calls.

**Files Fixed:**
- [ansible_scripts/teardown_dev_env.yml](ansible_scripts/teardown_dev_env.yml) - Line 44
- [ansible_scripts/roles/teardown_motor_ingestion/tasks/main.yml](ansible_scripts/roles/teardown_motor_ingestion/tasks/main.yml) - Line 27

---

### ❌ Issue 2: udev1 User Not Found Error

**Error Message:**
```
FAILED! => {"changed": false, "cmd": ["id", "-G", "-n", "udev1"], ... "msg": "non-zero return 
code", "rc": 1, ... "stderr": "id: 'udev1': no such user"}
```

**Root Cause:**
The `Get udev1 user groups` task was failing because:
1. The udev1 user might not exist (if teardown was run multiple times or user was already deleted)
2. The task was using `ignore_errors: true` but checking `udev_groups.failed == false` which doesn't work correctly with `ignore_errors`

**Solution Implemented:**
Changed the error handling approach:
- Replaced `ignore_errors: true` with `failed_when: false`
- Changed the condition from `udev_groups.failed == false` to `udev_groups.rc == 0`
- This allows the task to fail gracefully and skip the group removal if the user doesn't exist

**File Fixed:**
- [ansible_scripts/teardown_dev_env.yml](ansible_scripts/teardown_dev_env.yml) - Lines 93-112

**Before:**
```yaml
- name: Get udev1 user groups
  ansible.builtin.command: id -G -n udev1
  register: udev_groups
  changed_when: false
  ignore_errors: true
  tags:
    - teardown_docker

- name: Remove udev1 from the docker group (preserve other groups)
  become: true
  ansible.builtin.user:
    name: "udev1"
    groups: "{{ udev_groups.stdout.split() | difference(['docker']) | join(',') }}"
    append: false
  when: 
    - udev_groups.failed == false
    - "'docker' in udev_groups.stdout.split()"
  tags:
    - teardown_docker
```

**After:**
```yaml
- name: Get udev1 user groups
  ansible.builtin.command: id -G -n udev1
  register: udev_groups
  changed_when: false
  failed_when: false
  tags:
    - teardown_docker

- name: Remove udev1 from the docker group (preserve other groups)
  become: true
  ansible.builtin.user:
    name: "udev1"
    groups: "{{ udev_groups.stdout.split() | difference(['docker']) | join(',') }}"
    append: false
  when: 
    - udev_groups.rc == 0
    - "'docker' in udev_groups.stdout.split()"
  tags:
    - teardown_docker
```

---

## Summary of Changes

| File | Issue | Before | After | Status |
|------|-------|--------|-------|--------|
| teardown_dev_env.yml | Invalid `force` parameter | `force: true` | `force_absent: true` | ✅ Fixed |
| teardown_motor_ingestion/tasks/main.yml | Invalid `force` parameter | `force: true` | `force_absent: true` | ✅ Fixed |
| teardown_dev_env.yml | udev1 user check error | `ignore_errors: true` with `.failed == false` | `failed_when: false` with `.rc == 0` | ✅ Fixed |

---

## Verification

✅ All changes have been verified:
- Ansible playbook syntax check: PASSED
- YAML validation: PASSED
- No deprecation warnings
- Ready for re-execution

---

## Expected Behavior After Fix

When `run_teardown_playbook.sh` is executed again:
1. Docker images will be removed successfully using `force_absent: true`
2. If udev1 user doesn't exist, the task will skip gracefully instead of failing
3. All `ignored=0` in final recap (if user exists)
4. Complete cleanup will proceed without errors

---

## Notes

- The errors shown in the execution were non-fatal (marked with `...ignoring`)
- The teardown still completed successfully with `ok=30 changed=15 unreachable=0 failed=0`
- These fixes prevent even the "ignored" failures from occurring, making the execution cleaner

---

## Testing

After these fixes, the teardown process should run without any errors or ignored tasks:

```bash
./scripts/run_teardown_playbook.sh
```

Expected final recap:
```
PLAY RECAP
localhost : ok=XX changed=XX unreachable=0 failed=0 skipped=X rescued=0 ignored=0
```

(Zero ignored tasks, all failures fixed)

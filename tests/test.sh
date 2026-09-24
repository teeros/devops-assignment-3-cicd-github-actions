#!/usr/bin/env bash
#
# tests/test.sh - Test suite for app/app.sh.
# At least 8 meaningful tests: help, system-info, invalid command,
# missing host, valid host, missing port, non-numeric port, out-of-range port.
#
set -u

APP="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/app/app.sh"
PASS=0
FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL+1)); }

check_exit() {
    local name="$1"; local expected="$2"; shift 2
    "$APP" "$@" >/tmp/assignment3-app-test.log 2>&1
    local rc=$?
    if [[ "$rc" -eq "$expected" ]]; then
        pass "$name (exit $rc)"
    else
        fail "$name (expected exit $expected, got $rc)"
        cat /tmp/assignment3-app-test.log
    fi
}

echo "======================================"
echo " Assignment 3 - Application Test Suite"
echo "======================================"
echo

# 1. help
check_exit "help succeeds"                          0 help

# 2. system-info
check_exit "system-info succeeds"                   0 system-info

# 3. invalid command
check_exit "invalid command rejected"                2 totally-bogus-command

# 4. missing command
check_exit "missing command rejected"                2

# 5. check-host missing host
check_exit "check-host missing host rejected"        2 check-host

# 6. check-host valid host
check_exit "check-host with valid host runs"         0 check-host localhost

# 7. check-port missing port
check_exit "check-port missing port rejected"        2 check-port localhost

# 8. check-port non-numeric port
check_exit "check-port non-numeric port rejected"    2 check-port localhost abc

# 9. check-port out-of-range port (too high)
check_exit "check-port out-of-range (65536) rejected" 2 check-port localhost 65536

# 10. check-port out-of-range port (zero)
check_exit "check-port out-of-range (0) rejected"     2 check-port localhost 0

echo
echo "======================================"
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo "======================================"

[[ $FAIL -eq 0 ]]

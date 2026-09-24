#!/usr/bin/env bash
#
# lint.sh - Static checks: required files exist, and bash -n over all
# Bash scripts. Runs ShellCheck too, if it's available, as an extra check.
#
set -u

PASS=0
FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL+1)); }

echo "=== Lint: required files ==="
for f in README.md app/app.sh scripts/lint.sh scripts/build.sh tests/test.sh \
         Dockerfile compose.yaml .dockerignore .github/workflows/ci.yml; do
    [[ -f "$f" ]] && pass "exists: $f" || fail "missing: $f"
done

echo
echo "=== Lint: bash -n syntax ==="
for f in app/*.sh scripts/*.sh tests/*.sh; do
    [[ -f "$f" ]] || continue
    bash -n "$f" >/dev/null 2>&1 && pass "syntax OK: $f" || fail "syntax error: $f"
done

echo
echo "=== Lint: ShellCheck (optional) ==="
if command -v shellcheck >/dev/null 2>&1; then
    for f in app/*.sh scripts/*.sh tests/*.sh; do
        [[ -f "$f" ]] || continue
        if shellcheck -S warning "$f" >/tmp/lint-shellcheck.log 2>&1; then
            pass "shellcheck: $f"
        else
            fail "shellcheck: $f"
            cat /tmp/lint-shellcheck.log
        fi
    done
else
    echo "shellcheck not installed; skipping (optional extra check)."
fi

echo
echo "Passed: $PASS  Failed: $FAIL"
[[ $FAIL -eq 0 ]]

# Intentionally broken line to demonstrate CI failure (unclosed if)
if [[ "$FAIL" -gt 0 ]

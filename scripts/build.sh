#!/usr/bin/env bash
#
# scripts/build.sh - Build the Docker image and run smoke tests against it,
# including an invalid-command test.
#
set -u

IMAGE="${DEVOPS_TOOL_IMAGE:-devops-tool}"
PASS=0
FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL+1)); }

if ! command -v docker >/dev/null 2>&1; then
    echo "ERROR: Docker is required to build and smoke test the image." >&2
    exit 2
fi

echo "=== Building image: $IMAGE ==="
if docker build -t "$IMAGE" . >/tmp/assignment3-build.log 2>&1; then
    pass "docker build succeeds"
else
    fail "docker build fails"
    cat /tmp/assignment3-build.log
    echo
    echo "Passed: $PASS  Failed: $FAIL"
    exit 1
fi

echo
echo "=== Smoke tests ==="

smoke() {
    local name="$1"; local expect="$2"; shift 2
    docker run --rm "$IMAGE" "$@" >/tmp/assignment3-smoke.log 2>&1
    local rc=$?
    if [[ "$expect" == "zero" && $rc -eq 0 ]]; then
        pass "$name (exit $rc)"
    elif [[ "$expect" == "nonzero" && $rc -ne 0 ]]; then
        pass "$name (exit $rc)"
    else
        fail "$name (exit $rc)"
        cat /tmp/assignment3-smoke.log
    fi
}

smoke "help command"              zero    help
smoke "system-info command"       zero    system-info
smoke "invalid command fails"     nonzero invalid-command

docker image rm "$IMAGE" >/dev/null 2>&1 || true

echo
echo "Passed: $PASS  Failed: $FAIL"
[[ $FAIL -eq 0 ]]

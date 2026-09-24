#!/usr/bin/env bash
#
# app.sh - Small diagnostic application with a lint/test/CI-friendly CLI.
#
# Usage:
#   app.sh system-info
#   app.sh check-host <host>
#   app.sh check-port <host> <port>
#   app.sh help
#
# Invalid input returns exit code 2.
#
set -u

print_help() {
    cat <<USAGE
Usage: app.sh <command> [arguments]

Commands:
  system-info             Display system information
  check-host <host>       Resolve and check connectivity to <host>
  check-port <host> <port>  Validate <port> and check TCP connectivity to <host>:<port>
  help                     Show this help message

Invalid commands or missing/invalid arguments return exit code 2.
USAGE
}

cmd_system_info() {
    echo "=========================================="
    echo "            SYSTEM INFORMATION"
    echo "=========================================="
    echo "Hostname        : $(hostname 2>/dev/null || echo unknown)"
    echo "Current User    : $(whoami 2>/dev/null || echo unknown)"
    echo "Date/Time       : $(date '+%Y-%m-%d %H:%M:%S %Z')"
    if [[ -f /etc/os-release ]]; then
        echo "Operating System: $(. /etc/os-release && echo "$PRETTY_NAME")"
    else
        echo "Operating System: $(uname -s)"
    fi
    echo "Kernel Version  : $(uname -r)"
    echo "Uptime          : $(uptime -p 2>/dev/null || uptime)"
    return 0
}

valid_host() {
    local host="$1"
    [[ -n "$host" ]] && [[ "$host" =~ ^[A-Za-z0-9.:_-]+$ ]]
}

resolve_host() {
    local host="$1"
    local resolved=""
    if command -v getent >/dev/null 2>&1; then
        resolved=$(getent hosts "$host" 2>/dev/null | awk '{print $1}' | head -n1)
    fi
    if [[ -z "$resolved" ]] && command -v python3 >/dev/null 2>&1; then
        resolved=$(python3 -c "import socket,sys
try:
    print(socket.gethostbyname(sys.argv[1]))
except Exception:
    pass" "$host" 2>/dev/null)
    fi
    if [[ -z "$resolved" ]] && [[ "$host" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        resolved="$host"
    fi
    echo "$resolved"
}

cmd_check_host() {
    local host="${1:-}"
    if ! valid_host "$host"; then
        echo "Error: check-host requires a valid <host> argument." >&2
        return 2
    fi

    echo "=========================================="
    echo "          HOST CHECK: $host"
    echo "=========================================="

    local resolved
    resolved=$(resolve_host "$host")
    local status=0
    if [[ -n "$resolved" ]]; then
        echo "Resolved Address: $resolved"
    else
        echo "Resolved Address: UNRESOLVED"
        status=1
    fi

    if command -v ping >/dev/null 2>&1; then
        if ping -c 1 -W 2 "$host" >/dev/null 2>&1; then
            echo "Ping             : reachable"
        else
            echo "Ping             : unreachable"
            status=1
        fi
    fi

    return "$status"
}

cmd_check_port() {
    local host="${1:-}"
    local port="${2:-}"

    if ! valid_host "$host"; then
        echo "Error: check-port requires a valid <host> argument." >&2
        return 2
    fi

    if [[ -z "$port" ]]; then
        echo "Error: check-port requires a <port> argument." >&2
        return 2
    fi

    if ! [[ "$port" =~ ^[0-9]+$ ]]; then
        echo "Error: port must be numeric." >&2
        return 2
    fi

    if (( port < 1 || port > 65535 )); then
        echo "Error: port must be between 1 and 65535." >&2
        return 2
    fi

    echo "=========================================="
    echo "          PORT CHECK: $host:$port"
    echo "=========================================="

    if timeout 3 bash -c "echo > /dev/tcp/$host/$port" >/dev/null 2>&1; then
        echo "Port $port is OPEN on $host."
        return 0
    else
        echo "Port $port is CLOSED or unreachable on $host."
        return 1
    fi
}

main() {
    local command="${1:-}"

    case "$command" in
        system-info)
            cmd_system_info
            exit $?
            ;;
        check-host)
            shift
            cmd_check_host "${1:-}"
            exit $?
            ;;
        check-port)
            shift
            cmd_check_port "${1:-}" "${2:-}"
            exit $?
            ;;
        help|--help|-h)
            print_help
            exit 0
            ;;
        "")
            echo "Error: no command supplied." >&2
            print_help >&2
            exit 2
            ;;
        *)
            echo "Error: unknown command '$command'." >&2
            print_help >&2
            exit 2
            ;;
    esac
}

main "$@"

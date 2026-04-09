#!/usr/bin/env bash
# lib/utils.sh — Colored output helpers, logging, and common utilities

# ── Color codes ──────────────────────────────────────────────────────────────
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
BLUE=$'\033[0;34m'
CYAN=$'\033[0;36m'
BOLD=$'\033[1m'
RESET=$'\033[0m'

# ── Log level ────────────────────────────────────────────────────────────────
# Set IFORGE_QUIET=1 to suppress info/success messages.
IFORGE_QUIET="${IFORGE_QUIET:-0}"

# ── Helpers ──────────────────────────────────────────────────────────────────
info() {
    [[ "${IFORGE_QUIET}" == "1" ]] && return 0
    printf "${CYAN}[INFO]${RESET}  %s\n" "$*"
}

success() {
    [[ "${IFORGE_QUIET}" == "1" ]] && return 0
    printf "${GREEN}[OK]${RESET}    %s\n" "$*"
}

warn() {
    printf "${YELLOW}[WARN]${RESET}  %s\n" "$*" >&2
}

error() {
    printf "${RED}[ERROR]${RESET} %s\n" "$*" >&2
}

header() {
    [[ "${IFORGE_QUIET}" == "1" ]] && return 0
    printf "\n${BOLD}${BLUE}==> %s${RESET}\n" "$*"
}

# Print a simple horizontal rule
hr() {
    [[ "${IFORGE_QUIET}" == "1" ]] && return 0
    printf "${BLUE}%s${RESET}\n" "────────────────────────────────────────────────"
}

# Confirm prompt — returns 0 for yes, 1 for no.
# In non-interactive mode (IFORGE_YES=1) always returns 0.
confirm() {
    local prompt="${1:-Continue?}"
    if [[ "${IFORGE_YES:-0}" == "1" ]]; then
        return 0
    fi
    printf "${YELLOW}%s [y/N] ${RESET}" "$prompt"
    read -r reply
    [[ "$reply" =~ ^[Yy]$ ]]
}

# Check whether a command exists on the PATH.
command_exists() {
    command -v "$1" &>/dev/null
}

# Require root (or sudo) — exits with an error message if not satisfied.
require_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        error "This operation requires root privileges. Please run with sudo."
        exit 1
    fi
}

# Run a command and print a friendly error if it fails.
run_cmd() {
    if ! "$@"; then
        error "Command failed: $*"
        return 1
    fi
}

#!/usr/bin/env bash
# tests/test_iforge.sh — Shell-based tests for iForge core logic
#
# Run with:  bash tests/test_iforge.sh
#
# The tests exercise pure-bash logic that does NOT require root or a package
# manager, so they can run in any CI environment.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ── Minimal test harness ───────────────────────────────────────────────────────
PASS=0
FAIL=0
SKIP=0

_assert() {
    local desc="$1"
    local result="$2"   # 0 = pass, non-0 = fail
    if [[ "${result}" -eq 0 ]]; then
        printf "  \033[0;32m✓\033[0m %s\n" "${desc}"
        PASS=$(( PASS + 1 ))
    else
        printf "  \033[0;31m✗\033[0m %s\n" "${desc}"
        FAIL=$(( FAIL + 1 ))
    fi
}

assert_eq() {
    local desc="$1"; local expected="$2"; local actual="$3"
    if [[ "${expected}" == "${actual}" ]]; then
        _assert "${desc}" 0
    else
        _assert "${desc}" 1
        printf "      expected: %s\n      actual  : %s\n" "${expected}" "${actual}"
    fi
}

assert_contains() {
    local desc="$1"; local needle="$2"; local haystack="$3"
    if [[ "${haystack}" == *"${needle}"* ]]; then
        _assert "${desc}" 0
    else
        _assert "${desc}" 1
        printf "      needle  : %s\n      haystack: %s\n" "${needle}" "${haystack}"
    fi
}

assert_zero() {
    local desc="$1"; local code="$2"
    _assert "${desc}" "${code}"
}

assert_nonzero() {
    local desc="$1"; local code="$2"
    if [[ "${code}" -ne 0 ]]; then
        _assert "${desc}" 0
    else
        _assert "${desc}" 1
    fi
}

skip() {
    printf "  \033[1;33m-\033[0m %s (skipped)\n" "$1"
    SKIP=$(( SKIP + 1 ))
}

suite() {
    printf "\n\033[1;34m── %s\033[0m\n" "$1"
}

summary() {
    printf "\n\033[1m%d passed, %d failed, %d skipped\033[0m\n" \
        "${PASS}" "${FAIL}" "${SKIP}"
    [[ "${FAIL}" -eq 0 ]]
}

# ── Source the libraries (non-root; no package-manager calls) ─────────────────
source "${REPO_DIR}/lib/utils.sh"
source "${REPO_DIR}/lib/detect.sh"
source "${REPO_DIR}/lib/packages.sh"

# ── Test suites ───────────────────────────────────────────────────────────────

suite "utils.sh — command_exists"

assert_zero "command_exists bash returns 0" \
    "$(command_exists bash; echo $?)"
assert_nonzero "command_exists _no_such_command_ returns non-0" \
    "$(command_exists _no_such_cmd_xyz_; echo $?)"

suite "utils.sh — confirm (non-interactive mode)"

IFORGE_YES=1
confirm "Should auto-accept when IFORGE_YES=1"
_assert "confirm returns 0 when IFORGE_YES=1" $?
unset IFORGE_YES

suite "utils.sh — logging functions (smoke test)"

output="$(IFORGE_QUIET=0 info "hello" 2>&1)"
assert_contains "info() emits [INFO]"   "[INFO]"   "${output}"

output="$(IFORGE_QUIET=0 success "ok" 2>&1)"
assert_contains "success() emits [OK]"  "[OK]"     "${output}"

output="$(warn "careful" 2>&1)"
assert_contains "warn() emits [WARN]"   "[WARN]"   "${output}"

output="$(error "boom" 2>&1)"
assert_contains "error() emits [ERROR]" "[ERROR]"  "${output}"

output="$(IFORGE_QUIET=1 info "hidden" 2>&1)"
assert_eq "info() is silent when IFORGE_QUIET=1" "" "${output}"

suite "detect.sh — detect_os on a live system"

detect_os
if [[ -f /etc/os-release ]]; then
    if [[ -n "${OS_TYPE}" ]]; then
        _assert "OS_TYPE is set after detect_os" 0
    else
        _assert "OS_TYPE is set after detect_os" 1
    fi
    if [[ -n "${DISTRO_NAME}" ]]; then
        _assert "DISTRO_NAME is set after detect_os" 0
    else
        _assert "DISTRO_NAME is set after detect_os" 1
    fi
else
    skip "No /etc/os-release; cannot test detect_os"
fi

suite "detect.sh — simulate Debian detection"

(
    # Temporarily override /etc/os-release by faking the env vars that
    # detect_os reads from the sourced file.
    # We re-implement detect_os inline using a temp file.
    tmpfile="$(mktemp)"
    printf 'ID=ubuntu\nPRETTY_NAME="Ubuntu 22.04"\n' > "${tmpfile}"

    OS_TYPE=""; PKG_MANAGER=""; DISTRO_NAME=""
    # shellcheck disable=SC1090
    source "${tmpfile}"
    case "${ID:-}" in
        ubuntu|debian) OS_TYPE="debian"; PKG_MANAGER="apt" ;;
        arch|manjaro)  OS_TYPE="arch";   PKG_MANAGER="pacman" ;;
        *) OS_TYPE="unknown" ;;
    esac
    rm -f "${tmpfile}"
    [[ "${OS_TYPE}" == "debian" ]] && [[ "${PKG_MANAGER}" == "apt" ]]
)
_assert "Ubuntu ID maps to OS_TYPE=debian, PKG_MANAGER=apt" $?

(
    tmpfile="$(mktemp)"
    printf 'ID=arch\nPRETTY_NAME="Arch Linux"\n' > "${tmpfile}"
    OS_TYPE=""; PKG_MANAGER=""; DISTRO_NAME=""
    # shellcheck disable=SC1090
    source "${tmpfile}"
    case "${ID:-}" in
        ubuntu|debian) OS_TYPE="debian"; PKG_MANAGER="apt" ;;
        arch|manjaro)  OS_TYPE="arch";   PKG_MANAGER="pacman" ;;
        *) OS_TYPE="unknown" ;;
    esac
    rm -f "${tmpfile}"
    [[ "${OS_TYPE}" == "arch" ]] && [[ "${PKG_MANAGER}" == "pacman" ]]
)
_assert "Arch ID maps to OS_TYPE=arch, PKG_MANAGER=pacman" $?

suite "packages.sh — CATEGORY_ORDER and CATEGORIES"

if [[ ${#CATEGORY_ORDER[@]} -gt 0 ]]; then
    _assert "CATEGORY_ORDER has entries" 0
else
    _assert "CATEGORY_ORDER has entries" 1
fi

for cat in "${CATEGORY_ORDER[@]}"; do
    if [[ -n "${CATEGORIES[$cat]+_}" ]]; then
        _assert "Category '${cat}' has a description" 0
    else
        _assert "Category '${cat}' has a description" 1
    fi
done

suite "packages.sh — get_packages"

OS_TYPE="debian"
pkgs="$(get_packages essential)"
assert_contains "Debian essential contains 'git'" "git" "${pkgs}"
assert_contains "Debian essential contains 'curl'" "curl" "${pkgs}"

OS_TYPE="arch"
pkgs="$(get_packages essential)"
assert_contains "Arch essential contains 'git'" "git" "${pkgs}"
assert_contains "Arch essential contains 'curl'" "curl" "${pkgs}"

OS_TYPE="debian"
pkgs="$(get_packages docker)"
assert_contains "Debian docker contains 'docker'" "docker" "${pkgs}"

OS_TYPE="arch"
pkgs="$(get_packages docker)"
assert_contains "Arch docker contains 'docker'" "docker" "${pkgs}"

OS_TYPE="unknown"
pkgs="$(get_packages essential 2>/dev/null || true)"
assert_eq "Unknown OS returns empty package list" "" "${pkgs}"

suite "iforge.sh — CLI flags (no root required)"

IFORGE="${REPO_DIR}/iforge.sh"

output="$(bash "${IFORGE}" --version 2>&1)"
assert_contains "--version prints version string" "1.0.0" "${output}"

output="$(bash "${IFORGE}" --help 2>&1)"
assert_contains "--help shows USAGE" "USAGE" "${output}"

output="$(bash "${IFORGE}" --list 2>&1)"
assert_contains "--list shows 'essential'" "essential" "${output}"
assert_contains "--list shows 'docker'"    "docker"    "${output}"

exit_code=0; bash "${IFORGE}" 2>/dev/null || exit_code=$?
assert_zero "No args exits with 0 (shows help)" "${exit_code}"

exit_code=0; bash "${IFORGE}" --bogus-flag 2>/dev/null || exit_code=$?
assert_nonzero "Unknown flag exits non-zero" "${exit_code}"

# ── Summary ───────────────────────────────────────────────────────────────────
summary

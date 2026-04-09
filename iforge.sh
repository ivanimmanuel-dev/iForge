#!/usr/bin/env bash
# iforge.sh — Automate your Linux dev environment setup
#
# Usage:
#   sudo ./iforge.sh [OPTIONS] [CATEGORIES...]
#
# Examples:
#   sudo ./iforge.sh --all
#   sudo ./iforge.sh --list
#   sudo ./iforge.sh essential build python
#   sudo ./iforge.sh --yes docker shell

set -euo pipefail

# ── Resolve script directory (works with symlinks) ───────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Source libraries ──────────────────────────────────────────────────────────
# shellcheck source=lib/utils.sh
source "${SCRIPT_DIR}/lib/utils.sh"
# shellcheck source=lib/detect.sh
source "${SCRIPT_DIR}/lib/detect.sh"
# shellcheck source=lib/packages.sh
source "${SCRIPT_DIR}/lib/packages.sh"
# shellcheck source=lib/install.sh
source "${SCRIPT_DIR}/lib/install.sh"

# ── Version ───────────────────────────────────────────────────────────────────
IFORGE_VERSION="1.0.0"

# ── Usage / help ──────────────────────────────────────────────────────────────
usage() {
    cat <<EOF
${BOLD}iForge ${IFORGE_VERSION}${RESET} — Dev environment setup for Linux

${BOLD}USAGE${RESET}
    sudo $0 [OPTIONS] [CATEGORY...]

${BOLD}OPTIONS${RESET}
    -a, --all           Install every category
    -l, --list          List available categories and exit
    -y, --yes           Non-interactive mode (assume yes to all prompts)
    -q, --quiet         Suppress info/success output
    -v, --version       Print version and exit
    -h, --help          Show this help message and exit

${BOLD}CATEGORIES${RESET}
    essential   Essential system tools (git, curl, vim, tmux …)
    build       Build & compilation tools (gcc, cmake, make …)
    python      Python development (python3, pip, venv …)
    node        Node.js / JavaScript (nodejs, npm …)
    docker      Docker & Docker Compose
    shell       Shell enhancements (zsh, fzf, ripgrep, bat …)
    net         Networking & debugging tools (nmap, ssh, tcpdump …)

${BOLD}EXAMPLES${RESET}
    sudo $0 --all
    sudo $0 essential build python
    sudo $0 --yes docker shell

EOF
}

list_categories() {
    header "Available categories"
    for cat in "${CATEGORY_ORDER[@]}"; do
        printf "  ${BOLD}%-12s${RESET} %s\n" "${cat}" "${CATEGORIES[$cat]}"
    done
    echo ""
}

# ── Argument parsing ──────────────────────────────────────────────────────────
OPT_ALL=0
OPT_LIST=0
SELECTED_CATEGORIES=()

parse_args() {
    if [[ $# -eq 0 ]]; then
        usage
        exit 0
    fi

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -a|--all)
                OPT_ALL=1
                ;;
            -l|--list)
                OPT_LIST=1
                ;;
            -y|--yes)
                export IFORGE_YES=1
                ;;
            -q|--quiet)
                export IFORGE_QUIET=1
                ;;
            -v|--version)
                echo "iForge ${IFORGE_VERSION}"
                exit 0
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            -*)
                error "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                # Treat as a category name
                SELECTED_CATEGORIES+=("$1")
                ;;
        esac
        shift
    done
}

# ── Validate requested categories ─────────────────────────────────────────────
validate_categories() {
    local -a invalid=()
    for cat in "${SELECTED_CATEGORIES[@]}"; do
        if [[ -z "${CATEGORIES[$cat]+_}" ]]; then
            invalid+=("${cat}")
        fi
    done
    if [[ ${#invalid[@]} -gt 0 ]]; then
        error "Unknown category/categories: ${invalid[*]}"
        echo ""
        list_categories
        exit 1
    fi
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
    parse_args "$@"

    # Detect OS early so list/help can show context
    detect_os

    if [[ "${OPT_LIST}" -eq 1 ]]; then
        list_categories
        exit 0
    fi

    # From this point on we need root
    require_root

    assert_supported_os

    header "iForge ${IFORGE_VERSION}"
    info "Detected OS: ${DISTRO_NAME} (${OS_TYPE} / ${PKG_MANAGER})"
    hr

    # Build the work list
    if [[ "${OPT_ALL}" -eq 1 ]]; then
        SELECTED_CATEGORIES=("${CATEGORY_ORDER[@]}")
    fi

    if [[ ${#SELECTED_CATEGORIES[@]} -eq 0 ]]; then
        error "No categories selected. Use --all or specify at least one category."
        usage
        exit 1
    fi

    validate_categories

    # Show what will be installed and confirm
    info "Categories to install: ${SELECTED_CATEGORIES[*]}"
    if ! confirm "Proceed with installation?"; then
        info "Aborted."
        exit 0
    fi

    update_package_index

    for cat in "${SELECTED_CATEGORIES[@]}"; do
        install_category "${cat}"
        run_post_install "${cat}"
        hr
    done

    success "iForge setup complete! You may need to log out and back in for some changes to take effect."
}

main "$@"

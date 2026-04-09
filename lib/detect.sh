#!/usr/bin/env bash
# lib/detect.sh — OS and package-manager detection

# Populated by detect_os():
OS_TYPE=""      # "debian" | "arch" | "unknown"
PKG_MANAGER=""  # "apt" | "pacman" | ""
DISTRO_NAME=""  # Human-readable distro name (e.g. "Ubuntu 22.04")

detect_os() {
    if [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        DISTRO_NAME="${PRETTY_NAME:-${NAME:-Unknown}}"

        case "${ID:-}" in
            ubuntu|debian|linuxmint|pop|kali|raspbian|elementary)
                OS_TYPE="debian"
                PKG_MANAGER="apt"
                ;;
            arch|manjaro|endeavouros|garuda|artix)
                OS_TYPE="arch"
                PKG_MANAGER="pacman"
                ;;
            *)
                # Fall back to ID_LIKE for derivative distros
                case "${ID_LIKE:-}" in
                    *debian*|*ubuntu*)
                        OS_TYPE="debian"
                        PKG_MANAGER="apt"
                        ;;
                    *arch*)
                        OS_TYPE="arch"
                        PKG_MANAGER="pacman"
                        ;;
                    *)
                        OS_TYPE="unknown"
                        PKG_MANAGER=""
                        ;;
                esac
                ;;
        esac
    else
        OS_TYPE="unknown"
        PKG_MANAGER=""
        DISTRO_NAME="Unknown"
    fi
}

# Ensure the detected OS is supported; exit otherwise.
assert_supported_os() {
    if [[ "${OS_TYPE}" == "unknown" || -z "${PKG_MANAGER}" ]]; then
        error "Unsupported operating system: ${DISTRO_NAME}"
        error "iForge currently supports Debian/Ubuntu (apt) and Arch Linux (pacman) based systems."
        exit 1
    fi
}

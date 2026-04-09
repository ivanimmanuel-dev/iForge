#!/usr/bin/env bash
# lib/packages.sh — Package category definitions for Debian/apt and Arch/pacman

# Each category has two arrays:
#   APT_<CATEGORY>   — package names for Debian/Ubuntu
#   PACMAN_<CATEGORY> — package names for Arch Linux

# ── Essential system tools ────────────────────────────────────────────────────
APT_ESSENTIAL=(
    curl
    wget
    git
    vim
    neovim
    tmux
    htop
    tree
    unzip
    zip
    jq
    software-properties-common
    apt-transport-https
    ca-certificates
    gnupg
    lsb-release
)

PACMAN_ESSENTIAL=(
    curl
    wget
    git
    vim
    neovim
    tmux
    htop
    tree
    unzip
    zip
    jq
    ca-certificates
    gnupg
)

# ── Build / compilation tools ─────────────────────────────────────────────────
APT_BUILD=(
    build-essential
    cmake
    pkg-config
    autoconf
    automake
    libtool
    libssl-dev
    libffi-dev
)

PACMAN_BUILD=(
    base-devel
    cmake
    pkg-config
    autoconf
    automake
    libtool
    openssl
    libffi
)

# ── Python development ────────────────────────────────────────────────────────
APT_PYTHON=(
    python3
    python3-pip
    python3-venv
    python3-dev
)

PACMAN_PYTHON=(
    python
    python-pip
    python-virtualenv
)

# ── Node.js / JavaScript ──────────────────────────────────────────────────────
APT_NODE=(
    nodejs
    npm
)

PACMAN_NODE=(
    nodejs
    npm
)

# ── Docker ────────────────────────────────────────────────────────────────────
APT_DOCKER=(
    docker.io
    docker-compose
)

PACMAN_DOCKER=(
    docker
    docker-compose
)

# ── Shell / terminal enhancements ─────────────────────────────────────────────
APT_SHELL=(
    zsh
    bash-completion
    fzf
    ripgrep
    fd-find
    bat
)

PACMAN_SHELL=(
    zsh
    bash-completion
    fzf
    ripgrep
    fd
    bat
)

# ── Networking / debugging tools ──────────────────────────────────────────────
APT_NET=(
    nmap
    netcat-openbsd
    dnsutils
    traceroute
    tcpdump
    openssh-server
    openssh-client
)

PACMAN_NET=(
    nmap
    openbsd-netcat
    bind-tools
    traceroute
    tcpdump
    openssh
)

# ── Available categories (display name → internal key) ───────────────────────
declare -A CATEGORIES
CATEGORIES=(
    [essential]="Essential system tools (git, curl, vim, tmux …)"
    [build]="Build & compilation tools (gcc, cmake, make …)"
    [python]="Python development (python3, pip, venv …)"
    [node]="Node.js / JavaScript (nodejs, npm …)"
    [docker]="Docker & Docker Compose"
    [shell]="Shell enhancements (zsh, fzf, ripgrep, bat …)"
    [net]="Networking & debugging tools (nmap, ssh, tcpdump …)"
)

# Ordered list so menus are deterministic
CATEGORY_ORDER=(essential build python node docker shell net)

# Return the apt or pacman package list for a given category.
# Usage: get_packages <category>   (reads OS_TYPE from the environment)
get_packages() {
    local category="${1^^}"  # uppercase
    local varname

    case "${OS_TYPE}" in
        debian)  varname="APT_${category}" ;;
        arch)    varname="PACMAN_${category}" ;;
        *)       echo ""; return 1 ;;
    esac

    # Expand the named array
    local -n _pkg_list="${varname}" 2>/dev/null || { echo ""; return 1; }
    echo "${_pkg_list[@]}"
}

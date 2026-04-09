#!/bin/bash

echo "⚡ iForge: Forging your dev environment"

#------------ DEFAULT ------------
PROFILE="performance"
DRY_RUN=false

# ------------ HELP --------------
if [[ "$1" == "--help" ]]; then
    echo "⚡ iForge CLI"
    echo ""
    echo "Usage:"
    echo "  ./install.sh --profile performance"
    echo "  ./install.sh --profile minimal"
    echo "  ./install.sh --dry-run"
    echo "  ./install.sh --version"
    exit 0
fi

# ------------ VERSION -----------
if [[ "$1" == "--version" ]]; then
    echo "iForge v0.1"
    exit 0
fi

# ------------ CORE --------------
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --profile) PROFILE="$2"; shift ;;
        --dry-run) DRY_RUN=true ;;
        *) echo "❌ Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

echo "🧠 Selected profile: $PROFILE"

# --------- OS DETECTION ---------
if [ -f /etc/arch-release ]; then
    INSTALL_CMD="sudo pacman -S --noconfirm"
elif [ -f /etc/debian_version ]; then
    INSTALL_CMD="sudo apt install -y"
else
    echo "❌ Unsupported OS"
    exit 1
fi

# ------------ HELPERS -----------
run_cmd() {
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY RUN] $1"
    else
        eval $1
    fi
}

is_installed() {
    command -v $1 >/dev/null 2>&1
}

install_packages() {
    local packages=("$@")
    local total=${#packages[@]}
    local count=0

    for pkg in "${packages[@]}"; do
        count=$((count+1))
        echo "[$count/$total] Processing $pkg..."

        if is_installed $pkg; then
            echo "✔ $pkg already installed"
        else
            run_cmd "$INSTALL_CMD $pkg"
        fi
    done
}

# ----------- PROFILES -----------
install_performance() {
    echo "🚀 Installing performance dev tools..."
    install_packages git neovim curl nodejs npm htop
}

install_minimal() {
    echo "⚡ Installing minimal setup..."
    install_packages git neovim curl
}

# ---------- EXECUTION -----------
case $PROFILE in
    performance) install_performance ;;
    minimal) install_minimal ;;
    *) echo "❌ Unknown profile"; exit 1 ;;
esac

echo "✅ Setup complete. Welcome to iForge."

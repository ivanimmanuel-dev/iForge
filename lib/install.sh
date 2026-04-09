#!/usr/bin/env bash
# lib/install.sh — Installation logic for Debian/apt and Arch/pacman systems

# Update the local package index.
update_package_index() {
    header "Updating package index"
    case "${PKG_MANAGER}" in
        apt)
            run_cmd apt-get update -qq
            ;;
        pacman)
            run_cmd pacman -Sy --noconfirm
            ;;
    esac
    success "Package index updated"
}

# Install one or more packages, skipping already-installed ones.
# Usage: install_packages pkg1 pkg2 …
install_packages() {
    local -a pkgs=("$@")
    local -a to_install=()

    for pkg in "${pkgs[@]}"; do
        if ! is_installed "${pkg}"; then
            to_install+=("${pkg}")
        else
            info "Already installed: ${pkg}"
        fi
    done

    if [[ ${#to_install[@]} -eq 0 ]]; then
        success "All packages already installed."
        return 0
    fi

    info "Installing: ${to_install[*]}"
    case "${PKG_MANAGER}" in
        apt)
            run_cmd apt-get install -y -qq "${to_install[@]}"
            ;;
        pacman)
            run_cmd pacman -S --noconfirm --needed "${to_install[@]}"
            ;;
    esac
    success "Installed: ${to_install[*]}"
}

# Check whether a package is already installed.
is_installed() {
    local pkg="$1"
    case "${PKG_MANAGER}" in
        apt)
            dpkg-query -W -f='${Status}' "${pkg}" 2>/dev/null | grep -q "install ok installed"
            ;;
        pacman)
            pacman -Q "${pkg}" &>/dev/null
            ;;
        *)
            return 1
            ;;
    esac
}

# Install a named category of packages.
# Usage: install_category <category>
install_category() {
    local category="$1"
    local desc="${CATEGORIES[$category]:-$category}"
    header "Installing category: ${desc}"

    local pkgs
    pkgs="$(get_packages "${category}")"
    if [[ -z "${pkgs}" ]]; then
        warn "No packages defined for category '${category}' on ${OS_TYPE}."
        return 1
    fi

    # Word-split the space-separated list into an array
    # shellcheck disable=SC2086
    install_packages ${pkgs}
}

# Run post-install steps that require extra configuration beyond a simple
# package install (e.g. enabling the Docker service, adding the user to a
# group, etc.).
post_install_docker() {
    header "Docker post-install"
    if command_exists systemctl; then
        run_cmd systemctl enable --now docker 2>/dev/null || warn "Could not enable Docker service (may need reboot)."
    fi
    if [[ -n "${SUDO_USER:-}" ]]; then
        run_cmd usermod -aG docker "${SUDO_USER}"
        success "Added ${SUDO_USER} to the 'docker' group. Please log out and back in."
    fi
}

post_install_zsh() {
    header "Zsh post-install"
    local target_user="${SUDO_USER:-${USER}}"
    if ! command_exists zsh; then
        warn "zsh not found; skipping shell change."
        return
    fi
    local zsh_path
    zsh_path="$(command -v zsh)"
    if [[ "$(getent passwd "${target_user}" | cut -d: -f7)" != "${zsh_path}" ]]; then
        if confirm "Set zsh as the default shell for ${target_user}?"; then
            run_cmd chsh -s "${zsh_path}" "${target_user}"
            success "Default shell changed to zsh for ${target_user}."
        fi
    else
        success "zsh is already the default shell for ${target_user}."
    fi
}

# Dispatch any post-install hooks for a given category.
run_post_install() {
    local category="$1"
    case "${category}" in
        docker) post_install_docker ;;
        shell)  post_install_zsh ;;
    esac
}

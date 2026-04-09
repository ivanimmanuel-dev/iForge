# iForge

A CLI tool that automates your Linux dev environment setup for Debian/Ubuntu (apt) and Arch-based (pacman) systems.

## Features

- **OS detection** — automatically identifies your distro and selects the right package manager
- **Category-based installs** — choose what to install: essentials, build tools, Python, Node.js, Docker, shell enhancements, or networking utilities
- **Non-interactive mode** — pass `--yes` to skip all prompts (great for scripts/CI)
- **Quiet mode** — pass `--quiet` to suppress informational output
- **Post-install hooks** — enables Docker daemon, optionally sets zsh as default shell, adds user to the `docker` group

## Supported Systems

| Distribution family | Package manager |
|---|---|
| Ubuntu, Debian, Linux Mint, Pop!\_OS, Kali, Raspberry Pi OS, elementary OS | `apt` |
| Arch Linux, Manjaro, EndeavourOS, Garuda, Artix | `pacman` |

## Quick Start

```bash
# Clone the repo
git clone https://github.com/ivanimmanuel-dev/iForge.git
cd iForge

# Make the script executable
chmod +x iforge.sh

# Install everything
sudo ./iforge.sh --all

# Or pick specific categories
sudo ./iforge.sh essential build python
```

## Usage

```
sudo ./iforge.sh [OPTIONS] [CATEGORY...]
```

### Options

| Flag | Description |
|---|---|
| `-a`, `--all` | Install every category |
| `-l`, `--list` | List available categories and exit |
| `-y`, `--yes` | Non-interactive — assume yes to all prompts |
| `-q`, `--quiet` | Suppress info/success output |
| `-v`, `--version` | Print version and exit |
| `-h`, `--help` | Show help message and exit |

### Categories

| Category | Contents |
|---|---|
| `essential` | git, curl, wget, vim, neovim, tmux, htop, tree, unzip, jq … |
| `build` | gcc/make (build-essential / base-devel), cmake, pkg-config, libssl … |
| `python` | python3, pip, venv, python3-dev |
| `node` | nodejs, npm |
| `docker` | Docker Engine, Docker Compose (+ daemon enable + group membership) |
| `shell` | zsh, bash-completion, fzf, ripgrep, fd, bat |
| `net` | nmap, netcat, dig/nslookup, traceroute, tcpdump, openssh |

### Examples

```bash
# Install all categories non-interactively
sudo ./iforge.sh --all --yes

# Install just the essentials and Python tooling
sudo ./iforge.sh essential python

# See what categories are available
./iforge.sh --list

# Quiet mode — only errors are printed
sudo ./iforge.sh --quiet --yes essential build
```

## Project Layout

```
iForge/
├── iforge.sh        # Main entry point
├── lib/
│   ├── utils.sh     # Colored output helpers (info, success, warn, error)
│   ├── detect.sh    # OS / distro detection
│   ├── packages.sh  # Package lists per category per ecosystem
│   └── install.sh   # Installation logic + post-install hooks
└── tests/
    └── test_iforge.sh  # Pure-bash test suite (no root required)
```

## Running Tests

The test suite exercises all pure-bash logic (OS detection, package lookups, CLI flags) without requiring root or a package manager:

```bash
bash tests/test_iforge.sh
```

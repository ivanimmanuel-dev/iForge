# iForge

A CLI tool that automates your Linux dev environment setup for Debian/Ubuntu (apt) and Arch-based (pacman) systems using profiles and dry-run mode.

## Features

- OS detection — automatically identifies your distro and selects the right package manager (apt or pacman)
- Profiles — choose between performance (full developer setup) or minimal (essential tools only)
- Dry-run mode — preview what would be installed without making changes
- Non-interactive mode — skips prompts for automated scripts or CI
- Smart installation — only installs missing packages

## Supported Systems

| Distribution family | Package manager |
|---|---|
| Ubuntu, Debian, Linux Mint, Pop!\_OS, Kali, Raspberry Pi OS, elementary OS | apt |
| Arch Linux, Manjaro, EndeavourOS, Garuda, Artix | pacman |

# Quick Start

## Clone the repo
git clone https://github.com/ivanimmanuel-dev/iForge.git

cd iForge

## Make the script executable
chmod +x install.sh

## Install the default profile (performance)
sudo ./install.sh

## Dry-run to see what will be installed
./install.sh --dry-run

## Run minimal profile
sudo ./install.sh --profile minimal

# Usage

sudo ./install.sh [OPTIONS]

### Options

Flag | Description
---|---
--profile [performance/minimal] | Select which set of packages to install
--dry-run | Preview installation without making changes

### Profiles

Profile | Contents
---|---
performance | git, neovim, curl, nodejs, npm, htop, and more
minimal | git, neovim, curl

# Examples

## Preview performance profile installation
./install.sh --dry-run

## Install performance profile
sudo ./install.sh

## Install minimal profile
sudo ./install.sh --profile minimal

# Project Layout

iForge/

├── install.sh 

└── README.md 

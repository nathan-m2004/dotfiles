#!/bin/bash

# --- Configuration ---
LOG_FILE="install_log.txt"
DOTFILES_DIR="$HOME/dotfiles"

# 1. Official Arch Packages (Modify this list!)
# Essentials for Hyprland: Terminal, Bar, Launcher, Notification daemon, Audio, Fonts
PKGS=(
    "stow"
    "git"
    "hyprland"
    "alacritty"
    "zsh"
    "dolphin"
    "waybar"
    "rofi"
    "swaync"
    "hyprpaper"
    "hyprsunset"
    "pipewire"
    "pipewire-pulse"
    "wireplumber"
    "xdg-desktop-portal-hyprland"
    "polkit-kde-agent"
    "hyprpolkitagent"
    "qt5-wayland"
    "qt6-wayland"
    "ttf-jetbrains-mono-nerd"
    "ttf-roboto-mono-nerd"
    "noto-fonts-emoji"
    "fastfetch"
)

# 2. AUR Packages (Modify this list!)
AUR_PKGS=(
    "visual-studio-code-bin"
    "python-pywal16"
)

# --- Functions ---

# Colors for pretty printing
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
    echo "[INFO] $1" >> "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    echo "[ERROR] $1" >> "$LOG_FILE"
}

check_yay() {
    if ! command -v yay &> /dev/null; then
        log "Yay not found. Installing..."
        sudo pacman -S --needed --noconfirm git base-devel
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        cd /tmp/yay || exit
        makepkg -si --noconfirm
        cd - || exit
        rm -rf /tmp/yay
    else
        log "Yay is already installed."
    fi
}

install_packages() {
    log "Installing Official Packages..."
    sudo yay -S --needed --noconfirm "${PKGS[@]}"

    log "Installing AUR Packages..."
    yay -S --needed --noconfirm "${AUR_PKGS[@]}"
}

stow_dotfiles() {
    log "Stowing dotfiles..."
    
    # Folders in your dotfiles directory to stow
    # This loops through all folders in the dotfiles dir (excluding .git)
    cd "$DOTFILES_DIR" || exit
    
    for folder in */ ; do
        # Remove trailing slash
        folder=${folder%/}
        
        # Skip the .git folder or install script itself if not hidden
        if [[ "$folder" == ".git" ]]; then continue; fi

        log "Stowing $folder..."
        
        # Using --adopt allows stow to overwrite existing files in target
        # WARNING: This effectively replaces system config with your repo config
        stow --adopt -v "$folder"
    done
    
    # Reset git changes caused by --adopt (optional, keeps repo clean)
    git checkout .
}

# --- Main Execution ---

log "Starting Installation..."

# 1. Update System
log "Updating system..."
sudo yay -Syu --noconfirm

# 2. Setup AUR Helper
check_yay

# 3. Install Software
install_packages

# 4. Link Configs
stow_dotfiles

log "Installation Complete! Please restart your shell or reboot."
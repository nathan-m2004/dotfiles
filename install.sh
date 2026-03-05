#!/bin/bash

# --- Configuration ---
LOG_FILE="install_log.txt"
DOTFILES_DIR="$HOME/dotfiles"

# Ask for the administrator password upfront
sudo -v

# Keep-alive: update existing `sudo` time stamp until script has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# 1. Official Arch Packages
PKGS=(
    # --- Core & Window Manager ---
    "stow"
    "git"
    "docker"
    "firefox"
    "hyprland"
    "hypridle"
    "hyprlock"
    "hyprshot"
    "xdg-desktop-portal-hyprland"
    "hyprpolkitagent"
    
    # --- Terminal & Shell ---
    "alacritty"
    "zsh"
    "fastfetch"
    
    # --- Theming & Appearance ---
    "nwg-look"
    "materia-gtk-theme"
    "papirus-icon-theme"
    "swww"
    "hyprsunset"
    
    # --- Bar, Launcher, Notifications ---
    "waybar"
    "rofi"               
    "rofi-emoji"
    "wtype"              
    "swaync"
    "libnotify"
    
    # --- File Manager (Thunar) ---
    "thunar"
    "thunar-archive-plugin"
    "thunar-volman"
    "tumbler"
    "ffmpegthumbnailer"
    "gvfs"
    "file-roller"
    
    # --- Tools & Utilities ---
    "gsimplecal"
    "wl-clipboard"
    "pacman-contrib"
    "flatpak"
    "os-prober"
    "ly"
    
    # --- Audio & Network ---
    "pipewire"
    "pipewire-pulse"
    "wireplumber"
    "network-manager-applet"
    "blueman"
    "easyeffects"
    
    # --- Fonts ---
    "ttf-roboto-mono-nerd"
    "noto-fonts-emoji"
    "noto-fonts"
    "noto-fonts-cjk"
    "ttf-font-awesome"

    # --- Applications & Media ---
    "libreoffice-still"
    "obsidian"
    "krita"
    "obs-studio"
    "qbittorrent"
    "vlc"
    "vlc-plugins-extra"
    "vlc-plugin-ffmpeg"

    # --- Virtualization ---
    "qemu-full"
    "virt-manager"

    # --- Development & Debugging ---
    "gdb"
    "perf"
    "valgrind"
)

# 2. AUR Packages
AUR_PKGS=(
    "bibata-cursor-theme" # Moved from official repos
    "python-pywal16"
    "pwvucontrol"
    "waypaper"
    "vscodium-bin"
)

# --- Functions ---

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

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
    sudo pacman -S --needed --noconfirm "${PKGS[@]}"

    log "Installing AUR Packages..."
    yay -S --needed --noconfirm "${AUR_PKGS[@]}"
}

stow_dotfiles() {
    log "Stowing dotfiles..."

    # SAFETY CHECK: Ensure repo is clean before stowing with adopt
    # This prevents accidental overwrites if you are in the middle of editing
    if [[ -n $(git status --porcelain) ]]; then
        error "Your dotfiles repo has uncommitted changes!"
        warn "Please commit or stash your changes before running the stow step."
        warn "Skipping stow to prevent data loss."
        return
    fi
    
    cd "$DOTFILES_DIR" || exit
    
    for folder in */ ; do
        folder=${folder%/}
        if [[ "$folder" == ".git" ]]; then continue; fi

        log "Stowing $folder..."
        # --adopt: If a file exists on disk (e.g., ~/.config/waybar/config), 
        # stow will move it INTO your repo and link it back.
        # This is safe because we checked that git status is clean above.
        stow --adopt -v "$folder"
    done
    
    # CRITICAL: Do NOT run 'git checkout .' here.
    # Instead, we just advise the user.
    warn "Stow complete. If existing config files were 'adopted', you will see them as modified in git status."
}

install_firefox_userjs() {
    log "Configuring Firefox user.js..."

    # 1. Source file in your dotfiles
    # Make sure you actually saved your user.js here!
    SOURCE_FILE="$HOME/dotfiles/firefox/user.js"

    if [ ! -f "$SOURCE_FILE" ]; then
        warn "File not found: $SOURCE_FILE"
        warn "Skipping Firefox config."
        return
    fi

    # 2. Find the active profile (randomized string ending in .default-release)
    PROFILE_DIR=$(find "$HOME/.mozilla/firefox" -maxdepth 1 -type d -name "*.default-release" | head -n 1)

    if [ -z "$PROFILE_DIR" ]; then
        warn "Firefox profile not found. Run Firefox once to generate it."
        return
    fi

    # 3. Create the symlink
    # This overwrites any existing user.js with your managed one
    ln -sf "$SOURCE_FILE" "$PROFILE_DIR/user.js"
    
    log "Linked user.js to: $PROFILE_DIR"
}

enable_services() {
    log "Enabling systemd services..."

    # Network Manager (Required for network-manager-applet)
    log "Enabling NetworkManager..."
    sudo systemctl enable --now NetworkManager

    # Bluetooth (Required for blueman)
    log "Enabling Bluetooth..."
    sudo systemctl enable --now bluetooth

    # Virtualization (Required for qemu/virt-manager)
    log "Enabling libvirtd..."
    sudo systemctl enable --now libvirtd
    
    # Add current user to the libvirt group so you don't need sudo for VMs
    sudo usermod -aG libvirt "$USER"
    log "Added $USER to the libvirt group."

    # Display Manager (Ly)
    # Note: We don't use '--now' here so it doesn't instantly kill your current active session
    log "Enabling Ly Display Manager..."
    sudo systemctl enable ly@tty7.service
    
    # Optional: If you plan to add Docker back into this script later, uncomment this:
    log "Enabling Docker..."
    sudo systemctl enable --now docker
}

finalize() {
    log "Making scripts executable..."
    chmod +x "$HOME/.config/waybar/scripts/"*.sh 2>/dev/null
    chmod +x "$HOME/.config/waypaper/"*.sh 2>/dev/null
}

# --- Main Execution ---

log "Starting Installation..."

# 1. Update System
log "Updating system..."
sudo pacman -Syu --noconfirm

# 2. Setup AUR Helper
check_yay

# 3. Install Software
install_packages

# 4. Enable Services
enable_services

# 5. Link Configs (Safe Mode)
stow_dotfiles

# 6. Install Firefox user.js
install_firefox_userjs

# 7. Final Permissions
finalize

log "Installation Complete! Please restart your shell or reboot."
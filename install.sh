#!/bin/bash

# --- Configuration ---
LOG_FILE="install_log.txt"
DOTFILES_DIR="$HOME/dotfiles"

# 1. Official Arch Packages
# Added: wtype (for emojis), pacman-contrib (for checkupdates), alacritty, rofi
PKGS=(
    # --- Core & Window Manager ---
    "stow"
    "git"
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
    
    # --- Theming ---
    "nwg-look"
    
    # --- Bar, Launcher, Notifications ---
    "waybar"
    "rofi"
    "rofi-emoji"
    "wtype"
    "swaync"
    "libnotify"
    
    # --- File Manager (Thunar) ---
    "thunar"
    "thunar-archive-plugin" # Right-click -> Extract
    "thunar-volman"         # Auto-mount USBs
    "tumbler"               # Image thumbnails
    "ffmpegthumbnailer"     # Video thumbnails
    "gvfs"                  # Trash & Mounting
    "file-roller"           # The actual archive tool
    
    # --- Tools ---
    "gsimplecal"
    "wl-clipboard"
    "pacman-contrib"
    "grim"
    "slurp"
    
    # --- Audio & Network ---
    "pipewire"
    "pipewire-pulse"
    "wireplumber"
    "network-manager-applet"
    "blueman"
    
    # --- Fonts ---
    "ttf-jetbrains-mono-nerd"
    "ttf-roboto-mono-nerd"
    "noto-fonts-emoji"
    "noto-fonts" 
    "noto-fonts-cjk"
    "ttf-font-awesome"
)

# 2. AUR Packages
AUR_PKGS=(
    "visual-studio-code-bin" 
    "python-pywal16"
    "pwvucontrol"
    "python-pywalfox"
    "waypaper"
    "swww"
    "hyprsunset"
    "spicetify-cli"
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

# 4. Link Configs (Safe Mode)
stow_dotfiles

# 5. Install Firefox user.js
install_firefox_userjs

# 6. Final Permissions
finalize

log "Installation Complete! Please restart your shell or reboot."
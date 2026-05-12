#!/bin/bash

# --- Configuration ---
LOG_FILE="install_log.txt"
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Fail-fast and error handling
set -e
trap 'echo -e "\033[0;31m[ERROR]\033[0m An error occurred. Exiting..."; exit 1' ERR

# Log output to file and terminal
exec > >(tee -i "$LOG_FILE") 2>&1

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
    "bibata-cursor-theme" 
    "python-pywal16"
    "pwvucontrol"
    "waypaper"
    "vscodium-bin"
    "plymouth" # Added Plymouth here
)

# --- Functions ---

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

ask() {
    local prompt="$1"
    local default="$2"
    if [ "$AUTO_YES" = true ]; then
        return 0
    fi
    local reply
    if [ "$default" = "Y" ]; then
        echo -n -e "${BLUE}[?]${NC} $prompt [Y/n]: "
        read -r reply
        [[ -z "$reply" || "$reply" =~ ^[Yy]$ ]] && return 0 || return 1
    else
        echo -n -e "${BLUE}[?]${NC} $prompt [y/N]: "
        read -r reply
        [[ "$reply" =~ ^[Yy]$ ]] && return 0 || return 1
    fi
}

usage() {
    echo -e "Usage: $0 [OPTIONS]"
    echo -e "Options:"
    echo -e "  --help, -h       Show this help message"
    echo -e "  --stow           Only link dotfiles"
    echo -e "  --packages       Only install packages and enable services"
    echo -e "  --themes         Only install themes (CyberGRUB, Plymouth)"
    echo -e "  --all            Run everything (default if no options provided)"
    echo -e "  --yes, -y        Skip interactive prompts (auto-yes)"
    exit 0
}

# --- Argument Parsing ---
RUN_ALL=true
RUN_STOW=false
RUN_PACKAGES=false
RUN_THEMES=false
AUTO_YES=false

if [ $# -gt 0 ]; then
    RUN_ALL=false
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h) usage ;;
            --stow) RUN_STOW=true ;;
            --packages) RUN_PACKAGES=true ;;
            --themes) RUN_THEMES=true ;;
            --all) RUN_ALL=true ;;
            --yes|-y) AUTO_YES=true ;;
            *) error "Unknown option: $1"; usage ;;
        esac
        shift
    done
fi

if [ "$RUN_ALL" = true ]; then
    RUN_STOW=true
    RUN_PACKAGES=true
    RUN_THEMES=true
fi

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
    log "Stowing dotfiles (including uncommitted changes)..."

    # Ensure we are in the right directory
    if [ ! -d "$DOTFILES_DIR" ]; then
        error "Dotfiles directory not found at $DOTFILES_DIR"
        return
    fi

    cd "$DOTFILES_DIR" || exit

    local BACKUP_DIR="$HOME/.dotfiles.backup_$(date +%Y%m%d_%H%M%S)"
    local BACKUP_CREATED=false

    # Loop through each directory in the dotfiles folder
    for folder in */ ; do
        folder=${folder%/}
        
        # Skip the .git folder and other hidden metadata folders
        [[ "$folder" =~ ^\..* ]] && continue

        log "Linking $folder..."
        
        # Identify broken/conflicting symlinks before stowing
        conflicts=$(stow -n -v -t "$HOME" "$folder" 2>&1 | awk -F ': ' '/existing target is/ {print $2}')
        for conflict in $conflicts; do
            if [ -L "$HOME/$conflict" ] || [ -f "$HOME/$conflict" ]; then
                if [ "$BACKUP_CREATED" = false ]; then
                    mkdir -p "$BACKUP_DIR"
                    BACKUP_CREATED=true
                    log "Created backup directory at $BACKUP_DIR"
                fi
                log "Backing up conflicting file: $conflict"
                mkdir -p "$(dirname "$BACKUP_DIR/$conflict")"
                mv "$HOME/$conflict" "$BACKUP_DIR/$conflict"
            fi
        done
        
        # --adopt: Handles conflicts by moving existing config into your repo
        # -v: Verbose output so you can see what's happening
        # -t ~: Targets your home directory
        stow --adopt -v -t "$HOME" "$folder"
    done

    # Inform the user that changes might be staged/modified now
    warn "Stow complete. If system files were newer than your dotfiles, they have been moved into $DOTFILES_DIR."
    log "Check 'git status' to see what changed."
}

install_firefox_userjs() {
    log "Configuring Firefox user.js..."

    SOURCE_FILE="$DOTFILES_DIR/firefox/user.js"

    if [ ! -f "$SOURCE_FILE" ]; then
        warn "File not found: $SOURCE_FILE"
        warn "Skipping Firefox config."
        return
    fi

    PROFILE_DIR=$(find "$HOME/.config/mozilla/firefox" -maxdepth 1 -type d -name "*.default-release" | head -n 1)

    if [ -z "$PROFILE_DIR" ]; then
        warn "Firefox profile not found. Run Firefox once to generate it."
        return
    fi

    ln -sf "$SOURCE_FILE" "$PROFILE_DIR/user.js"
    log "Linked user.js to: $PROFILE_DIR"
}

enable_services() {
    log "Enabling systemd services..."

    log "Enabling NetworkManager..."
    sudo systemctl enable --now NetworkManager

    log "Enabling Bluetooth..."
    sudo systemctl enable --now bluetooth

    log "Enabling libvirtd..."
    sudo systemctl enable --now libvirtd
    
    sudo usermod -aG libvirt "$USER"
    log "Added $USER to the libvirt group."

    log "Enabling Ly Display Manager..."
    sudo systemctl enable ly@tty7.service
    
    log "Enabling Docker..."
    sudo systemctl enable --now docker
}

install_cybergrub() {
    log "Installing CyberGRUB-2077 theme..."
    
    sudo mkdir -p /boot/grub/themes
    rm -rf /tmp/cybergrub
    git clone https://github.com/adnksharp/CyberGRUB-2077.git /tmp/cybergrub
    
    sudo cp -r /tmp/cybergrub/CyberGRUB-2077 /boot/grub/themes/
    rm -rf /tmp/cybergrub
    
    log "Updating GRUB configuration..."
    
    sudo sed -i 's/^#GRUB_TERMINAL_OUTPUT="gfxterm"/GRUB_TERMINAL_OUTPUT="gfxterm"/' /etc/default/grub
    
    if grep -q "^GRUB_THEME=" /etc/default/grub; then
        sudo sed -i 's|^GRUB_THEME=.*|GRUB_THEME="/boot/grub/themes/CyberGRUB-2077/theme.txt"|' /etc/default/grub
    else
        echo 'GRUB_THEME="/boot/grub/themes/CyberGRUB-2077/theme.txt"' | sudo tee -a /etc/default/grub > /dev/null
    fi
    
    if grep -q "^#GRUB_GFXMODE=" /etc/default/grub; then
        sudo sed -i 's/^#GRUB_GFXMODE=.*/GRUB_GFXMODE=1920x1080,auto/' /etc/default/grub
    elif grep -q "^GRUB_GFXMODE=auto" /etc/default/grub; then
        sudo sed -i 's/^GRUB_GFXMODE=auto/GRUB_GFXMODE=1920x1080,auto/' /etc/default/grub
    fi

    sudo grub-mkconfig -o /boot/grub/grub.cfg
    log "CyberGRUB-2077 installed successfully!"
}

install_plymouth() {
    log "Installing Plymouth 'Glitch' theme..."

    # 1. Download and apply the theme
    rm -rf /tmp/plymouth-themes
    git clone https://github.com/adi1090x/plymouth-themes.git /tmp/plymouth-themes
    
    sudo mkdir -p /usr/share/plymouth/themes
    sudo cp -r /tmp/plymouth-themes/pack_2/glitch /usr/share/plymouth/themes/
    rm -rf /tmp/plymouth-themes

    # 2. Add 'plymouth' to mkinitcpio.conf hooks
    # It safely injects 'plymouth' right after 'udev'
    if ! grep -q "plymouth" /etc/mkinitcpio.conf; then
        log "Adding plymouth hook to mkinitcpio.conf..."
        sudo sed -i 's/\b\(udev\)\b/\1 plymouth/' /etc/mkinitcpio.conf
    fi

    # 3. Add 'splash' to GRUB kernel parameters for the quiet boot experience
    if ! grep -q "splash" /etc/default/grub; then
        log "Adding 'splash' to GRUB parameters..."
        sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="splash /' /etc/default/grub
    fi

    # 4. Set the theme and rebuild the initramfs
    # The -R flag automatically runs mkinitcpio for you
    log "Setting Plymouth theme and rebuilding initramfs..."
    sudo plymouth-set-default-theme -R glitch

    # 5. Re-generate GRUB to apply the splash parameter
    log "Updating GRUB for Plymouth..."
    sudo grub-mkconfig -o /boot/grub/grub.cfg

    log "Plymouth setup complete!"
}

finalize() {
    log "Making scripts executable..."
    chmod +x "$HOME/.config/waybar/scripts/"*.sh 2>/dev/null
    chmod +x "$HOME/.config/waypaper/"*.sh 2>/dev/null
}

# --- Main Execution ---

log "Starting Installation..."

if [ "$RUN_PACKAGES" = true ]; then
    log "Updating system..."
    sudo pacman -Syu --noconfirm
    check_yay
    install_packages
    enable_services
fi

if [ "$RUN_STOW" = true ]; then
    stow_dotfiles
    install_firefox_userjs
    finalize
fi

if [ "$RUN_THEMES" = true ]; then
    if ask "Do you want to install the CyberGRUB-2077 theme?" "N"; then
        install_cybergrub
    else
        log "Skipping CyberGRUB theme."
    fi

    if ask "Do you want to install the Plymouth 'Glitch' theme?" "N"; then
        install_plymouth
    else
        log "Skipping Plymouth theme."
    fi
fi

log "Installation Complete! Please restart your shell or reboot."
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
        stow --adopt -v "$folder"
    done
    
    warn "Stow complete. If existing config files were 'adopted', you will see them as modified in git status."
}

install_firefox_userjs() {
    log "Configuring Firefox user.js..."

    SOURCE_FILE="$HOME/dotfiles/firefox/user.js"

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

# 7. Install CyberGRUB Theme
install_cybergrub

# 8. Install Plymouth Theme
install_plymouth

# 9. Final Permissions
finalize

log "Installation Complete! Please restart your shell or reboot."
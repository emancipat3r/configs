#!/bin/bash

# STYLED LOGGING FUNCTIONS
good() {
    echo -e "\e[1;32m[+]\e[0m $1"
}

bad() {
    echo -e "\e[1;31m[-]\e[0m $1"
}

warn() {
    echo -e "\e[1;33m[!]\e[0m $1"
}

info() {
    echo -e "\e[1m[*]\e[0m $1"
}

# ENSURE SCRIPT IS RAN WITH ROOT PRIVILEGES
if [[ $EUID -ne 0 ]]; then
    bad "This script must be run as root."
    exit 1
else
    good "Running with root privileges."
fi

# VARIABLES
ORIGINAL_USER=${SUDO_USER:-$(whoami)} # Assuming script is run with sudo
info "Configuring for user: $ORIGINAL_USER"

# INSTALL PACKAGES
info "Installing necessary packages..."
if pacman -S --noconfirm gnome-tweaks git vim tmux gnome-terminal xclip; then
    good "Packages installed successfully."
else
    bad "Failed to install packages."
    exit 1
fi

# SET SCALING FOR HIDPI
info "Setting HiDPI scaling factor..."
if sudo -u $ORIGINAL_USER gsettings set org.gnome.desktop.interface scaling-factor 2; then
    good "HiDPI scaling factor set."
else
    bad "Failed to set HiDPI scaling factor."
fi

# SET BACKGROUND
info "Setting desktop background..."
BACKGROUND_PATH="/home/$ORIGINAL_USER/Downloads/background.jpg"
if sudo -u $ORIGINAL_USER curl -sL 'https://raw.githubusercontent.com/emancipat3r/wallpapers/main/1705395666276601.jpg' -o "$BACKGROUND_PATH" &&
   sudo -u $ORIGINAL_USER gsettings set org.gnome.desktop.background picture-uri-dark "file://$BACKGROUND_PATH"; then
    good "Desktop background set."
else
    bad "Failed to set desktop background."
fi

# DOWNLOAD AND EXTRACT THEME
info "Downloading and applying Adwaita-Dark theme..."
THEME_TAR_PATH="/home/$ORIGINAL_USER/Downloads/Adwaita-Dark.tar.gz"
THEME_NAME="Adwaita-Dark"
if sudo -u $ORIGINAL_USER curl -sL 'https://raw.githubusercontent.com/emancipat3r/gnome_themes/main/148170-Adwaita-Dark.tar.gz' -o "$THEME_TAR_PATH" &&
   tar zxf "$THEME_TAR_PATH" -C /usr/share/themes/ &&
   sudo -u $ORIGINAL_USER gsettings set org.gnome.desktop.interface gtk-theme "$THEME_NAME"; then
    good "Adwaita-Dark theme applied."
else
    bad "Failed to apply Adwaita-Dark theme."
fi

# MUTE VOLUME
info "Muting system volume..."
if sudo -u $ORIGINAL_USER pactl set-sink-mute "$(pactl get-default-sink)" 1; then
    good "System volume muted."
else
    bad "Failed to mute system volume."
fi

# INSTALL OMZ
info "Installing Oh My Zsh..."
if sudo -u $ORIGINAL_USER sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"; then
    good "Oh My Zsh installed."
else
    bad "Failed to install Oh My Zsh."
    # Consider whether to exit here based on your needs
fi

# INSTALL AND SET OMZ PLUGINS
info "Installing Oh My Zsh plugins..."
PLUGIN_DIR="/home/$ORIGINAL_USER/.oh-my-zsh/plugins"
if sudo -u $ORIGINAL_USER git clone https://github.com/marlonrichert/zsh-autocomplete.git "$PLUGIN_DIR/zsh-autocomplete" &&
   sudo -u $ORIGINAL_USER git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$PLUGIN_DIR/zsh-syntax-highlighting"; then
    good "Oh My Zsh plugins installed."
    
    info "Updating .zshrc with new plugins..."
    ZSHRC_PATH="/home/$ORIGINAL_USER/.zshrc"
    if sudo -u $ORIGINAL_USER sed -i 's/plugins=(git)/plugins=(git zsh-autocomplete zsh-syntax-highlighting)/' "$ZSHRC_PATH"; then
        good ".zshrc updated with new plugins."
    else
        bad "Failed to update .zshrc with new plugins."
    fi
else
    bad "Failed to install Oh My Zsh plugins."
fi

echo -e "Please manually run \e[1m'source ~/.zshrc'\e[0m to apply zsh configurations or restart your terminal session."
good "Configuration script completed."

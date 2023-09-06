#!/bin/bash

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root."
   exit 1
fi

# Function to display progress
progress_banner() {
    echo "----------------------------------------------"
    echo "$1"
    echo "----------------------------------------------"
}

# Prompt for new administrative username and other details
read -p "Enter your new administrative username: " NEW_USER
read -p "Enter your domain name (e.g., RouteAndToot.com): " DOMAIN_NAME
read -p "Enter your email for SSL/TLS certificate notifications: " USER_EMAIL

# Update and upgrade packages
progress_banner "Starting Update and Upgrade of Packages"
apt update && apt upgrade -y

# Install necessary software
progress_banner "Installing Necessary Software"
apt install -y software-properties-common ufw fail2ban nginx certbot python3-certbot-nginx libpam-google-authenticator

# Configure UFW (Uncomplicated Firewall)
progress_banner "Configuring UFW (Uncomplicated Firewall)"
ufw allow OpenSSH
ufw allow 51820/udp
ufw allow 'Nginx Full'
ufw enable

# Enable Fail2Ban
progress_banner "Enabling Fail2Ban"
systemctl enable fail2ban
systemctl start fail2ban

# Create a new administrative user and add to sudo group
progress_banner "Creating New Administrative User"
adduser $NEW_USER
usermod -aG sudo $NEW_USER

# Lock down sudo privileges
echo "root ALL=(ALL:ALL) ALL" > /etc/sudoers
echo "$NEW_USER ALL=(ALL:ALL) ALL" >> /etc/sudoers

# Change SSH port to a random high port
NEW_SSH_PORT=$((RANDOM % 64512 + 1024))
sed -i "s/#Port 22/Port $NEW_SSH_PORT/" /etc/ssh/sshd_config

# Enable Google Authenticator for SSH
progress_banner "Setting up Google Authenticator for SSH"
su - $NEW_USER -c "google-authenticator -t -d -f -r 3 -R 30 -W"

# Update SSHD config to require 2FA
echo "AuthenticationMethods publickey,keyboard-interactive:pam" >> /etc/ssh/sshd_config

# Disable root login via SSH
progress_banner "Disabling Root Login via SSH"
sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl restart sshd

# Rest of your setup (Wireguard, Pi-hole, etc.)

# Schedule automatic updates
progress_banner "Scheduling Automatic Updates"
echo "0 0 * * 0 root apt update && apt upgrade -y && pihole -up" > /etc/cron.d/auto_update

echo "Setup complete with SSH now running on port $NEW_SSH_PORT. Further manual configuration may be needed."

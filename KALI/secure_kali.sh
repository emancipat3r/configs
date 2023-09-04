#!/bin/bash

# Function to display progress art
show_progress() {
  echo "=========================="
  echo "  $1"
  echo "=========================="
}

# Run as root
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root"
  exit 1
fi

show_progress "Updating Packages"
apt update && apt upgrade -y

show_progress "Installing UFW"
apt install ufw -y

show_progress "Enabling UFW"
ufw enable

show_progress "Configuring Firewall"
ufw allow http
ufw allow https

show_progress "Disabling Root Login via SSH"
sed -i 's/PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config

show_progress "Changing SSH Port"
random_ssh_port=$(shuf -i 1025-65535 -n 1)
sed -i "s/^#Port 22/Port $random_ssh_port/g" /etc/ssh/sshd_config

show_progress "Updating UFW Rules"
ufw allow $random_ssh_port/tcp

show_progress "Creating Non-Root User"
read -p "Enter the username for the new non-root user: " new_username
adduser $new_username
usermod -aG sudo $new_username

show_progress "Changing Hostname"
read -p "Enter the new hostname for this VPS: " new_hostname
hostnamectl set-hostname $new_hostname
echo "127.0.1.1 $new_hostname" >> /etc/hosts

show_progress "Installing Oh My Zsh"
apt install zsh -y
sudo -u $new_username sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git /home/$new_username/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions /home/$new_username/.oh-my-zsh/custom/plugins/zsh-autosuggestions
sed -i 's/plugins=(git)/plugins=(git zsh-syntax-highlighting zsh-autosuggestions)/g' /home/$new_username/.zshrc

show_progress "Installing and Configuring Fail2Ban"
apt install fail2ban -y
echo "[sshd]
enabled  = true
port     = $random_ssh_port" > /etc/fail2ban/jail.d/custom-ssh-port.conf
systemctl enable fail2ban
systemctl restart fail2ban

show_progress "Restarting SSH Service"
systemctl restart sshd

show_progress "Disabling Unused Network Protocols"
echo "install dccp /bin/true" >> /etc/modprobe.d/disable_unused_protocols.conf
echo "install sctp /bin/true" >> /etc/modprobe.d/disable_unused_protocols.conf
echo "install rds /bin/true" >> /etc/modprobe.d/disable_unused_protocols.conf
echo "install tipc /bin/true" >> /etc/modprobe.d/disable_unused_protocols.conf

echo "=========================="
echo "  Security Setup Complete"
echo "=========================="
echo "New SSH port is $random_ssh_port. You may need to reboot the system for all changes to take effect."

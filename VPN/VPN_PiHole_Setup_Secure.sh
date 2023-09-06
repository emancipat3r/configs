#!/bin/bash
# Script will install Tailscale and Pihole
# Developed and tested on Ubuntu


# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root."
   exit 1
fi

# Script Error & Failsafe
set -e				# Exits script if command ran exits with non-zero status
set -o pipefail		# Exits script if command ran within a pipeline fails

# Functions
progress_banner() {
    echo "----------------------------------------------"
    echo "$1"
    echo "----------------------------------------------"
}

prompt_for_setting() {
    local prompt_message="$1"
    local default_value="$2"
    local user_input

    echo -n "${prompt_message} [${default_value}]: "
    read user_input

    # If user input is empty, use the default value
    if [ -z "$user_input" ]; then
        echo "$default_value"
    else
        echo "$user_input"
    fi
}

# Update & Install System Software
progress_banner "Updating & Installing System Software"
apt update && apt upgrade -y
apt install -y ufw libpam-google-authenticator

# Install & Configure Tailscale
progress_banner "Installing and Configuring Tailscale"
curl -fsSL https://tailscale.com/install.sh | sh
echo 'net.ipv4.ip_forward = 1' | tee -a /etc/sysctl.conf
echo 'net.ipv6.conf.all.forwarding = 1' | tee -a /etc/sysctl.conf
sysctl -p /etc/sysctl.conf
tailscale up --advertise-exit-node --accept-dns=false

# Install PiHole
progress_banner "Installing and Configuring Pihole"

## Destination config file
mkdir -p /etc/pihole/
CONFIG_FILE="/etc/pihole/setupVars.conf"

## Prompt for settings and save them to variables
WEBPASSWORD=$(prompt_for_setting "Enter Web Password" "defaultPassword")
PIHOLE_INTERFACE=$(prompt_for_setting "Enter Pi-hole interface" "tailscale0")
IPV4_ADDRESS=$(prompt_for_setting "Enter IPv4 address" "$(tailscale ip -4)")
IPV6_ADDRESS=$(prompt_for_setting "Enter IPv6 address" "$(tailscale ip -6)")
QUERY_LOGGING=$(prompt_for_setting "Enable Query Logging (true/false)" "true")
INSTALL_WEB=$(prompt_for_setting "Install web interface (true/false)" "true")
DNSMASQ_LISTENING=$(prompt_for_setting "DNSMasq Listening (single/local/all)" "local")
PIHOLE_DNS_1=$(prompt_for_setting "Primary DNS" "1.1.1.1")
PIHOLE_DNS_2=$(prompt_for_setting "Secondary DNS" "8.8.8.8")
DNS_FQDN_REQUIRED=$(prompt_for_setting "Require FQDN for DNS queries (true/false)" "true")
DNS_BOGUS_PRIV=$(prompt_for_setting "Use DNS bogus priv (true/false)" "true")
DNSSEC=$(prompt_for_setting "Enable DNSSEC (true/false)" "true")
TEMPERATUREUNIT=$(prompt_for_setting "Temperature Unit (C/F)" "F")
WEBUIBOXEDLAYOUT=$(prompt_for_setting "Web UI Boxed Layout (boxed/traditional)" "traditional")
API_EXCLUDE_DOMAINS=$(prompt_for_setting "API Exclude Domains (comma separated)" "all")
API_EXCLUDE_CLIENTS=$(prompt_for_setting "API Exclude Clients (comma separated)" "all")
API_QUERY_LOG_SHOW=$(prompt_for_setting "API Query Log Show (all/permittedonly/blockedonly)" "nothing")
API_PRIVACY_MODE=$(prompt_for_setting "API Privacy Mode (true/false)" "true")

## Write settings to the config file
cat <<EOL > ${CONFIG_FILE} || { echo "Error: Failed to write to ${CONFIG_FILE}"; exit 1; }
WEBPASSWORD=${WEBPASSWORD}
PIHOLE_INTERFACE=${PIHOLE_INTERFACE}
IPV4_ADDRESS=${IPV4_ADDRESS}
IPV6_ADDRESS=${IPV6_ADDRESS}
QUERY_LOGGING=${QUERY_LOGGING}
INSTALL_WEB=${INSTALL_WEB}
DNSMASQ_LISTENING=${DNSMASQ_LISTENING}
PIHOLE_DNS_1=${PIHOLE_DNS_1}
PIHOLE_DNS_2=${PIHOLE_DNS_2}
DNS_FQDN_REQUIRED=${DNS_FQDN_REQUIRED}
DNS_BOGUS_PRIV=${DNS_BOGUS_PRIV}
DNSSEC=${DNSSEC}
TEMPERATUREUNIT=${TEMPERATUREUNIT}
WEBUIBOXEDLAYOUT=${WEBUIBOXEDLAYOUT}
API_EXCLUDE_DOMAINS=${API_EXCLUDE_DOMAINS}
API_EXCLUDE_CLIENTS=${API_EXCLUDE_CLIENTS}
API_QUERY_LOG_SHOW=${API_QUERY_LOG_SHOW}
API_PRIVACY_MODE=${API_PRIVACY_MODE}
EOL

echo "[*] Pihole Settings saved to ${CONFIG_FILE}"

# Running Pihole Installer
curl -sSL https://install.pi-hole.net | bash /dev/stdin --unattended
if [ $? -ne 0 ]; then
    echo "Error: Pi-hole installation failed."
    exit 1
fi

# Configure UFW
progress_banner "Configuring and Enabling UFW"
ufw allow in on tailscale0
ufw enable
ufw default deny incoming
ufw default allow outgoing
ufw delete 22/tcp
ufw reload

# Configure SSH to use 2FA
progress_banner "Configuring SSH to use Google Authenticator 2FA"
google-authenticator -t -d -f -r 3 -R 30 -w 3
#    -t => Time based counter
#    -d => Disallow token reuse
#    -f => Force writing the settings to file without prompting the user
#    -r => How many attempts to enter the correct code
#    -R => How long in seconds a user can attempt to enter the correct code
#    -w => How many codes can are valid at a time (this references the 1:30 min - 4 min window of valid codes)

# Schedule automatic updates
progress_banner "Setting up Automatic Updates"
echo "0 0 * * 0 root apt update && apt upgrade -y && pihole -up" > /etc/cron.d/auto_update

progress_banner "Setup Complete"
cat << EOF 
[!] Set this node as the Tailscale network exit node in the admin console
[!] Set this node as the DNS name server. Your Tailnet IP is - $(tailscale ip -4)
EOF	

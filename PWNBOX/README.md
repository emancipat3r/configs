# Hack the Box - Configuration Files
This directory holds my HTB PWNBox configuration files. 

PWNBox uses a user home directory called `~/my_data` for all files the PWNBox user wants to persist past PWNBox VPS teardown. Within the `~/my_data` directory, there is a bash script called `user_init` which is supposed to run every time the user spins up a new PWNBox VPS. Using this, a user can have their PWNBox configured the way they want without having to pull down all their extra Github repos into `/opt/`, installing tmux, installing zsh, installing and configuring Oh My Zsh, etcetera. Please see my `user_init` file to see my configurations

```bash
#!/bin/bash
#This script is executed every time your instance is spawned.

dconf write /org/mate/terminal/profiles/default/background-type "'solid'"

sudo apt-get install zsh tmux -y
PASS=$(cat ~/Desktop/my_credentials.txt | grep -i password | awk -F " " '{ print $2 }')
ZSH="~/.oh-my-zsh/"

chmod +x ~/my_data/*
mkdir ~/boxes
mkdir ~/repos

git clone https://github.com/emancipat3r/OSCP.git ~/repos/OSCP/
sudo git clone https://github.com/t3l3machus/Villain /opt/Villain
sudo pip3 install -r /opt/Villain/requirements.txt
sudo mkdir -p /opt/ligolo-ng
sudo wget https://github.com/nicocha30/ligolo-ng/releases/download/v0.4.3/ligolo-ng_agent_0.4.3_Linux_64bit.tar.gz -O /opt/ligolo-ng/agent.tar.gz
sudo wget https://github.com/nicocha30/ligolo-ng/releases/download/v0.4.3/ligolo-ng_proxy_0.4.3_Linux_64bit.tar.gz -O /opt/ligolo-ng/proxy.tar.gz
sudo tar xvf /opt/ligolo-ng/agent.tar.gz -C /opt/ligolo-ng/
sudo tar xvf /opt/ligolo-ng/proxy.tar.gz -C /opt/ligolo-ng/

echo $PASS | chsh $(whoami) -s `which zsh`
echo ""
curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -o ~/my_data/install.sh
chmod +x ~/my_data/install.sh 
rm -rf ~/.oh-my-zsh
~/my_data/install.sh --unattended

git clone --depth 1 -- https://github.com/marlonrichert/zsh-autocomplete.git ~/.oh-my-zsh/plugins/zsh-autocomplete
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/plugins/zsh-syntax-highlighting

sed 's/^plugins=(\(.*\)/plugins=(git zsh-autocomplete zsh-syntax-highlighting)/' ~/.zshrc

source ~/.zshrc

~/my_data/zsh_start.sh
```

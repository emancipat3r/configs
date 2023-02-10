# Hack the Box - Configuration Files
This directory holds my HTB PWNBox configuration files. 

PWNBox uses a user home directory called `~/my_data` for all files the PWNBox user wants to persist past PWNBox VPS teardown. Within the `~/my_data` directory, there is a bash script called `user_init` which is supposed to run every time the user spins up a new PWNBox VPS. Using this, a user can have their PWNBox configured the way they want without having to pull down all their extra Github repos into `/opt/`, installing tmux, installing zsh, installing and configuring Oh My Zsh, etcetera. Please see my `user_init` file to see my configurations

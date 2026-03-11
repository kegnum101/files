#!/bin/bash
# docker-install.sh
# Installs Docker CE on Ubuntu

set -e  # exit on first error

# Update package lists and install prerequisites
sudo apt update
sudo apt install -y ca-certificates curl gnupg

# Create keyrings directory if it doesn't exist
sudo install -m 0755 -d /etc/apt/keyrings

# Add Docker GPG key
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add Docker repository
echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package lists again
sudo apt update

# Install Docker packages
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Finish up the install manually
echo -e "\e[1;4;31mNow enter in the following commands:\e[0m"
echo sudo usermod -aG docker "$USER"
echo newgrp docker
echo sudo systemctl enable --now docker
echo docker --version
echo docker run hello-world

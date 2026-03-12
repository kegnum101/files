#!/bin/bash
set -e

BACKUP_FILE="brave-backup.tar.gz"
TEMP_DIR="./temp"

while true; do
    read -rp "Is the brave-backup.tar.gz backup file in this script directory OR is this a fresh install? (y/n): " answer
    case "$answer" in
        [Yy]* ) echo "Continuing install..."; break;;
        [Nn]* ) echo "Backup required. Exiting."; exit 1;;
        * ) echo "Please answer y or n.";;
    esac
done

echo "Installing Brave keyring"  
sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg

echo "Adding Brave to apt"
sudo curl -fsSLo /etc/apt/sources.list.d/brave-browser-release.sources https://brave-browser-apt-release.s3.brave.com/brave-browser.sources

echo "updating apt"
sudo apt update

echo "installing Brave"
sudo apt install brave-browser -y

if [ -f "$BACKUP_FILE" ]; then
    echo "Backup archive found. Extracting to temporary folder..."
    
    # Ensure temp folder is clean
    rm -rf "$TEMP_DIR"
    mkdir -p "$TEMP_DIR"

    # Extract everything to temp
    tar -xzf "$BACKUP_FILE" -C "$TEMP_DIR"

    # Search recursively for BraveSoftware directory
    BRAVE_DIR=$(find "$TEMP_DIR" -type d -name "BraveSoftware" | head -n 1)

    if [ -z "$BRAVE_DIR" ]; then
        echo "Error: BraveSoftware directory not found in backup."
        rm -rf "$TEMP_DIR"
        exit 1
    fi

    echo "Found BraveSoftware at $BRAVE_DIR. Copying to ~/.config..."
    
    cp -r "$BRAVE_DIR" ~/.config/

    echo "Cleaning up temp folder"
    rm -rf "$TEMP_DIR"

    echo "Brave backup restored successfully."
else
    echo "No brave-backup.tar.gz found in this directory."
    echo "Continuing with default Brave installation."
fi

#!/bin/bash
# Installs a set of useful packages on Ubuntu

set -e  # Exit immediately if a command fails

sudo apt update

sudo apt install -y \
    smartmontools \
    lm-sensors \
    mosquitto-clients \
    python3-pip \
    python3-venv \
    inotify-tools \
    zip \
    bc \
    jq

echo "All packages installed successfully!"

echo smartmontools
dpkg -s smartmontools | grep -E "Package|Status"
echo --
echo lm-sensors
dpkg -s lm-sensors | grep -E "Package|Status"
echo --
echo mosquitto-clients
dpkg -s mosquitto-clients | grep -E "Package|Status"
echo --
echo python3-pip
dpkg -s python3-pip | grep -E "Package|Status"
echo --
echo python3-venv
dpkg -s python3-venv | grep -E "Package|Status"
echo --
echo inotify-tools
dpkg -s inotify-tools | grep -E "Package|Status"
echo --
echo zip
dpkg -s zip | grep -E "Package|Status"
echo --
echo bc
dpkg -s bc | grep -E "Package|Status"
echo --
echo jq
dpkg -s jq | grep -E "Package|Status"
echo --

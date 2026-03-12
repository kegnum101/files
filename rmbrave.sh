sudo apt purge -y brave-browser

sudo rm -f /etc/apt/sources.list.d/brave-browser-release.list

sudo rm -f /usr/share/keyrings/brave-browser-archive-keyring.gpg

rm -rf ~/.config/BraveSoftware ~/.cache/BraveSoftware ~/.local/share/BraveSoftware

sudo rm -rf /opt/brave.com

sudo rm /etc/apt/sources.list.d/brave-browser-release.sources

sudo apt autoremove -y

sudo apt update

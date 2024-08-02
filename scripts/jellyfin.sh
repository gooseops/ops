#!/bin/bash
sudo apt update -y
sudo apt install curl gnupg software-properties-common -y
sudo add-apt-repository universe -y
sudo apt update -y
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://repo.jellyfin.org/jellyfin_team.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/jellyfin.gpg
cat <<EOF | sudo tee /etc/apt/sources.list.d/jellyfin.sources
Types: deb
URIs: https://repo.jellyfin.org/ubuntu
Suites: jammy
Components: main
Architectures: amd64
Signed-By: /etc/apt/keyrings/jellyfin.gpg
EOF
sudo apt update -y
sudo apt install jellyfin
sudo systemctl enable jellyfin
sudo systemctl start jellyfin
sudo systemctl status jellyfin

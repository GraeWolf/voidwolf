#!/usr/bin/env bash

set -euo pipefail

sudo xbps-install -Sy ufw

echo "Enabling and starting ufw."
systemctl enable --now ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw enable

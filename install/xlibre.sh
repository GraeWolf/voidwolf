#!/usr/bin/env bash

set -euo pipefail

# Installing the Xlibre verson of xorg

sudo mkdir -p /etc/xbps.d
printf "repository=https://github.com/xlibre-void/xlibre/releases/latest/download/\n" | sudo tee /etc/xbps.d/99-repository-xlibre.conf

# Syncronize the repository and accept the fingerprint (Y)
sudo xbps-install -S

# Install
sudo xbps-install -Syu xlibre



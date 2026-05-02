#!/usr/bin/env bash

set -euo pipefail


# Checking if kernels headers exist and if not instll them

if xbps-query -s linux-headers &>/dev/null; then
	echo "linux-headers are installed"
else
	echo "linux-headers not installed."
	echo "installing now"
	sudo xbps-install -Sy linux-headers
fi

# Install multilib and non-free repos
sudo xbps-install -Sy void-repo-nonfree void-repo-multilib void-repo-multilib-nonfree
sudo xbps-install -S

# Installing the Nvidia drivers
sudo xbps-install -Sy nvidia-dkms

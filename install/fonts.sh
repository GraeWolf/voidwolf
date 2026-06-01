#!/usr/bin/env bash

set -euo pipefail

# installing fonts
sudo xbps-install -Sy dejavu-fonts-ttf noto-fonts-ttf \
	fontconfig xdg-utils wget


# Cascadia code install 
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/CascadiaCode.zip
unzip -j CascadiaCode.zip *.ttf -d $HOME/.local/share/fonts/

# JetBrains Mono 
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip
unzip -j JetBrainsMono.zip *.ttf -d $HOME/.local/share/fonts/ 


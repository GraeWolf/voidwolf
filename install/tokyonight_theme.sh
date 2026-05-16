#/usr/bin/env bash

set -euo pipefail

if xbps-query -s git &>/dev/null; then
  echo "git is installed"
else
  echo "git is not installed."
  echo "installing now."
  sudo xbps-install -Sy git
fi

if [ -d "$HOME/.local/share/themes" ]; then
  echo "themes directory exists"
else
  echo "creating themes directory"
  mkdir -p $HOME/.local/share/themes
fi

git clone https://github.com/Fausto-Korpsvart/Tokyonight-GTK-Theme.git

cd Tokyonight-GTK-Theme/themes
./install.sh -d $HOME/.local/share/themes --tweaks black macos -t purple -c dark -l 

sudo xbps-install -Sy yaru-plus




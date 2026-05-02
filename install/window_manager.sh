#!/usr/bin/env bash

set -euo pipefail

# Install Bspwm, polybar and helper apps.
sudo xbps-install -Sy bspwm sxhkd rofi picom polybar fastfetch arandr \
           polkit-gnome gvfs udisks2 udiskie NetworkManager bluez feh \
           network-manager-applet lxappearance lxsession unzip eza bat \
		       pcmanfm xsettingsd dunst zoxide trash-cli bash-completion starship

chmod 755 bspwm/bspwmrc
chmod 644 sxhkd/sxhkdrc

ln -sfn $(pwd)/bspwm /home/$USER/.config/bspwm
ln -sfn $(pwd)/xsettingsd /home/$USER/.config/xsettingsd
ln -sfn $(pwd)/picom /home/$USER/.config/picom
ln -sfn $(pwd)/polybar /home/$USER/.config/polybar
ln -sfn $(pwd)/sxhkd /home/$USER/.config/sxhkd
ln -sfn $(pwd)/xinitrc /home/$USER/.xinitrc
ln -sfn $(pwd)/scripts /home/$USER/.local/scripts
ln -sfn $(pwd)/dunst $HOME/.config/dunst
ln -sfn $(pwd)/.bash_profile $HOME/.bash_profile
ln -sfn $(pwd)/.bashrc $HOME/.bashrc
ln -sfn $(pwd)/starship.toml $HOME/.config/starship.toml


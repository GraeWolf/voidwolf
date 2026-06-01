#!/usr/bin/env bash

set -eEo

# This theme was obtained from https://github.com/w8ste/Tokyonight-rofi-theme

sudo mv $(pwd)/rofi/tokyonight.rasi /usr/share/rofi/themes
sudo mv $(pwd)/rofi/tokyonight_big1.rasi /usr/share/rofi/themes
sudo mv $(pwd)/rofi/tokyonight_big2.rasi /usr/share/rofi/themes

ln -sfn $(pwd)/rofi $HOME/.config/rofi


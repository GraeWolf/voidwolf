#!/usr/bin/env bash

set -euo pipefail

./install/ssh_setup.sh
./install/git_setup.sh
./install/xdg_user_dirs.sh
./install/repo_install.sh
./install/nvidia.sh
./install/xlibre.sh
./install/window_manager.sh
./install/rofi.sh
./install/tokyonight_theme.sh
./install/fonts.sh
./install/ghostty.sh
./install/nvim.sh
./install/steam.sh
./install/lockscreen.sh
./install/av.sh
./install/firewall.sh
./install/qol.sh
./install/enable_services.sh

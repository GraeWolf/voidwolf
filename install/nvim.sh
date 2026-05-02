#!/usr/bin/env bash

set -euo pipefail

# Install neovim and its dependencies
sudo xbps-install -Sy neovim ripgrep fzf luarocks wget

ln -sfn $(pwd)/nvim $HOME/.config/nvim


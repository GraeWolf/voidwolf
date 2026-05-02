#!/usr/bin/env bash

set -euo pipefail

sudo xbps-install -Sy ghostty

ln -sfn $(pwd)/ghostty $HOME/.config/ghostty


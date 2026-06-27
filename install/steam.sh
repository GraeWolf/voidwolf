#!/usr/bin/env bash

set -euo pipefail

sudo xbps-install -Sy steam libgcc-32bit libstdc++-32bit libdrm-32bit libglvnd-32bit libva-32bit nvidia580-libs-32bit vulkan-loader-32bit
setsid gtk-launch steam >/dev/nll 2>&1 &

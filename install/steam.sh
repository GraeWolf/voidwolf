#!/usr/bin/env bash

set -euo pipefail

sudo xbps-install -Sy steam
setsid gtk-launch steam >/dev/nll 2>&1 &

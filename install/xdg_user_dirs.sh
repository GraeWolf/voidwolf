#!/usr/bin/env bash

set -euo pipefail

sudo xbps-install -Sy xdg-user-dirs

xdg-user-dirs-update

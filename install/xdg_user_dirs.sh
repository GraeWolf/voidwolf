#!/usr/bin/env bash

set -euo pipefial

sudo xbps-install -Sy xdg-user-dirs

xdg-user-dirs-update

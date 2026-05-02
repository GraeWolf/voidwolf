#!/usr/bin/env bash

set -euo pipefail

# Install multilib and non-free repos
sudo xbps-install -Sy void-repo-nonfree void-repo-multilib void-repo-multilib-nonfree
sudo xbps-install -S


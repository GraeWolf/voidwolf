#!/usr/bin/env bash

set -euo pipefail

echo "Enabling dbus."
sudo ln -s /etc/sv/dbus /var/service/

echo "Enabling and starting NetworkManager."
if xbps-query -s dhcpcd &>/dev/null; then
  sudo rm /var/service/dhcpcd
fi
if xbps-query -s wpa_supplicant &>/dev/null; then
  sudo rm /var/service/wpa_supplicant
fi
sudo ln -s /etc/sv/NetworkManager /var/service/

echo "Enabling and starting BlueTooth."
sudo ln -s /etc/sv/bluetoothd /var/service/

echo "Enabling time sync."
sudo ln -s /etc/sv/chronyd /var/service/

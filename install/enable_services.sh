#!/usr/bin/env bash

set -euo pipefail

echo "Enabling dbus."
sudo ln -s /etc/sv/dbus /var/service/

echo "Enabling and starting NetworkManager."
if [ -L "var/service/dhcpcd" ]; then
  sudo rm /var/service/dhcpcd
fi
if [ -L "/var/service/wpa_supplicant" ]; then
  sudo rm /var/service/wpa_supplicant
fi
sudo ln -s /etc/sv/NetworkManager /var/service/

echo "Enabling and starting BlueTooth."
sudo ln -s /etc/sv/bluetoothd /var/service/

echo "Enabling time sync."
if [ -L "/var/service/chronyd" ]; then
  echo "Chronyd already enabled"
else
  sudo ln -s /etc/sv/chronyd /var/service/
fi

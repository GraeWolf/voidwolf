#!/usr/bin/env bash

set -euo pipefail

if [ -L "/var/service/dbus" ]; then
  echo "dbus already enabled"
else
  echo "Enabling dbus."
  sudo ln -s /etc/sv/dbus /var/service/
fi

if [ -L "/var/service/dhcpcd" ]; then
  sudo rm /var/service/dhcpcd
fi
if [ -L "/var/service/wpa_supplicant" ]; then
  sudo rm /var/service/wpa_supplicant
fi

if [ -L "/var/service/NetworkManager" ]; then
  echo "NetworkManager already enabled"
else
  sudo ln -s /etc/sv/NetworkManager /var/service/
fi

if [ -L "/var/service/bluetoothd" ]; then
  echo "bluetoothd already enabled"
else
  echo "Enabling and starting BlueTooth."
  sudo ln -s /etc/sv/bluetoothd /var/service/
fi

echo "Enabling time sync."
if [ -L "/var/service/chronyd" ]; then
  echo "Chronyd already enabled"
else
  sudo ln -s /etc/sv/chronyd /var/service/
fi

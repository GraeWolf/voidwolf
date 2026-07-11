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
  sudo rm -f /etc/resolve.conf
  sudo ln -s /run/NetworkManager/resolv.conf /etc/resolv.conf
  sudo mkdir -p /etc/NetworkManager/conf.d
  cat <<EOF | sudo tee /etc/NetworkManager/conf.d/dns.conf
    [main]
    dns=none

    [global-dns]
    nameservers=1.1.1.1,1.0.0.1
    EOF
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

echo "Enabling elogind."
if [ -L "/var/service/elogind" ]; then
    echo "Elogind already enabled"
else
    sudo ln -s /etc/sv/elogind /var/service/
fi

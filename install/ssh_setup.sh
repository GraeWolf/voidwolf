#!/usr/bin/env bash

set -euo pipefail

sudo xbps-install -Sy git neovim cifs-utils gvfs-smb

#use user name to mount smb share

echo "Please enter the smb share username: "
read smbUser

echo "Enter smb share:"
read smbShare

sudo mount -t cifs -o username=$smbUser //$smbShare /mnt

# Check to see if the .data directory is mounted and the .ssh directory exists
if [ -d "/mnt/.ssh" ]; then
	cp -R "/mnt/.ssh" "$HOME/"
	chmod 700 "$HOME/.ssh"
	chmod 600 "$HOME/.ssh/id_"* "$HOME/.ssh/config"
	chmod 644 "$HOME/.ssh/"*.pub
	echo ".ssh has been copied over and permissions set"
else
	echo "Directory not found"
fi

sudo umount /mnt

# convert graewolf repo to ssh
git remote set-url origin git@github.com:GraeWolf/voidwolf.git

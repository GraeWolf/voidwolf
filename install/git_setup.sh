#!/usr/bin/env bash

set -euo pipefail

echo "Please enter your git username: "
read gitUser
git config --global user.name $gitUser

echo "Please enter the eamil used with git: "
read gitEmail
git config --global user.email gitEmail

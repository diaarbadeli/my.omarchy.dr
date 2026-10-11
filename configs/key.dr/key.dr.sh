#!/usr/bin/env bash

set -euo pipefail

if command -v keyd >/dev/null 2>&1; then
    echo "Keyd is installed."
else
    echo "Keyd is not installed."
    sudo omarchy-pkg-add keyd
fi

CONFIG_URL="https://raw.githubusercontent.com/diaarbadeli/key.dr/main/conf/keydr.conf"
TEMP_CONFIG="/tmp/keydr.conf"

curl -fsSL "$CONFIG_URL" -o "$TEMP_CONFIG"

if sudo cmp -s "$TEMP_CONFIG" /etc/keyd/default.conf; then
    echo "Keyd config is already up to date."
    rm "$TEMP_CONFIG"
    exit 0
fi

sudo rm -f /etc/keyd/default.conf.backup
sudo cp /etc/keyd/default.conf /etc/keyd/default.conf.backup
sudo cp "$TEMP_CONFIG" /etc/keyd/default.conf

rm "$TEMP_CONFIG"

sudo keyd reload

echo "Keyd config updated."

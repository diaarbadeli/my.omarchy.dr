#!/usr/bin/env bash

set -u

echo "==> Omawire"

if ! command -v wg >/dev/null 2>&1; then
    echo "  Installing required dependency: wireguard-tools"
    omarchy-pkg-add wireguard-tools
else
    echo "  ✓ wireguard-tools already installed"
fi

if omarchy plugin list | grep -q '^glafeara\.wireguard'; then
    echo "  ✓ Omawire already installed"
else
    echo "  Installing Omawire..."
    omarchy plugin add https://github.com/glafeara/omarchy-wireguard.git --yes
fi

if omarchy plugin list | grep -q '^glafeara\.wireguard.*enabled'; then
    echo "  ✓ Omawire enabled"
else
    echo "  Enabling Omawire..."
    omarchy plugin enable glafeara.wireguard
fi

echo "  ✓ Omawire ready"

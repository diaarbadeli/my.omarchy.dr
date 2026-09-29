#!/usr/bin/env bash

set -u

PLUGIN_ID="glafeara.wireguard"

echo "========================================"
echo "            Omawire setup"
echo "========================================"
echo

if ! command -v jq >/dev/null 2>&1; then
    echo "✗ jq is required"
    exit 1
fi

# --------------------------------------------------
# Dependency
# --------------------------------------------------

echo "→ Checking dependency..."

if command -v wg >/dev/null 2>&1; then
    echo "  ✓ wireguard-tools already installed"
else
    echo "  → Installing wireguard-tools"

    omarchy-pkg-add wireguard-tools || {
        echo "  ✗ Failed to install wireguard-tools"
        exit 1
    }

    echo "  ✓ wireguard-tools installed"
fi

# --------------------------------------------------
# Plugin
# --------------------------------------------------

echo
echo "→ Checking Omawire..."

if omarchy plugin list --json |
    jq -e --arg id "$PLUGIN_ID" '.[] | select(.id == $id)' >/dev/null
then
    echo "  ✓ Omawire already installed"
else
    echo "  → Installing Omawire"

    omarchy plugin add \
        "https://github.com/glafeara/omarchy-wireguard.git" \
        --yes || {
        echo "  ✗ Failed to install Omawire"
        exit 1
    }

    echo "  ✓ Omawire installed"
fi

# --------------------------------------------------
# Enable
# --------------------------------------------------

echo
echo "→ Enabling Omawire..."

if omarchy plugin list --json |
    jq -e --arg id "$PLUGIN_ID" \
        '.[] | select(.id == $id and .enabled == true)' >/dev/null
then
    echo "  ✓ Omawire already enabled"
else
    omarchy plugin enable "$PLUGIN_ID" || {
        echo "  ✗ Failed to enable Omawire"
        exit 1
    }

    echo "  ✓ Omawire enabled"
fi

# --------------------------------------------------
# Done
# --------------------------------------------------

echo
echo "========================================"
echo "✓ Omawire setup complete."
echo "========================================"

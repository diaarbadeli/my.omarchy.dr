#!/usr/bin/env bash

set -u

PLUGIN_ID="omaplug"

echo "========================================"
echo "           Omaplug setup"
echo "========================================"
echo

if ! command -v jq >/dev/null 2>&1; then
    echo "✗ jq is required"
    exit 1
fi

# --------------------------------------------------
# Plugin
# --------------------------------------------------

echo "→ Checking Omaplug..."

if omarchy plugin list --json |
    jq -e --arg id "$PLUGIN_ID" '.[] | select(.id == $id)' >/dev/null
then
    echo "  ✓ Omaplug already installed"
else
    echo "  → Installing Omaplug"

    omarchy plugin add \
        "https://github.com/fross100/omaplug.git" \
        --yes || {
        echo "  ✗ Failed to install Omaplug"
        exit 1
    }

    echo "  ✓ Omaplug installed"
fi

# --------------------------------------------------
# Enable
# --------------------------------------------------

echo
echo "→ Enabling Omaplug..."

if omarchy plugin list --json |
    jq -e --arg id "$PLUGIN_ID" \
        '.[] | select(.id == $id and .enabled == true)' >/dev/null
then
    echo "  ✓ Omaplug already enabled"
else
    omarchy plugin enable "$PLUGIN_ID" || {
        echo "  ✗ Failed to enable Omaplug"
        exit 1
    }

    echo "  ✓ Omaplug enabled"
fi

# --------------------------------------------------
# Done
# --------------------------------------------------

echo
echo "========================================"
echo "✓ Omaplug setup complete."
echo "========================================"

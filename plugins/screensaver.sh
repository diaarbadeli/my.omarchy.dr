#!/usr/bin/env bash

set -u

PLUGIN_ID="io.github.wouldja.screensaver"

echo "========================================"
echo "         Omarchy Screensaver setup"
echo "========================================"
echo

if ! command -v jq >/dev/null 2>&1; then
    echo "✗ jq is required"
    exit 1
fi

# --------------------------------------------------
# Plugin
# --------------------------------------------------

echo "→ Checking Screensaver..."

if omarchy plugin list --json |
    jq -e --arg id "$PLUGIN_ID" '.[] | select(.id == $id)' >/dev/null
then
    echo "  ✓ Screensaver already installed"
else
    echo "  → Installing Screensaver"

    omarchy plugin add \
        "https://github.com/wouldja/omarchy-screensaver.git" \
        --yes || {
        echo "  ✗ Failed to install Screensaver"
        exit 1
    }

    echo "  ✓ Screensaver installed"
fi

# --------------------------------------------------
# Enable
# --------------------------------------------------

echo
echo "→ Enabling Screensaver..."

if omarchy plugin list --json |
    jq -e --arg id "$PLUGIN_ID" \
        '.[] | select(.id == $id and .enabled == true)' >/dev/null
then
    echo "  ✓ Screensaver already enabled"
else
    omarchy plugin enable "$PLUGIN_ID" || {
        echo "  ✗ Failed to enable Screensaver"
        exit 1
    }

    echo "  ✓ Screensaver enabled"
fi

# --------------------------------------------------
# Done
# --------------------------------------------------

echo
echo "========================================"
echo "✓ Screensaver setup complete."
echo "========================================"

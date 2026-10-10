#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

PLUGIN_ID="io.github.aphelion-studios.omamoodist"
PRESETS_SOURCE="$REPO_ROOT/config/omamoodist/presets.json"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/moodist/config.json"

echo "========================================"
echo "          OmaMoodist setup"
echo "========================================"
echo

# --------------------------------------------------
# Dependencies
# --------------------------------------------------

if ! command -v jq >/dev/null 2>&1; then
    echo "✗ jq is required"
    exit 1
fi

echo "→ Checking dependency..."

if pacman -Qi python-numpy >/dev/null 2>&1; then
    echo "  ✓ python-numpy already installed"
else
    echo "  → Installing python-numpy"

    omarchy-pkg-add python-numpy || {
        echo "  ✗ Failed to install python-numpy"
        exit 1
    }

    echo "  ✓ python-numpy installed"
fi

# --------------------------------------------------
# Plugin
# --------------------------------------------------

echo
echo "→ Checking OmaMoodist..."

if omarchy plugin list --json |
    jq -e --arg id "$PLUGIN_ID" '.[] | select(.id == $id)' >/dev/null
then
    echo "  ✓ OmaMoodist already installed"
else
    echo "  → Installing OmaMoodist"

    omarchy plugin add \
        "https://github.com/aphelion-studios/omamoodist.git" \
        --yes || {
        echo "  ✗ Failed to install OmaMoodist"
        exit 1
    }

    echo "  ✓ OmaMoodist installed"
fi

echo
echo "→ Enabling OmaMoodist..."

if omarchy plugin list --json |
    jq -e --arg id "$PLUGIN_ID" \
        '.[] | select(.id == $id and .enabled == true)' >/dev/null
then
    echo "  ✓ OmaMoodist already enabled"
else
    omarchy plugin enable "$PLUGIN_ID" || {
        echo "  ✗ Failed to enable OmaMoodist"
        exit 1
    }

    echo "  ✓ OmaMoodist enabled"
fi

# --------------------------------------------------
# Presets
# --------------------------------------------------

echo
echo "→ Checking saved presets..."

if [[ ! -f "$PRESETS_SOURCE" ]]; then
    echo "  ✗ Preset source not found:"
    echo "    $PRESETS_SOURCE"
    echo
    echo "  The repository is missing:"
    echo "    config/omamoodist/presets.json"
    exit 1
fi

if ! jq -e 'type == "object"' "$PRESETS_SOURCE" >/dev/null; then
    echo "  ✗ Invalid presets.json"
    exit 1
fi

echo "  ✓ Preset source found"

mkdir -p "$(dirname "$CONFIG")"

# Create a minimal config only if Moodist has never been configured.
if [[ ! -f "$CONFIG" ]]; then
    printf '%s\n' \
        '{"binaural":{},"master":1,"presets":{},"sleep_minutes":0,"sounds":{}}' \
        > "$CONFIG"

    echo "  ✓ Created Moodist configuration"
fi

tmp="$(mktemp "${CONFIG}.XXXXXX")"
trap 'rm -f "$tmp"' EXIT

if ! jq --slurpfile presets "$PRESETS_SOURCE" '
    .presets = ($presets[0] // {})
' "$CONFIG" > "$tmp"; then
    echo "  ✗ Failed to update Moodist configuration"
    exit 1
fi

if cmp -s "$CONFIG" "$tmp"; then
    rm -f "$tmp"
    trap - EXIT
    echo "  ✓ Presets already up to date"
else
    mv "$tmp" "$CONFIG"
    trap - EXIT
    echo "  ✓ Presets installed"
fi

# --------------------------------------------------
# Done
# --------------------------------------------------

echo
echo "========================================"
echo "✓ OmaMoodist setup complete."
echo "========================================"

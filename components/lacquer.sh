#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

PLUGIN_ID="io.github.deunnis.lacquer"
PLUGIN_URL="https://github.com/Deunnis/omarchy-lacquer.git"

SOURCE_DIR="$REPO_ROOT/config/lacquer"

HYPR_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/looknfeel.lua"
SHELL_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/shell.toml"
LACQUER_STATE="${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/io.github.deunnis.lacquer"

BACKUP_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/lacquer-backups"
BACKUP_DIR="$BACKUP_ROOT/$(date +%Y%m%d-%H%M%S)"

echo "========================================"
echo "           Lacquer setup"
echo "========================================"
echo

if ! command -v jq >/dev/null 2>&1; then
    echo "✗ jq is required"
    exit 1
fi

# --------------------------------------------------
# Verify repository state
# --------------------------------------------------

echo "→ Checking Lacquer configuration..."

required_files=(
    "looknfeel.lua"
    "shell.toml"
    "pins.json"
    "shuffle.json"
    "ui.json"
)

for file in "${required_files[@]}"; do
    if [[ ! -f "$SOURCE_DIR/$file" ]]; then
        echo "  ✗ Missing configuration:"
        echo "    $SOURCE_DIR/$file"
        exit 1
    fi
done

echo "  ✓ All Lacquer configuration files found"

# --------------------------------------------------
# Plugin
# --------------------------------------------------

echo
echo "→ Checking Lacquer plugin..."

if omarchy plugin list --json |
    jq -e --arg id "$PLUGIN_ID" '.[] | select(.id == $id)' >/dev/null
then
    echo "  ✓ Lacquer already installed"
else
    echo "  → Installing Lacquer"

    omarchy plugin add "$PLUGIN_URL" --yes || {
        echo "  ✗ Failed to install Lacquer"
        exit 1
    }

    echo "  ✓ Lacquer installed"
fi

# --------------------------------------------------
# Enable
# --------------------------------------------------

echo
echo "→ Enabling Lacquer..."

if omarchy plugin list --json |
    jq -e --arg id "$PLUGIN_ID" \
        '.[] | select(.id == $id and .enabled == true)' >/dev/null
then
    echo "  ✓ Lacquer already enabled"
else
    omarchy plugin enable "$PLUGIN_ID" || {
        echo "  ✗ Failed to enable Lacquer"
        exit 1
    }

    echo "  ✓ Lacquer enabled"
fi

# --------------------------------------------------
# Backup current state
# --------------------------------------------------

echo
echo "→ Backing up current Lacquer state..."

backup_needed=0

if [[ -f "$HYPR_CONFIG" ]]; then
    backup_needed=1
fi

if [[ -f "$SHELL_CONFIG" ]]; then
    backup_needed=1
fi

for file in pins.json shuffle.json ui.json; do
    if [[ -f "$LACQUER_STATE/$file" ]]; then
        backup_needed=1
    fi
done

if [[ "$backup_needed" -eq 1 ]]; then
    mkdir -p "$BACKUP_DIR"

    if [[ -f "$HYPR_CONFIG" ]]; then
        cp -a "$HYPR_CONFIG" "$BACKUP_DIR/looknfeel.lua"
    fi

    if [[ -f "$SHELL_CONFIG" ]]; then
        cp -a "$SHELL_CONFIG" "$BACKUP_DIR/shell.toml"
    fi

    for file in pins.json shuffle.json ui.json; do
        if [[ -f "$LACQUER_STATE/$file" ]]; then
            cp -a "$LACQUER_STATE/$file" "$BACKUP_DIR/$file"
        fi
    done

    echo "  ✓ Backup created:"
    echo "    $BACKUP_DIR"
else
    echo "  ✓ Nothing to back up"
fi

# --------------------------------------------------
# Restore configuration
# --------------------------------------------------

echo
echo "→ Restoring Lacquer configuration..."

mkdir -p \
    "$(dirname "$HYPR_CONFIG")" \
    "$(dirname "$SHELL_CONFIG")" \
    "$LACQUER_STATE"

cp "$SOURCE_DIR/looknfeel.lua" "$HYPR_CONFIG"
echo "  ✓ Hyprland look'n'feel"

cp "$SOURCE_DIR/shell.toml" "$SHELL_CONFIG"
echo "  ✓ Omarchy shell appearance"

for file in pins.json shuffle.json ui.json; do
    cp "$SOURCE_DIR/$file" "$LACQUER_STATE/$file"
    echo "  ✓ $file"
done

# --------------------------------------------------
# Reload
# --------------------------------------------------

echo
echo "→ Reloading configuration..."

if command -v hyprctl >/dev/null 2>&1; then
    if hyprctl reload >/dev/null 2>&1; then
        echo "  ✓ Hyprland reloaded"
    else
        echo "  ! Hyprland reload failed"
    fi
fi

if command -v omarchy-shell >/dev/null 2>&1; then
    if omarchy-shell shell reloadConfig >/dev/null 2>&1; then
        echo "  ✓ Omarchy shell reloaded"
    else
        echo "  ! Omarchy shell reload failed"
    fi
fi

echo
echo "========================================"
echo "✓ Lacquer setup complete."
echo "========================================"

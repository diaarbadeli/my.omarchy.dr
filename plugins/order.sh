#!/usr/bin/env bash

set -u

failed=0

echo "========================================"
echo "       Omarchy bar configuration"
echo "========================================"
echo

# ────────────────────────────────────────
# Disable stock workspace plugin
# ────────────────────────────────────────

echo "→ Disabling stock Omarchy Workspaces"

if omarchy plugin disable "omarchy.workspaces"; then
    echo "  ✓ omarchy.workspaces disabled"
else
    echo "  ✗ failed to disable omarchy.workspaces"
    failed=1
fi

echo

# ────────────────────────────────────────
# Bar positioning
# ────────────────────────────────────────

move() {
    local id="$1"
    local section="$2"
    local index="$3"

    echo "→ $id → $section[$index]"

    if omarchy bar move "$id" --section "$section" --index "$index"; then
        echo "  ✓"
    else
        echo "  ✗ failed"
        failed=1
    fi
}

echo "Setting bar layout..."
echo

# Left
move "omarchy.indicators" "left" 0
move "blu.workspaces" "left" 1
move "omarchy.audio" "left" 2

# Center
move "omarchy.clock" "center" 0
move "omarchy.system-update" "center" 1
move "omaplug" "center" 2

# Right
move "omarchy.tray" "right" 0
move "omamail" "right" 1
move "io.github.aphelion-studios.omamoodist" "right" 2
move "glafeara.wireguard" "right" 3
move "omarchy.bluetooth" "right" 4
move "omarchy.network" "right" 5
move "omarchy.power" "right" 6

echo
echo "========================================"

if [[ "$failed" -eq 0 ]]; then
    echo "✓ Bar layout applied."
    exit 0
else
    echo "✗ Bar layout completed with errors."
    exit 1
fi

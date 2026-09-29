#!/usr/bin/env bash
set -u

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGINS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins"

failed=0

echo "========================================"
echo "       my.omarchy.dr installer"
echo "========================================"
echo

# ────────────────────────────────────────
# Local plugins
# ────────────────────────────────────────

install_local_plugin() {
    local id="$1"
    local source="$2"
    local target="$PLUGINS_DIR/$id"

    echo "→ $id"

    if [[ ! -f "$source/manifest.json" ]]; then
        echo "  ✗ manifest.json not found"
        failed=1
        return
    fi

    mkdir -p "$target"

    if cp -a "$source/." "$target/"; then
        echo "  ✓ installed"
    else
        echo "  ✗ failed"
        failed=1
        return
    fi

    if omarchy plugin enable "$id"; then
        echo "  ✓ enabled"
    else
        echo "  ✗ could not enable"
        failed=1
    fi
}

install_local_plugin \
    "blu.workspaces" \
    "$REPO_DIR/plugins/blu.workspaces"

echo

# ────────────────────────────────────────
# Git plugins
# ────────────────────────────────────────

install_git_plugin() {
    local name="$1"
    local url="$2"

    echo "→ $name"

    if omarchy plugin add "$url" --enable --yes; then
        echo "  ✓ installed"
    else
        echo "  ✗ failed"
        failed=1
    fi
}

install_git_plugin \
    "Lock Explorer" \
    "https://github.com/SirJul1337/omarchy-lock-explorer.git"

install_git_plugin \
    "Omamail" \
    "https://github.com/huacnlee/omamail.git"

install_git_plugin \
    "Omamoodist" \
    "https://github.com/aphelion-studios/omamoodist.git"

install_git_plugin \
    "Lacquer" \
    "https://github.com/Deunnis/omarchy-lacquer.git"

install_git_plugin \
    "Omawire" \
    "https://github.com/glafeara/omarchy-wireguard.git"

install_git_plugin \
    "Omaplug" \
    "https://github.com/fross100/omaplug.git"

install_git_plugin \
    "Screensaver" \
    "https://github.com/wouldja/omarchy-screensaver.git"

echo
echo "========================================"

if [[ "$failed" -eq 0 ]]; then
    echo "✓ Installation completed."
    exit 0
else
    echo "✗ Installation completed with errors."
    exit 1
fi

#!/usr/bin/env bash

set -u

PLUGIN_ID="omamail"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/shell.json"

echo "========================================"
echo "          Omamail configuration"
echo "========================================"
echo

if ! command -v jq >/dev/null 2>&1; then
    echo "✗ jq is required"
    exit 1
fi

if [[ ! -f "$CONFIG" ]]; then
    echo "✗ Omarchy shell config not found:"
    echo "  $CONFIG"
    exit 1
fi

if ! jq -e --arg id "$PLUGIN_ID" '
    (
        [.plugins[]? | select(.id == $id)] +
        [.bar.layout.left[]? | select(.id == $id)] +
        [.bar.layout.center[]? | select(.id == $id)] +
        [.bar.layout.right[]? | select(.id == $id)]
    ) | length > 0
' "$CONFIG" >/dev/null; then
    echo "✗ Omamail entry not found in shell.json"
    exit 1
fi

tmp="$(mktemp "${CONFIG}.XXXXXX")"
trap 'rm -f "$tmp"' EXIT

jq '
  def configure_omamail:
    if .id == "omamail" then
      .notifyNewMail = "Off"
      | .undoSendSeconds = 0
      | .showBarIcon = false
    else
      .
    end;

  .plugins = [
    .plugins[]? | configure_omamail
  ]
  | .bar.layout.left = [
    .bar.layout.left[]? | configure_omamail
  ]
  | .bar.layout.center = [
    .bar.layout.center[]? | configure_omamail
  ]
  | .bar.layout.right = [
    .bar.layout.right[]? | configure_omamail
  ]
' "$CONFIG" > "$tmp" || {
    echo "✗ Failed to generate updated shell.json"
    exit 1
}

if cmp -s "$CONFIG" "$tmp"; then
    echo "✓ Omamail settings already configured"
    rm -f "$tmp"
    trap - EXIT
else
    mv "$tmp" "$CONFIG"
    trap - EXIT

    echo "✓ New mail notifications: OFF"
    echo "✓ Undo send window:       0 seconds"
    echo "✓ Bar icon:               hidden"

    if omarchy-shell shell reloadConfig >/dev/null; then
        echo "✓ Omarchy shell configuration reloaded"
    else
        echo "✗ Failed to reload Omarchy shell"
        exit 1
    fi
fi

echo
echo "✓ Omamail configuration complete."

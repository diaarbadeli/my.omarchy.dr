#!/usr/bin/env bash

set -euo pipefail

CONFIG_URL="https://raw.githubusercontent.com/diaarbadeli/my.omarchy.dr/refs/heads/main/configs/bindings.dr/bindings.lua"
TARGET="$HOME/.config/hypr/bindings.lua"

TEMP_CONFIG="$(mktemp)"
MANAGED_CONFIG="$(mktemp)"

START_MARKER="-- >>> bindings.dr managed block >>>"
END_MARKER="-- <<< bindings.dr managed block <<<"

cleanup() {
    rm -f "$TEMP_CONFIG" "$MANAGED_CONFIG"
}

trap cleanup EXIT

curl -fsSL "$CONFIG_URL" -o "$TEMP_CONFIG"

{
    printf '%s\n' "$START_MARKER"
    cat "$TEMP_CONFIG"
    printf '%s\n' "$END_MARKER"
} > "$MANAGED_CONFIG"

mkdir -p "$(dirname "$TARGET")"

# First installation.
if [[ ! -f "$TARGET" ]]; then
    cp "$MANAGED_CONFIG" "$TARGET"
    hyprctl reload
    echo "bindings.dr installed."
    exit 0
fi

START_COUNT="$(grep -Fc -- "$START_MARKER" "$TARGET" || true)"
END_COUNT="$(grep -Fc -- "$END_MARKER" "$TARGET" || true)"

if [[ "$START_COUNT" -eq 0 && "$END_COUNT" -eq 0 ]]; then

    {
        cat "$MANAGED_CONFIG"
        cat "$TARGET"
    } > "${TARGET}.new"

elif [[ "$START_COUNT" -eq 1 && "$END_COUNT" -eq 1 ]]; then

    awk \
        -v start="$START_MARKER" \
        -v end="$END_MARKER" \
        '
        $0 == start {
            skip=1
            next
        }

        $0 == end {
            skip=0
            next
        }

        !skip {
            print
        }
        ' "$TARGET" > "${TARGET}.rest"

    {
        cat "$MANAGED_CONFIG"
        cat "${TARGET}.rest"
    } > "${TARGET}.new"

    rm -f "${TARGET}.rest"

else
    echo "Error: invalid bindings.dr managed block in $TARGET."
    echo "Expected either zero markers or exactly one start/end pair."
    exit 1
fi

# Nothing changed.
if cmp -s "${TARGET}.new" "$TARGET"; then
    rm -f "${TARGET}.new"
    echo "bindings.dr is already up to date."
    exit 0
fi

# Keep exactly one backup.
cp "$TARGET" "$TARGET.backup"

mv "${TARGET}.new" "$TARGET"

hyprctl reload

echo "bindings.dr updated."

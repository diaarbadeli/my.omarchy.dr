#!/usr/bin/env bash

set -Eeuo pipefail

# lacquer.dr — install theme assets and prepare the saved Look for import.
# Safe to run repeatedly. Does not modify Lacquer's own source files.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

PLUGIN_ID="io.github.deunnis.lacquer"
PLUGIN_URL="https://github.com/Deunnis/omarchy-lacquer.git"
LOOK_SLUG="lacquer-dr"
THEME_NAME="solitude-dr"

CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# This script lives inside configs/lacquer.dr/, beside these assets.
SOURCE_DIR="$SCRIPT_DIR"
THEME_TARGET="$CONFIG_HOME/omarchy/themes/$THEME_NAME"
LOOK_STATE="$STATE_HOME/omarchy/$PLUGIN_ID/looks.json"
LOOK_SOURCE="$SOURCE_DIR/lacquer-looks.json"
LOOK_PAGE='{"section":"looks"}'

# --------------------------------------------------
# Helpers
# --------------------------------------------------

die() {
    printf '✗ %s\n' "$*" >&2
    exit 1
}

info() {
    printf '\n→ %s\n' "$*"
}

ok() {
    printf '  ✓ %s\n' "$*"
}

warn() {
    printf '  ! %s\n' "$*" >&2
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

look_is_saved() {
    [[ -f "$LOOK_STATE" ]] &&
        jq -e --arg slug "$LOOK_SLUG" \
            '.looks | any(.slug == $slug)' \
            "$LOOK_STATE" >/dev/null 2>&1
}

# --------------------------------------------------
# Validate inputs and dependencies
# --------------------------------------------------

printf '%s\n' \
    '========================================' \
    '          lacquer.dr setup' \
    '========================================'

[[ -d "$SOURCE_DIR" ]] || die "Theme source directory not found: $SOURCE_DIR"
[[ -f "$LOOK_SOURCE" ]] || die "Saved Look not found: $LOOK_SOURCE"

require_command omarchy
require_command omarchy-pkg-add
require_command jq
require_command cp
require_command install
require_command pacman

jq -e --arg slug "$LOOK_SLUG" '
    (.looks | type == "array") and
    (.looks | any(.slug == $slug and .name == "lacquer.dr"))
' "$LOOK_SOURCE" >/dev/null ||
    die "The source JSON is invalid or does not contain the expected Look."

# --------------------------------------------------
# Install fonts (best effort)
# --------------------------------------------------

info "Checking fonts..."

install_font() {
    local package="$1"

    if pacman -Q "$package" >/dev/null 2>&1; then
        ok "$package already installed"
        return 0
    fi

    if omarchy-pkg-add "$package"; then
        ok "$package installed"
    else
        warn "Could not install $package through omarchy-pkg-add."
        warn "Check whether this package is available through your configured repositories."
    fi
}

install_font "ttf-recursive"
install_font "vazirmatn-fonts"

# --------------------------------------------------
# Install and enable Lacquer
# --------------------------------------------------

info "Checking Lacquer..."

plugin_list="$(omarchy plugin list --json)" ||
    die "Could not retrieve the Omarchy plugin list."

if printf '%s' "$plugin_list" | jq -e --arg id "$PLUGIN_ID" \
    '.[] | select(.id == $id)' >/dev/null; then
    ok "Lacquer is installed"
else
    info "Installing Lacquer..."
    omarchy plugin add "$PLUGIN_URL" --yes || die "Lacquer installation failed."
    ok "Lacquer installed"
fi

plugin_list="$(omarchy plugin list --json)" ||
    die "Could not refresh the Omarchy plugin list."

if printf '%s' "$plugin_list" | jq -e --arg id "$PLUGIN_ID" \
    '.[] | select(.id == $id and .enabled == true)' >/dev/null; then
    ok "Lacquer is enabled"
else
    omarchy plugin enable "$PLUGIN_ID" || die "Could not enable Lacquer."
    ok "Lacquer enabled"
fi

# --------------------------------------------------
# Install the solitude-dr theme assets
# --------------------------------------------------

info "Installing $THEME_NAME theme assets..."
mkdir -p "$THEME_TARGET"

for file in colors.toml icons.theme preview.jpg; do
    if [[ -f "$SOURCE_DIR/$file" ]]; then
        install -Dm644 "$SOURCE_DIR/$file" "$THEME_TARGET/$file"
    else
        warn "Optional theme asset is missing: $file"
    fi
done

if [[ -d "$SOURCE_DIR/backgrounds" ]]; then
    mkdir -p "$THEME_TARGET/backgrounds"
    cp -f -- "$SOURCE_DIR"/backgrounds/* "$THEME_TARGET/backgrounds/" 2>/dev/null || true
else
    warn "No backgrounds directory found."
fi

ok "Theme assets copied to $THEME_TARGET"

# --------------------------------------------------
# Prepare the import file
# --------------------------------------------------

info "Preparing the saved Look..."
LOOK_FILE="$HOME/lacquer.dr-looks.json"
IMPORT_NEEDED=1

if look_is_saved; then
    IMPORT_NEEDED=0
    ok "The Look is already present in Lacquer's saved state"

    # Remove only our exact generated copy, never an unrelated file.
    if [[ -f "$LOOK_FILE" ]] && cmp -s "$LOOK_SOURCE" "$LOOK_FILE"; then
        rm -f -- "$LOOK_FILE"
    fi
else
    # Avoid overwriting an unrelated file with the same name.
    if [[ -e "$LOOK_FILE" ]] && ! cmp -s "$LOOK_SOURCE" "$LOOK_FILE"; then
        LOOK_FILE="$HOME/lacquer.dr-looks-$(date +%Y%m%d-%H%M%S).json"
    fi

    if ! cmp -s "$LOOK_SOURCE" "$LOOK_FILE"; then
        install -Dm644 "$LOOK_SOURCE" "$LOOK_FILE" ||
            die "Could not prepare the Look import file."
    fi

    ok "Import file ready: $LOOK_FILE"
fi

# --------------------------------------------------
# Open Lacquer on Saved looks
# --------------------------------------------------

info "Opening Lacquer → Saved looks..."
omarchy-shell shell summon "$PLUGIN_ID" "$LOOK_PAGE" ||
    warn "Could not open Lacquer automatically. Open it from the Omarchy plugin menu."

# --------------------------------------------------
# Watch for a successful import
# --------------------------------------------------

if [[ "$IMPORT_NEEDED" -eq 1 ]]; then
    # Lacquer writes looks.json after importing. Wait for the saved entry before
    # removing the import file. This confirms import/save, not that Apply was clicked.
    nohup bash -c '
        set -u
        look_file="$1"
        state_file="$2"
        slug="$3"

        for ((i = 0; i < 360; i++)); do
            if [[ -f "$state_file" ]] &&
                jq -e --arg slug "$slug" \
                    ".looks | any(.slug == \$slug)" \
                    "$state_file" >/dev/null 2>&1; then
                rm -f -- "$look_file"
                if command -v omarchy-notification-send >/dev/null 2>&1; then
                    omarchy-notification-send \
                        "Lacquer import confirmed" \
                        "The lacquer.dr Look is saved. The temporary JSON file was removed. Select the Look and press Apply." \
                        -g "󰃨"
                fi
                exit 0
            fi
            sleep 5
        done
    ' lacquer-dr-import-watch "$LOOK_FILE" "$LOOK_STATE" "$LOOK_SLUG" \
        >/dev/null 2>&1 </dev/null &
    ok "Waiting for Lacquer to save the imported Look"
fi

# --------------------------------------------------
# Guide notification
# --------------------------------------------------

if [[ "$IMPORT_NEEDED" -eq 1 ]]; then
    NOTIFICATION_BODY="Import $LOOK_FILE from Saved looks. When lacquer.dr appears, select it and press Apply. The temporary file is removed automatically after Lacquer saves the import."
else
    NOTIFICATION_BODY="lacquer.dr is already in Saved looks. Select it and press Apply to restore its settings."
fi

if command -v omarchy-notification-send >/dev/null 2>&1; then
    omarchy-notification-send \
        -g "󰃨" \
        "lacquer.dr is ready" \
        "$NOTIFICATION_BODY" \
        --exec omarchy-shell shell summon "$PLUGIN_ID" "$LOOK_PAGE"
else
    warn "omarchy-notification-send not found; use the terminal instructions above."
    printf '\n%s\n' "$NOTIFICATION_BODY"
fi

printf '\n%s\n' \
    '========================================' \
    'lacquer.dr setup finished.' \
    '========================================'


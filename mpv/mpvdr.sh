#!/usr/bin/env bash
#
# setup-mpv.sh - Idempotent MPV setup for Omarchy/Arch
# - Installs Vazirmatn font (Persian + Latin) via AUR
# - Fixes subtitle display
# - Applies custom subtitle theme (white text, dark stroke, bold, large)
# - Installs ModernZ OSC
#
# Repo: github.com/diaarbadeli/my.omarchy.dr
# Usage: chmod +x setup-mpv.sh && ./setup-mpv.sh
#

set -euo pipefail

# ---------- Paths ----------
MPV_CONFIG_DIR="${HOME}/.config/mpv"
MPV_CONF="${MPV_CONFIG_DIR}/mpv.conf"
SCRIPTS_DIR="${MPV_CONFIG_DIR}/scripts"
FONTS_DIR="${MPV_CONFIG_DIR}/fonts"
SCRIPT_OPTS_DIR="${MPV_CONFIG_DIR}/script-opts"

MODERNZ_REPO="https://github.com/Samillion/ModernZ.git"
MODERNZ_TMP="$(mktemp -d)"

# ---------- Subtitle styling (tunable) ----------
SUB_COLOR="${SUB_COLOR:-#c7bfbf}"
SUB_BORDER_COLOR="${SUB_BORDER_COLOR:-#1a1414}"
SUB_BORDER_SIZE="${SUB_BORDER_SIZE:-3.5}"
SUB_FONT_SIZE="${SUB_FONT_SIZE:-90}"
SUB_FONT="${SUB_FONT:-Vazirmatn}"

# ---------- Output helpers ----------
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log_info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

cleanup() { [[ -d "$MODERNZ_TMP" ]] && rm -rf "$MODERNZ_TMP"; }
trap cleanup EXIT

# ---------- Preflight ----------
preflight() {
    log_info "Checking prerequisites..."
    command -v git &>/dev/null || { log_error "git required: sudo pacman -S git"; exit 1; }
    [[ -f "$MPV_CONF" ]] || { mkdir -p "$MPV_CONFIG_DIR"; touch "$MPV_CONF"; }
    mkdir -p "$SCRIPTS_DIR" "$FONTS_DIR" "$SCRIPT_OPTS_DIR"
    log_info "Prerequisites OK."
}

# ---------- Font install ----------
install_font() {
    log_info "Checking for ${SUB_FONT} font..."

    if fc-list 2>/dev/null | grep -qi "vazir"; then
        log_info "Vazirmatn already installed."
        return 0
    fi

    if ! command -v yay &>/dev/null; then
        log_error "yay not found. Install yay first, or manually:"
        log_error "  yay -S vazirmatn-fonts"
        log_error "  OR drop Vazirmatn TTF into: ${FONTS_DIR}/"
        return 1
    fi

    log_info "Installing vazirmatn-fonts via yay..."
    if yay -S --noconfirm --needed vazirmatn-fonts; then
        fc-cache -f &>/dev/null || true
        log_info "Vazirmatn installed."
    else
        log_error "Failed to install vazirmatn-fonts."
        log_error "Manual fallback: drop a TTF into ${FONTS_DIR}/ and re-run."
        return 1
    fi
}

# ---------- Backup ----------
backup_config() {
    if [[ -f "$MPV_CONF" && ! -s "${MPV_CONF}.bak.orig" ]]; then
        cp "$MPV_CONF" "${MPV_CONF}.bak.orig"
        log_info "Created original backup: ${MPV_CONF}.bak.orig"
    fi
}

# ---------- Subtitle config (idempotent) ----------
configure_subtitles() {
    local marker_start="# >>> setup-mpv.sh subtitle config >>>"
    local marker_end="# <<< setup-mpv.sh subtitle config <<<"

    log_info "Configuring subtitle settings..."

    if grep -qF "$marker_start" "$MPV_CONF" 2>/dev/null; then
        log_warn "Subtitle config block already present."
        log_info "Removing old block and re-applying with current values..."
        sed -i "/# >>> setup-mpv.sh subtitle config >>>/,/# <<< setup-mpv.sh subtitle config <<</d" "$MPV_CONF"
    fi

    backup_config

    cat >> "$MPV_CONF" <<EOF

$marker_start
# --- Subtitle display fixes ---
sub-auto=all
sid=1
sub-visibility=yes

# --- Subtitle styling ---
sub-font="${SUB_FONT}"
sub-font-size=${SUB_FONT_SIZE}
sub-color="${SUB_COLOR}"
sub-border-color="${SUB_BORDER_COLOR}"
sub-border-size=${SUB_BORDER_SIZE}
sub-bold=yes
sub-shadow-offset=1.5
sub-shadow-color="#00000080"
sub-ass-override=force

# --- ModernZ OSC ---
osc=no

$marker_end
EOF

    log_info "Subtitle config written to $MPV_CONF"
    log_info "  Font:   ${SUB_FONT}"
    log_info "  Size:   ${SUB_FONT_SIZE}"
    log_info "  Text:   ${SUB_COLOR}"
    log_info "  Stroke: ${SUB_BORDER_COLOR} @ ${SUB_BORDER_SIZE}"
}

# ---------- ModernZ ----------
install_modernz() {
    log_info "Installing ModernZ OSC..."
    git clone --depth 1 "$MODERNZ_REPO" "$MODERNZ_TMP" 2>/dev/null \
        || { log_error "Clone failed."; exit 1; }
    [[ -f "$MODERNZ_TMP/modernz.lua" ]] \
        || { log_error "modernz.lua missing from repo."; exit 1; }

    if [[ -f "$SCRIPTS_DIR/modernz.lua" ]]; then
        cp "$SCRIPTS_DIR/modernz.lua" "$SCRIPTS_DIR/modernz.lua.bak.$(date +%Y%m%d_%H%M%S)"
        log_info "Backed up existing modernz.lua"
    fi
    cp "$MODERNZ_TMP/modernz.lua" "$SCRIPTS_DIR/"
    log_info "Installed modernz.lua"

    [[ -f "$MODERNZ_TMP/modernz-icons.ttf" ]] && \
        cp "$MODERNZ_TMP/modernz-icons.ttf" "$FONTS_DIR/" && \
        log_info "Installed modernz-icons.ttf"

    [[ -f "$MODERNZ_TMP/extras/locale/modernz-locale.json" ]] && \
        cp "$MODERNZ_TMP/extras/locale/modernz-locale.json" "$SCRIPT_OPTS_DIR/" && \
        log_info "Installed locale file"

    [[ -f "$MODERNZ_TMP/extras/thumbfast.lua" ]] && \
        cp "$MODERNZ_TMP/extras/thumbfast.lua" "$SCRIPTS_DIR/" && \
        log_info "Installed thumbfast.lua"

    log_info "ModernZ installation complete."
}

# ---------- Validate ----------
validate() {
    log_info "Validating setup..."
    local errors=0
    grep -qF "osc=no" "$MPV_CONF" || { log_warn "osc=no missing"; errors=$((errors+1)); }
    grep -qF "sub-font=\"${SUB_FONT}\"" "$MPV_CONF" || { log_warn "sub-font not set"; errors=$((errors+1)); }
    [[ -f "$SCRIPTS_DIR/modernz.lua" ]] || { log_error "modernz.lua missing"; errors=$((errors+1)); }
    [[ $errors -eq 0 ]] && log_info "Validation passed." || log_warn "$errors issue(s)."
}

# ---------- Main ----------
main() {
    log_info "Starting MPV setup..."
    preflight
    install_font || log_warn "Continuing without font install."
    configure_subtitles
    install_modernz
    validate

    echo ""
    log_info "========================================="
    log_info "Setup complete!"
    log_info "========================================="
    echo ""
    echo "Subtitle theme:"
    echo "  Font:   ${SUB_FONT} @ ${SUB_FONT_SIZE}px, bold"
    echo "  Text:   ${SUB_COLOR}"
    echo "  Stroke: ${SUB_BORDER_COLOR} @ ${SUB_BORDER_SIZE}"
    echo ""
    echo "Rollback: cp ${MPV_CONF}.bak.orig ${MPV_CONF}"
}

main "$@"

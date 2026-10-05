# my.omarchy.dr

Personal Omarchy configuration, scripts, and plugins.

## Contents

- `setup-mpv.sh` — Idempotent MPV setup: subtitle fixes, custom theme, Vazirmatn font, ModernZ OSC.

## MPV Setup

### What it does

1. **Installs Vazirmatn** (Persian + Latin) via `yay -S vazirmatn-fonts`.
   - Persian glyphs render in Vazirmatn.
   - Latin glyphs render in Roboto (built into Vazirmatn).
2. **Fixes subtitle display** — `sid=1`, `sub-auto=all`, `sub-visibility=yes`.
3. **Applies custom theme**:
   - Font: Vazirmatn
   - Size: 110 (large)
   - Text: `#c7bfbf` (warm off-white)
   - Stroke: `#1a1414` (near-black) @ 3.5px (bold look)
   - Shadow: subtle, for depth
4. **Installs ModernZ OSC** — modern on-screen controller replacing the default.

### Usage

    chmod +x setup-mpv.sh
    ./setup-mpv.sh

The script is **idempotent**:
- Subtitle config uses a marker block — safe to re-run.
- If the block already exists, it's deleted and rewritten with current values.
- ModernZ files are backed up before overwrite.
- `mpv.conf` is backed up once as `mpv.conf.bak.orig`.

### Re-applying After Changes

Just run the script again. It will replace the existing subtitle block with the current values.

### Rollback

    cp ~/.config/mpv/mpv.conf.bak.orig ~/.config/mpv/mpv.conf

### Subtitle Theme Variables

Edit the top of `setup-mpv.sh`:

    SUB_COLOR="#c7bfbf"
    SUB_BORDER_COLOR="#1a1414"
    SUB_BORDER_SIZE="3.5"
    SUB_FONT_SIZE="110"
    SUB_FONT="Vazirmatn"

Or override at runtime:

    SUB_FONT_SIZE=130 SUB_COLOR="#ffffff" ./setup-mpv.sh

### Font Fallback

If `yay` isn't available, drop a Vazirmatn `.ttf` into `~/.config/mpv/fonts/` manually. MPV loads fonts from there without system install.

### Notes

- `sub-ass-override=force` ensures your theme applies to `.ass` files too. Comment it out if you want embedded ASS styles to win.
- `sub-bold=yes` may be subtle depending on font. The thick stroke (3.5) is what actually creates the bold look.
- ModernZ icons require `modernz-icons.ttf` in `~/.config/mpv/fonts/` — the script handles this.

## Keybindings & keyd

(TODO: document `key.dr` and `bindings.dr` integration here.)

## License

See `LICENSE`.

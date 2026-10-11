
hl.unbind("SUPER + SHIFT + ALT + E") -- was new email
hl.unbind("SUPER + SHIFT + ALT + A") -- was grok
hl.unbind("SUPER + SHIFT + C") -- better AI
hl.unbind("SUPER + SHIFT + X") -- better AI
hl.unbind("SUPER + SHIFT + V") --  better AI
hl.unbind("SUPER + SHIFT + B") -- was browser 
hl.unbind("SUPER + SHIFT + M") -- was spotify
hl.unbind("SUPER + SHIFT + S") -- was maps
hl.unbind("SUPER + SHIFT + E") -- was email
hl.unbind("SUPER + SHIFT + G") -- was signal
hl.unbind("SUPER + SHIFT + O") -- was obsidian
hl.unbind("SUPER + SHIFT + A") -- was chatgpt
hl.unbind("SUPER + SHIFT + P") -- was google photos
hl.unbind("SUPER + code:61") -- disable scale switch
hl.unbind("SUPER + G") -- disable grouping
hl.unbind("SUPER + L") -- disable layout switch
hl.unbind("SUPER + J") -- disable vertical arrangement
hl.unbind("SUPER + N") -- was editor
hl.unbind("SUPER + O") -- disable window popout (toggle tiling suffices)
hl.unbind("SUPER + SLASH") -- disable monitor scaleup (hurts>helps)
hl.unbind("SUPER + ALT + SLASH") -- disable monitor scaledown (hurts>helps)
hl.unbind("SUPER + CTRL + N") -- was nightlight
-- Must-Haves
o.bind("SUPER + B", "Browser", "omarchy-launch-browser")
o.bind("SUPER + E", "Editor", "omarchy-launch-editor")
o.bind("SUPER + CTRL + N", "Moodist", "omarchy-shell -q io.github.aphelion-studios.omamoodist toggle")
o.bind("SUPER + SHIFT + H", "File manager", "omarchy-launch-nautilus")
o.bind("SUPER + SHIFT + CTRL + H", "File manager (cwd)", {omarchy = "nautilus-cwd"})
o.bind("SUPER + SHIFT + M", "Cliamp", { tui = "cliamp", focus = true })
-- Messaging
o.bind("SUPER + SHIFT + T", "Telegram", 'omarchy-launch-or-focus-webapp "Telegram" "https://web.telegram.org/a/"')
o.bind("SUPER + SHIFT + B", "Bale", 'omarchy-launch-or-focus-webapp "Bale" "https://web.bale.ai/chat"')
o.bind("SUPER + SHIFT + G", "Omamail", "omarchy shell shell toggle omamail '{}'")
-- better AI
o.bind("SUPER + A", "Deepseek", 'omarchy-launch-or-focus-webapp "deepseek" "https://chat.deepseek.com/"')
o.bind("SUPER + SHIFT + Z", "z.ai", 'omarchy-launch-or-focus-webapp "z.ai" "https://chat.z.ai/"')
o.bind("SUPER + SHIFT + X", "Grok", 'omarchy-launch-or-focus-webapp "Grok" "https://grok.com/"')
o.bind("SUPER + SHIFT + C", "Claude", 'omarchy-launch-or-focus-webapp "Claude" "https://claude.ai/new"')
o.bind("SUPER + SHIFT + V", "ChatGPT", 'omarchy-launch-or-focus-webapp "ChatGPT" "https://chatgpt.com"')
-- Scripts & system
o.bind("SUPER + L", "Lock system", "omarchy-system-lock")
o.bind("SUPER + SHIFT + L", "Lock screen explorer", "omarchy-shell lock explore")
o.bind("SUPER + GRAVE", "WireGuard toggle", "omarchy-shell glafeara.wireguard toggle")
o.bind("SUPER + CTRL + GRAVE", "WireGuard panel", "omarchy-shell glafeara.wireguard open") -- super caps grave
o.bind("SUPER + SHIFT + P", "Omaplug", function()
    os.execute([[
        if omarchy-shell shell listPlugins | jq -e '.[] | select(.id == "omaplug" and .enabled == true)' >/dev/null 2>&1; then
            omarchy plugin disable omaplug
        else
            omarchy plugin enable omaplug
            omarchy-shell shell toggle omaplug '{}'
        fi
    ]])
end)
o.bind("XF86Display", "Screensaver", function()
    os.execute([[
        if omarchy-shell shell listPlugins | jq -e '.[] | select(.id == "io.github.wouldja.screensaver" and .enabled == true)' >/dev/null 2>&1; then
            omarchy plugin disable io.github.wouldja.screensaver
        else
            omarchy plugin enable io.github.wouldja.screensaver
            omarchy-shell shell toggle io.github.wouldja.screensaver '{}'
        fi
    ]])
end)
o.bind("SUPER + SHIFT + K", "Toggle Keyd", [[
sh -c 'if systemctl is-active --quiet keyd; then
  sudo systemctl stop keyd
  notify-send "Hey" "Lets Play Games" -i input-keyboard
else
  sudo systemctl start keyd
  notify-send "Alright" "Lets get back to work" -i input-keyboard
fi'
]])
o.bind("SUPER + N", "Obsidian", {
  launch = "obsidian",
  focus = "md.obsidian.Obsidian"
})
o.bind("SUPER + SHIFT + S", "Toggle Hyprsunset", [[
sh -c 'if pgrep -x "hyprsunset" > /dev/null; then
  killall hyprsunset
  omarchy-notification-send "Nooo!"
else
  hyprsunset -t 3000 &
  omarchy-notification-send "Phew!"
fi'
]])
-- Voxtype Toggle & Cancel
o.bind("INSERT", "Dictation Toggle", "voxtype record toggle")
o.bind("SHIFT + INSERT", "Dictation Cancel", "voxtype record cancel")


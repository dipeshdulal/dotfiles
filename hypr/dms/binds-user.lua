-- Optional per-user keybind overrides (managed by DMS). Loaded after default binds.

-- File manager: Nautilus (replaces Dolphin)
hl.bind("SUPER + E", hl.dsp.exec_cmd("nautilus --new-window"))

-- Browser: DMS default browser (Settings → Default Apps)
hl.bind("SUPER + B", hl.dsp.exec_cmd("dms ipc call defaultApp browser"))

-- Screenshots: Omasnap (annotation + scroll capture), replacing DMS built-ins.
-- Do NOT add no_screen_share to Omasnap's layer rule: it blacks out captures
-- and breaks scroll stitching (see hypr/hyprland.lua).
hl.unbind("Print")
hl.unbind("CTRL + Print")
hl.unbind("ALT + Print")
hl.bind("Print", hl.dsp.exec_cmd("omasnap"))
hl.bind("CTRL + Print", hl.dsp.exec_cmd("omasnap --capture-fullscreen"))
hl.bind("ALT + Print", hl.dsp.exec_cmd("omasnap --capture-window"))

-- macOS-style line nav: release SUPER+left/right from window focus so they
-- reach the focused app. We navigate windows with SUPER+HJKL, so nothing is
-- lost here.
hl.unbind("SUPER + left")
hl.unbind("SUPER + right")

-- macOS-style line editing, Hyprland-native (no remapper daemon).
-- Super+Backspace: terminals -> Ctrl-U (readline); GUI apps -> Shift+Home then
-- BackSpace. Super+Left/Right -> Home/End. Uses the focused window's class.
local function nav_in_terminal()
  local w = hl.get_active_window()
  local c = w and (w.class or ""):lower() or ""
  return c:find("ghostty", 1, true) ~= nil
    or c:find("kitty", 1, true) ~= nil
    or c:find("alacritty", 1, true) ~= nil
    or c:find("foot", 1, true) ~= nil
    or c:find("wezterm", 1, true) ~= nil
end

hl.bind("SUPER + backspace", function()
  if nav_in_terminal() then
    hl.dispatch(hl.dsp.send_shortcut({ mods = "CTRL", key = "u" }))
  else
    hl.dispatch(hl.dsp.send_shortcut({ mods = "SHIFT", key = "Home" }))
    hl.dispatch(hl.dsp.send_shortcut({ mods = "", key = "BackSpace" }))
  end
end)

hl.bind("SUPER + left", function()
  hl.dispatch(hl.dsp.send_shortcut({ mods = "", key = "Home" }))
end)

hl.bind("SUPER + right", function()
  hl.dispatch(hl.dsp.send_shortcut({ mods = "", key = "End" }))
end)

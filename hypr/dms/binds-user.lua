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
-- reach the focused app (Ghostty maps Cmd+Left/Right to Home/End). We navigate
-- windows with SUPER+HJKL, so nothing is lost here.
hl.unbind("SUPER + left")
hl.unbind("SUPER + right")

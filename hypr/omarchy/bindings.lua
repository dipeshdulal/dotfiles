-- Personal keybinding overrides for Omarchy.
-- Omarchy's defaults load first (see hyprland.lua), so anything already bound
-- must be released with hl.unbind() before rebinding it.

-- File manager: Flea (omarchy/flea). Free on Omarchy, which binds SUPER + SHIFT + F.
-- `flea --default` claims SUPER + SHIFT + F, the file chooser and "Show in
-- folder"; this adds SUPER + E on top.
o.bind("SUPER + E", "File manager", { launch = "flea" })

-- Window focus on HJKL, ported from the archtower DMS setup.
-- Omarchy uses J/K/L for other things, so clear them first:
--   SUPER + J  toggle window split
--   SUPER + K  keybindings menu
--   SUPER + L  toggle workspace layout
-- SUPER + arrows are released too, so only one scheme is in play.
hl.unbind("SUPER + J")
hl.unbind("SUPER + K")
hl.unbind("SUPER + L")
hl.unbind("SUPER + LEFT")
hl.unbind("SUPER + RIGHT")
hl.unbind("SUPER + UP")
hl.unbind("SUPER + DOWN")

o.bind("SUPER + H", "Focus left", hl.dsp.focus({ direction = "l" }))
o.bind("SUPER + J", "Focus down", hl.dsp.focus({ direction = "d" }))
o.bind("SUPER + K", "Focus up", hl.dsp.focus({ direction = "u" }))
o.bind("SUPER + L", "Focus right", hl.dsp.focus({ direction = "r" }))

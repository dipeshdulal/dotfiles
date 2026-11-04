-- Personal keybinding overrides for Omarchy.
-- Ported from archtower's DMS config (~/Backups/archtower/post-install/bindings.lua).
-- Omarchy's defaults load first, so hl.unbind here always wins.
-- Verify with: hyprctl configerrors   (silence)  and  hyprctl binds

--------------------------------------------------------------------
-- 1. vim navigation.  Omarchy ships SUPER+arrows and owns J/K/L:
--    J toggle-split, K keybindings menu, L cycle workspace layout.
--------------------------------------------------------------------
hl.unbind("SUPER + J")
hl.unbind("SUPER + K")
hl.unbind("SUPER + L")

o.bind("SUPER + H", "Focus left", hl.dsp.focus({ direction = "l" }))
o.bind("SUPER + J", "Focus down", hl.dsp.focus({ direction = "d" }))
o.bind("SUPER + K", "Focus up", hl.dsp.focus({ direction = "u" }))
o.bind("SUPER + L", "Focus right", hl.dsp.focus({ direction = "r" }))

-- Move the window (the DMS config used window.move, not Omarchy's window.swap)
o.bind("SUPER + SHIFT + H", "Move window left", hl.dsp.window.move({ direction = "l" }))
o.bind("SUPER + SHIFT + J", "Move window down", hl.dsp.window.move({ direction = "d" }))
o.bind("SUPER + SHIFT + K", "Move window up", hl.dsp.window.move({ direction = "u" }))
o.bind("SUPER + SHIFT + L", "Move window right", hl.dsp.window.move({ direction = "r" }))

-- Keybindings cheat sheet gets its own key (was SUPER+K). archtower used
-- SUPER+SHIFT+SLASH, but that is Passwords when preinstalled bindings are on,
-- so use SUPER+F1, which is free in both cases.
o.bind(
	"SUPER + F1",
	"Keybindings",
	[[omarchy-launch-terminal sh -c "omarchy menu keybindings --print | less"]]
)

--------------------------------------------------------------------
-- 2. macOS-style line editing.
--    Omarchy claims SUPER+Left/Right (focus) and SUPER+Backspace
--    (window transparency toggle), so free them first.
--------------------------------------------------------------------
hl.unbind("SUPER + LEFT")
hl.unbind("SUPER + RIGHT")
hl.unbind("SUPER + BACKSPACE")

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

--------------------------------------------------------------------
-- 3. Screenshots: omasnap replaces Omarchy's capture bindings.
--    Only applied when omasnap is installed, so PRINT never goes dead:
--      omarchy pkg add omasnap
--    Omarchy's capture menu on SUPER+CTRL+C is left alone.
--------------------------------------------------------------------
if o.cmd_present("omasnap") then
	hl.unbind("PRINT")
	hl.unbind("ALT + PRINT")
	hl.unbind("SUPER + CTRL + PRINT")

	o.bind("PRINT", "Screenshot (omasnap)", "omasnap")
	o.bind("CTRL + PRINT", "Fullscreen (omasnap)", "omasnap --capture-fullscreen")
	o.bind("ALT + PRINT", "Window (omasnap)", "omasnap --capture-window")
end

--------------------------------------------------------------------
-- 4. Everyday launchers.
--------------------------------------------------------------------
-- Flea (omarchy/flea). `flea --default` claims SUPER+SHIFT+F, the file
-- chooser and "Show in folder"; this adds SUPER+E on top.
o.bind("SUPER + E", "File manager", { launch = "flea" })

-- Browser: archtower's SUPER+B called `dms ipc call defaultApp browser`.
-- Omarchy binds SUPER+SHIFT+RETURN for the browser, so this is optional.
-- o.bind("SUPER + B", "Browser", { launch = "zen-browser" })

-- Chrome hard reload: CTRL+SHIFT+R is swallowed by tiling/rename on some setups
hl.unbind("CTRL + SHIFT + R")
hl.bind("CTRL + Delete", hl.dsp.send_shortcut({ mods = "CTRL SHIFT", key = "r" }))

--------------------------------------------------------------------
-- 5. Input method. Omarchy binds SUPER+I to `omarchy-input-method cycle`,
--    which is what you want with Nepali + Japanese. archtower's SUPER+I was
--    "previous workspace"; if you want that back, give it another chord:
-- hl.unbind("SUPER + I")
-- o.bind("SUPER + I", "Previous workspace", hl.dsp.focus({ workspace = "e-1" }))
-- o.bind("SUPER + SHIFT + I", "Input language", "omarchy-input-method cycle back")
--------------------------------------------------------------------

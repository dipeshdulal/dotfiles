-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all
--
-- Layout: 34" ultrawide on the left, 27" 1080p on the right rotated to
-- portrait (1080x1920). Both panels are 1x, so GTK must not be double-scaled:
-- the Omarchy template ships GDK_SCALE=2, which is only right on a HiDPI
-- laptop and makes GTK3 apps render at double size here.

hl.env("GDK_SCALE", "1")

-- Left / primary: 3440x1440 ultrawide. Pinned to 144 Hz -- letting Hyprland
-- pick "auto" landed on 50 Hz here, which made everything feel sluggish.
hl.monitor({
	output = "DP-1",
	mode = "3440x1440@144",
	position = "0x0",
	scale = 1,
})

-- Right: 1920x1080 rotated 270deg -> 1080x1920. Top-aligned with the
-- ultrawide (y = 0), so it hangs 480px below rather than overhanging the top.
-- For vertical centring use "3440x-240"; for bottom alignment "3440x-480".
-- (transform: 0 = normal, 1 = 90deg, 2 = 180deg, 3 = 270deg.)
hl.monitor({
	output = "HDMI-A-1",
	mode = "1920x1080@60",
	position = "3440x0",
	scale = 1,
	transform = 3,
})

-- Fallback for any other output, and for the window before both panels have
-- been detected. Must stay last so the specific rules above win.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

-- Workspaces 1-5 live on the ultrawide, 6-10 on the portrait panel. Without
-- this Hyprland assigns workspace 1 to the first monitor by ID, which is the
-- portrait panel -- so new windows would open sideways.
for ws = 1, 5 do
	hl.workspace_rule({ workspace = tostring(ws), monitor = "DP-1" })
end

for ws = 6, 10 do
	hl.workspace_rule({ workspace = tostring(ws), monitor = "HDMI-A-1" })
end

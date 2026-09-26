-- Optional per-user keybind overrides (managed by DMS). Loaded after default binds.

-- File manager: Nautilus (replaces Dolphin)
hl.bind("SUPER + E", hl.dsp.exec_cmd("nautilus --new-window"))

-- Browser: DMS default browser (Settings → Default Apps)
hl.bind("SUPER + B", hl.dsp.exec_cmd("dms ipc call defaultApp browser"))

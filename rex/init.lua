-- Rex keymap mirrored from herdr (~/.config/herdr/config.toml).
-- herdr uses a tmux-style prefix: ctrl+b.

-- Tabs ("windows" in tmux/herdr)
rex.bind("ctrl+b>c", "client.tab.new")
rex.bind("ctrl+b>n", "client.tab.next")
rex.bind("ctrl+b>p", "client.tab.previous")
rex.bind("ctrl+b>,", "client.tab.rename")
rex.bind("ctrl+b>shift+7", "client.tab.close") -- prefix + &

-- Go to tab 1..9
for i = 1, 9 do
  rex.bind("ctrl+b>" .. i, "client.tab.goto", { index = i })
end

-- Panes
rex.bind("ctrl+b>z", "pane.zoom")
rex.bind("ctrl+b>x", "pane.close")
rex.bind("ctrl+b>shift+[Backslash]", "pane.split", { direction = "right" })
rex.bind("ctrl+b>-", "pane.split", { direction = "down" })

-- Focus panes with prefix + h/j/k/l
rex.bind("ctrl+b>h", "pane.focus.left")
rex.bind("ctrl+b>j", "pane.focus.down")
rex.bind("ctrl+b>k", "pane.focus.up")
rex.bind("ctrl+b>l", "pane.focus.right")

-- Direct ctrl+h/j/k/l: move between panes, but hand the key to vim/nvim when
-- one owns the pane. This is Rex's version of herdr's vim-herdr-navigation
-- plugin: it checks the pane's foreground process, so nvim splits and Rex
-- panes navigate with the same keys. Add more program names to FORWARD_TO
-- if you want other full-screen programs to receive the keys instead.
local FORWARD_TO = { vim = true, nvim = true, vi = true }

-- A key handler (rex.bind with a function) may not queue client actions, so
-- the check lives in an action and the keys bind to it directly.
rex.action{
  name  = "pane_focus_or_forward",
  title = "Focus Pane or Forward Key",
  args  = { key = "string", direction = "string" },
  run   = function(ctx, args)
    local ok, proc = pcall(rex.block.call, "com.superlogical.terminal", "process", {})
    local fg = ok and proc and proc.foreground
    local name = fg and (fg.name or fg.argv0)
    if name ~= nil and FORWARD_TO[name] then
      rex.client.queue("pane.send_key", { key = args.key })
    else
      rex.client.queue("pane.focus." .. args.direction)
    end
  end,
}

rex.bind("ctrl+h", "pane_focus_or_forward", { key = "ctrl+h", direction = "left" })
rex.bind("ctrl+j", "pane_focus_or_forward", { key = "ctrl+j", direction = "down" })
rex.bind("ctrl+k", "pane_focus_or_forward", { key = "ctrl+k", direction = "up" })
rex.bind("ctrl+l", "pane_focus_or_forward", { key = "ctrl+l", direction = "right" })

-- Rex has no "detach"; hide the app instead (closest equivalent).
-- Comment out if you'd rather prefix+d do nothing.
rex.bind("ctrl+b>d", "client.visibility.toggle")

-- Help: herdr uses prefix+?; Rex's closest is the command palette.
rex.bind("ctrl+b>shift+[Slash]", "client.palette.toggle")

-- Press ctrl+b twice to send one to the terminal.
rex.bind("ctrl+b>ctrl+b", "pane.send_key", { key = "ctrl+b" })

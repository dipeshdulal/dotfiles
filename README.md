## Configuration for my nvim setup

```
git clone https://github.com/dipeshdulal/my-nvim-config ~/.config/nvim
```

## Sessionizer

Fuzzy-pick a project and open it as a workspace inside the single persistent,
agent-aware [herdr](https://herdr.dev) session. This is a port of ThePrimeagen's
[`tmux-sessionizer`](https://github.com/ThePrimeagen/.dotfiles/blob/master/bin/.local/scripts/tmux-sessionizer)
to herdr — each project becomes a herdr *workspace* instead of a tmux session,
all within one session. Requires `fzf` and `jq`. Save as `~/herdr-sessionizer.sh`,
`chmod +x` it, and bind it to a key.

```bash
#!/bin/bash

# herdr-sessionizer
# Fuzzy-pick a project and open it as a workspace inside the single
# persistent, agent-aware herdr session.
# Port of tmux-sessionizer (ThePrimeagen) to herdr:
#   tmux session  ->  herdr workspace (project = workspace, all in one session)

selected=$(find ~/projects -mindepth 1 -maxdepth 2 -type d | fzf)

if [[ -z $selected ]]; then
  exit 0
fi

label=$(basename "$selected" | tr . _)

# The workspace API talks to the herdr server over its socket — make sure it's up.
if ! herdr status server >/dev/null 2>&1; then
  herdr server >/dev/null 2>&1 &
  for _ in $(seq 1 30); do
    herdr status server >/dev/null 2>&1 && break
    sleep 0.1
  done
fi

# Reuse an existing workspace with this label, else create one at the project dir.
existing=$(herdr workspace list 2>/dev/null \
  | jq -r --arg l "$label" '.result.workspaces[]? | select(.label==$l) | .workspace_id' \
  | head -n1)

if [[ -n $existing ]]; then
  herdr workspace focus "$existing" >/dev/null
else
  herdr workspace create --cwd "$selected" --label "$label" --focus >/dev/null
fi

# If we're not already inside a herdr pane, attach the client to land in it.
if [[ "${HERDR_ENV:-}" != "1" ]]; then
  exec herdr
fi
```

> The original tmux-based sessionizer still works with the tmux setup below; the
> navigation config falls back to tmux when you're not inside a herdr pane.

## herdr Setup

[herdr](https://herdr.dev) is the terminal multiplexer this config is wired for.
Seamless `Ctrl+h/j/k/l` navigation between Neovim splits and herdr panes comes
from [`vim-herdr-navigation`](https://github.com/paulbkim-dev/vim-herdr-navigation)
(a port of `vim-tmux-navigator`). Two cooperating sides — a herdr plugin that
forwards the chord into Vim or moves pane focus, and the Neovim maps loaded by
`lua/plugins/tmux-navigator.lua`.

**1. Link the plugin** (checkout lives at `~/Projects/vim-herdr-navigation`):

```bash
herdr plugin link ~/Projects/vim-herdr-navigation
herdr plugin action list --plugin vim-herdr-navigation
```

**2. Bind the keys** in `~/.config/herdr/config.toml`, then reload
(`prefix+shift+r`) or restart:

```toml
[[keys.command]]
key = "ctrl+h"
type = "plugin_action"
command = "vim-herdr-navigation.left"
description = "navigate left (vim/herdr)"

[[keys.command]]
key = "ctrl+j"
type = "plugin_action"
command = "vim-herdr-navigation.down"
description = "navigate down (vim/herdr)"

[[keys.command]]
key = "ctrl+k"
type = "plugin_action"
command = "vim-herdr-navigation.up"
description = "navigate up (vim/herdr)"

[[keys.command]]
key = "ctrl+l"
type = "plugin_action"
command = "vim-herdr-navigation.right"
description = "navigate right (vim/herdr)"
```

**3. Neovim side** is already wired in `lua/plugins/tmux-navigator.lua`: it
disables `vim-tmux-navigator`'s default maps and sources this checkout's
`editor/nvim.lua` as the single source of truth. Adjust the path there if your
checkout isn't at `~/Projects/vim-herdr-navigation`. It falls back to tmux
(`$TMUX`) or plain `wincmd` when you're not in a herdr pane, so the tmux setup
below keeps working. Requires herdr `>= 0.7.0` and `jq`.

## Alacritty Setup

```toml
[window]
decorations = "Buttonless"
padding = { y = 5 }

[font]
normal = { family = "Hack Nerd Font" }
size = 12
```


## Tmux Setup `~/.tmux.conf` 
```
set -g mouse on
unbind '"'
unbind %

bind | split-window -h
bind - split-window -v

bind r source-file ~/.tmux.conf \; display-message "Config reloaded..."

# Set hyperlinks
set -ga terminal-features "*:hyperlinks"

# Vi mode
setw -g mode-keys vi

# List of plugins
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'christoomey/vim-tmux-navigator'
set -g @plugin 'catppuccin/tmux'

set -g @catppuccin_window_left_separator ""
set -g @catppuccin_window_right_separator " "
set -g @catppuccin_window_middle_separator " █"
set -g @catppuccin_window_number_position "right"

set -g @catppuccin_flavour 'macchiato'
set -g @catppuccin_status_modules_right "application session"

# Initialize TMUX plugin manager (keep this line at the very bottom of tmux.conf)
run '~/.tmux/plugins/tpm/tpm'

```

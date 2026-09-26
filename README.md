# dotfiles

Neovim, pi, herdr, tmux and zsh configuration, plus the Hyprland (DMS)
window/binding overrides and the desktop file-manager setup, symlinked into
place by `install.sh`.

```bash
git clone https://github.com/dipeshdulal/dotfiles ~/dotfiles
cd ~/dotfiles && ./install.sh
```

`install.sh` is idempotent — re-run it after adding a topic. Existing real files
are moved to `<path>.bak` rather than overwritten, so a first run on a machine
that already has configs is non-destructive.

Because everything is symlinked, editing a config in its normal location edits
this repo. `git status` shows drift immediately; there is no sync step.

## Layout

| topic     | repo path             | links to                          |
| --------- | --------------------- | --------------------------------- |
| nvim      | `nvim/`               | `~/.config/nvim`                  |
| pi        | `pi/agent/`           | `~/.pi/agent/*` (per file)        |
| skills    | `claude/skills/*`     | `~/.claude/skills/*`              |
| herdr     | `herdr/config.toml`   | `~/.config/herdr/config.toml`     |
| zsh       | `zsh/zshrc`           | `~/.zshrc`                        |
| tmux      | `tmux/tmux.conf`      | `~/.tmux.conf`                    |
| hypr      | `hypr/`               | `~/.config/hypr/…` (per file)     |
| desktop   | `desktop/`            | not symlinked; run `setup.sh`     |
| bin       | `bin/`                | `~/.local/bin/`                   |

## Secrets

**No credentials live in this repo.** `~/.pi/agent/auth.json` holds pi's API
keys and is gitignored; `install.sh` never touches it. After cloning to a new
machine, run `pi` and authenticate.

Also deliberately untracked: `pi/agent/sessions/` (chat history),
`pi/agent/npm/node_modules/`, `pi/agent/models-store.json` (regenerable cache),
and herdr's `*.log` / `*.sock` / `session.json` runtime state.

## Post-install

`install.sh` prints these, repeated here:

1. **pi auth** — run `pi` and authenticate.
2. **pi packages** — run `pi` once; it installs the extensions declared in
   `pi/agent/settings.json` into `~/.pi/agent/npm/node_modules`, pinned by the
   tracked `package-lock.json`.
3. **nvim plugins** — launch `nvim`; lazy.nvim restores from `nvim/lazy-lock.json`.
4. **tmux plugins** — `git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm`,
   then `tmux source ~/.tmux.conf` and `prefix+I`.
5. **herdr navigation** — `herdr plugin link ~/projects/vim-herdr-navigation`.
6. **desktop** — `./desktop/setup.sh` installs Nautilus + previews and makes it
   the default file manager.

## Sessionizer

`bin/herdr-sessionizer.sh` fuzzy-picks a project and opens it as a workspace
inside the single persistent, agent-aware [herdr](https://herdr.dev) session. A
port of ThePrimeagen's
[`tmux-sessionizer`](https://github.com/ThePrimeagen/.dotfiles/blob/master/bin/.local/scripts/tmux-sessionizer)
where each project becomes a herdr *workspace* rather than a tmux session.
Requires `fzf` and `jq`. Bound to `f` in `zsh/zshrc`.

## herdr navigation

Seamless `Ctrl+h/j/k/l` between Neovim splits and herdr panes comes from
[`vim-herdr-navigation`](https://github.com/paulbkim-dev/vim-herdr-navigation)
(a port of `vim-tmux-navigator`). Two cooperating sides: a herdr plugin that
forwards the chord into Vim or moves pane focus, and the Neovim maps loaded by
`nvim/lua/plugins/tmux-navigator.lua`.

The keybindings live in the tracked `herdr/config.toml`. The Neovim side sources
the checkout's `editor/nvim.lua` as the single source of truth — adjust the path
in `nvim/lua/plugins/tmux-navigator.lua` if your checkout isn't at
`~/projects/vim-herdr-navigation`. It falls back to tmux (`$TMUX`) or plain
`wincmd` outside a herdr pane. Requires herdr `>= 0.7.0` and `jq`.

## Desktop / file manager

Files is **Nautilus** (GNOME Files) with **Sushi** for spacebar quick-look,
replacing Dolphin. `desktop/setup.sh` installs the packages in
`desktop/packages.txt` and points `inode/directory` at Nautilus.

The Hyprland side is tracked under `hypr/`:

- `hypr/dms/binds-user.lua` — per-user DMS keybinds. `SUPER+E` opens
  `nautilus --new-window`.
- `hypr/hyprland.lua` — user Hyprland config. Floats both the Nautilus window
  and the Sushi previewer (`org.gnome.NautilusPreviewer`), so quick-look opens
  as a floating panel instead of being tiled.

Notes:

- Nautilus 50 pulls in the GNOME indexer (`localsearch` / `tinysparql`). Mask
  it for no background indexing:
  `systemctl --user mask localsearch-3.service tinysparql-3.service`.
- **Do not install `hyprpolkitagent`.** DMS already runs a polkit agent via
  Quickshell; a second one fails to register ("an authentication agent already
  exists") and then segfaults. It is only needed on bare Hyprland without DMS.
- Removing Dolphin: protect deps you still want first —
  `sudo pacman -D --asexplicit udisks2 upower ripgrep` — then
  `sudo pacman -Rns dolphin`.
- `hyprctl reload` re-reads bindings but does not reliably re-apply Lua window
  rules; a full Hyprland restart does.

## Alacritty

Not tracked (no live config on this machine). For reference:

```toml
[window]
decorations = "Buttonless"
padding = { y = 5 }

[font]
normal = { family = "Hack Nerd Font" }
size = 12
```

#!/usr/bin/env bash
# Symlink every tracked config into place. Idempotent; re-run after adding topics.
# Existing real files are moved aside to <path>.bak rather than overwritten.

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

link() {
  local src="$DOTFILES/$1" dest="$2"

  if [[ ! -e $src ]]; then
    echo "  skip   $2 (missing $1)"
    return
  fi

  if [[ -L $dest ]]; then
    if [[ "$(readlink "$dest")" == "$src" ]]; then
      echo "  ok     $2"
      return
    fi
    rm "$dest"
  elif [[ -e $dest ]]; then
    local backup="$dest.bak"
    [[ -e $backup ]] && backup="$dest.bak.$(date +%s)"
    mv "$dest" "$backup"
    echo "  backup $2 -> $(basename "$backup")"
  fi

  mkdir -p "$(dirname "$dest")"
  ln -s "$src" "$dest"
  echo "  link   $2"
}

echo "nvim"
link nvim "$HOME/.config/nvim"

echo "pi"
link pi/web-search.json                  "$HOME/.pi/web-search.json"
link pi/agent/settings.json              "$HOME/.pi/agent/settings.json"
link pi/agent/zentui.json                "$HOME/.pi/agent/zentui.json"
link pi/agent/claude-bridge.json         "$HOME/.pi/agent/claude-bridge.json"
link pi/agent/themes/gothalo.json        "$HOME/.pi/agent/themes/gothalo.json"
link pi/agent/npm/package.json           "$HOME/.pi/agent/npm/package.json"
link pi/agent/npm/package-lock.json      "$HOME/.pi/agent/npm/package-lock.json"
for ext in "$DOTFILES"/pi/agent/extensions/*.ts; do
  link "pi/agent/extensions/$(basename "$ext")" "$HOME/.pi/agent/extensions/$(basename "$ext")"
done

echo "claude skills"
for skill in "$DOTFILES"/claude/skills/*/; do
  name="$(basename "$skill")"
  link "claude/skills/$name" "$HOME/.claude/skills/$name"
done

echo "herdr"
link herdr/config.toml "$HOME/.config/herdr/config.toml"

echo "rex"
link rex/init.lua "$HOME/.config/rex/init.lua"

echo "zsh"
link zsh/zshrc "$HOME/.zshrc"
link zsh/p10k.zsh "$HOME/.p10k.zsh"

# Omarchy defaults to bash, where the zsh alias above does nothing.
echo "bash"
if [[ -f $HOME/.bashrc ]] && ! grep -q "herdr-sessionizer" "$HOME/.bashrc"; then
  printf '\n# Fuzzy-pick a project and open it as a herdr workspace.\nalias f="bash ~/.local/bin/herdr-sessionizer.sh"\n' >>"$HOME/.bashrc"
  echo "  add    ~/.bashrc alias f"
fi

# fzf key bindings (Ctrl+R history, Ctrl+T files, Alt+C cd). Omarchy sources
# fzf's completion but not its key bindings, so Ctrl+R does nothing by default.
if [[ -f $HOME/.bashrc ]] && ! grep -q "fzf/key-bindings.bash" "$HOME/.bashrc"; then
  printf '\n# fzf key bindings: Ctrl+R history, Ctrl+T files, Alt+C cd.\n[[ -r /usr/share/fzf/key-bindings.bash ]] && source /usr/share/fzf/key-bindings.bash\n' >>"$HOME/.bashrc"
  echo "  add    ~/.bashrc fzf key bindings"
fi

# Bash completions for tools that ship none in bash-completion. These live in
# the per-user dir, which bash-completion loads lazily by command name.
echo "completions"
comp_dir="$HOME/.local/share/bash-completion/completions"
mkdir -p "$comp_dir"
gen_completion() {
  local cmd="$1"
  shift
  command -v "$cmd" >/dev/null 2>&1 || return 0
  [[ -s "$comp_dir/$cmd" ]] && return 0
  "$@" >"$comp_dir/$cmd" 2>/dev/null && echo "  gen    $cmd" || rm -f "$comp_dir/$cmd"
}
gen_completion herdr herdr completion bash
gen_completion mise mise completion bash
gen_completion gh gh completion -s bash

echo "tmux"
link tmux/tmux.conf "$HOME/.tmux.conf"

echo "hypr"
if [[ -d /usr/share/omarchy ]]; then
  # Omarchy owns hyprland.lua and the rest of the defaults, so only our
  # override files are linked. `omarchy refresh hyprland` restores the
  # package versions if these ever need to be reset.
  link hypr/omarchy/monitors.lua  "$HOME/.config/hypr/monitors.lua"
  link hypr/omarchy/bindings.lua  "$HOME/.config/hypr/bindings.lua"
  link hypr/omarchy/looknfeel.lua "$HOME/.config/hypr/looknfeel.lua"
else
  # Bare Hyprland + DMS (the archtower setup).
  link hypr/hyprland.lua       "$HOME/.config/hypr/hyprland.lua"
  link hypr/dms/binds-user.lua "$HOME/.config/hypr/dms/binds-user.lua"
fi

echo "bin"
link bin/herdr-sessionizer.sh "$HOME/.local/bin/herdr-sessionizer.sh"

cat <<'EOF'

Done. Remaining manual steps:

  1. pi auth      pi does not store credentials in this repo. Run `pi` and
                  authenticate, or write ~/.pi/agent/auth.json by hand.
  2. pi packages  Run `pi` once; it installs the extensions declared in
                  settings.json into ~/.pi/agent/npm/node_modules.
  3. nvim plugins Launch `nvim`; lazy.nvim restores from nvim/lazy-lock.json.
  4. tmux plugins git clone https://github.com/tmux-plugins/tpm \
                    ~/.tmux/plugins/tpm && tmux source ~/.tmux.conf, then prefix+I
  5. herdr nav    herdr plugin link ~/projects/vim-herdr-navigation
  6. desktop      ./desktop/setup.sh  (Nautilus file manager + previews)
  7. input        ./fcitx5/setup.sh   (Fcitx5 + Mozc + m17n: Japanese and
                                       Nepali typing)
EOF

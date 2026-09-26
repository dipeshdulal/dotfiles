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

echo "zsh"
link zsh/zshrc "$HOME/.zshrc"
link zsh/p10k.zsh "$HOME/.p10k.zsh"

echo "tmux"
link tmux/tmux.conf "$HOME/.tmux.conf"

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
EOF

#!/usr/bin/env bash
# Desktop apps: Nautilus (GNOME Files) as the file manager, replacing Dolphin.
#
# Installs the packages listed in packages.txt and makes Nautilus the handler
# for directories. The Hyprland keybind (SUPER+E) and the floating quick-look
# window rule come from the symlinked ../hypr/ config, not from here.
#
# Safe to re-run.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC2046  # intentional word-splitting of the package list
packages=$(grep -vE '^[[:space:]]*(#|$)' "$HERE/packages.txt")

echo "desktop: installing file manager packages"
# shellcheck disable=SC2086
sudo pacman -S --needed --noconfirm $packages

echo "desktop: setting Nautilus as the default directory handler"
xdg-mime default org.gnome.Nautilus.desktop inode/directory

# DMS (DankMaterialShell) ships its own polkit agent via Quickshell. Do not
# install hyprpolkitagent alongside it: registration fails with "An
# authentication agent already exists" and the binary segfaults on exit.
if pacman -Qq hyprpolkitagent >/dev/null 2>&1; then
  cat <<'EOF'

note: hyprpolkitagent is installed but DMS already provides a polkit agent.
      Remove it to avoid the failed systemd unit:

        sudo pacman -Rns hyprpolkitagent
EOF
fi

if command -v dolphin >/dev/null 2>&1; then
  cat <<'EOF'

note: Dolphin is still installed. Nautilus is now the default, so it is only
      needed if you actually use it. A blanket `pacman -Rns dolphin` also
      removes deps you probably want (udisks2, upower, ripgrep, gvfs,
      smbclient, libmtp). Protect those first:

        sudo pacman -D --asexplicit udisks2 upower ripgrep
        sudo pacman -Rns dolphin
EOF
fi

cat <<'EOF'

Done. Reload or restart Hyprland to pick up the SUPER+E bind and window rules:

  hyprctl reload      # may not re-apply Lua window rules; a restart always will
EOF

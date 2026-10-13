#!/usr/bin/env bash
# Japanese + Nepali input: Fcitx5 + Mozc + m17n (ne-rom).
#
# Installs the packages listed in packages.txt -- all from the official
# repos, no AUR -- then seeds ~/.config/fcitx5 from the files in this
# directory. The Hyprland side (env vars and autostart) lives in
# ../hypr/hyprland.lua.
#
# Usage:
#   ./setup.sh
#
# Safe to re-run. An existing ~/.config/fcitx5 is never overwritten: fcitx5
# owns those files once it has run and rewrites them on exit, so this only
# fills them in the first time.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for arg in "$@"; do
  case "$arg" in
    -h | --help)
      sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "unknown argument: $arg (try --help)" >&2
      exit 2
      ;;
  esac
done

# --- Privilege gate --------------------------------------------------------
#
# `sudo -n true` NEVER prompts and NEVER counts as an authentication attempt.
# Running the real work without a cached credential instead means pacman asks
# via $SUDO_ASKPASS, and each empty or wrong answer spends one of the three
# pam_faillock strikes this machine allows (deny=3). Three of those lock the
# account for unlock_time=600s, and pam_faillock.so preauth then rejects even
# the correct password everywhere -- terminals included. See
# ../bin/sudo-askpass.sh for the full explanation.
#
# So: fail here, early, having spent nothing, and let the user authenticate
# themselves where they can see what is happening.
if ! sudo -n true 2>/dev/null; then
  cat >&2 <<'EOF'
Need sudo privileges, and none are cached. Authenticating on your behalf is
risky here: this machine's pam_faillock allows only 3 failed sudo attempts
before locking the account for 10 minutes, and a lockout also rejects your
correct password.

Run this yourself first, in your own terminal:

  sudo -v

then re-run this script.
EOF
  exit 1
fi

# --- Install ---------------------------------------------------------------
# shellcheck disable=SC2046  # intentional word-splitting of the package list
packages=$(grep -vE '^[[:space:]]*(#|$)' "$HERE/packages.txt")
echo "==> fcitx5: installing packages from the official repos"
# shellcheck disable=SC2086
sudo pacman -S --needed --noconfirm $packages

# --- Seed config -----------------------------------------------------------
if pgrep -x fcitx5 >/dev/null 2>&1; then
  cat <<'EOF'

  note: fcitx5 is already running. Stop it from the tray icon (or
        `fcitx5-remote -e`) before hand-editing ~/.config/fcitx5, otherwise
        its save-on-exit will overwrite the changes.

EOF
fi

FCITX5_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/fcitx5"
mkdir -p "$FCITX5_DIR"

seed() {
  local src="$HERE/$1" dest="$FCITX5_DIR/$1"

  if [[ ! -e $src ]]; then
    echo "  skip   $dest (missing $1)"
  elif [[ -e $dest ]]; then
    echo "  keep   $dest"
  else
    cp "$src" "$dest"
    echo "  seed   $dest"
  fi
}

echo "==> fcitx5: seeding config"
seed profile
seed config

cat <<'EOF'

Done. The Hyprland side is already configured in ../hypr/hyprland.lua, so
just start fcitx5 for this session (it autostarts on future logins):

  fcitx5 -d --replace

Then:

  Ctrl+Space         next language:  U.S. -> Japanese -> Nepali -> U.S.
  Ctrl+Shift+Space   previous language

Japanese: Ctrl+Space until the indicator shows the Japanese engine, type
`nihongo`, press Space to convert. While composing, F6..F10 switch
hiragana / katakana / half-width (see ../README.md).

Nepali: Ctrl+Space again. m17n's ne-rom is the MPP romanized *layout* -- one
key per glyph, not a transliteration:

  k a Q m a x w M   ->   काठमाडौं
  n e p a l         ->   नेपाल
  n m s / t e       ->   नमस्ते
EOF

if ! fc-list :lang=ja >/dev/null 2>&1; then
  cat <<'EOF'

note: no CJK font found, so Japanese will render as boxes:
  sudo pacman -S noto-fonts-cjk
EOF
fi

if ! fc-list :lang=ne >/dev/null 2>&1; then
  cat <<'EOF'

note: no Devanagari font found, so Nepali will render as boxes:
  sudo pacman -S noto-fonts
EOF
fi

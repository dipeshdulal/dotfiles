#!/usr/bin/env bash
# Japanese + Nepali romaji input: Fcitx5 + Mozc + Lekhika.
#
# Installs the packages listed in packages.txt (official repos) and
# packages-aur.txt (AUR, compiled from source), then seeds
# ~/.config/fcitx5 from the files in this directory. The Hyprland side
# (GTK_IM_MODULE and friends, plus the autostart) lives in
# ../hypr/hyprland.lua.
#
# Usage:
#   ./setup.sh              install + seed config
#   ./setup.sh --dictionary  also download the 113 MB word-suggestion DB
#
# Safe to re-run. An existing ~/.config/fcitx5 is never overwritten: fcitx5
# owns those files once it has run and rewrites them on exit, so this only
# fills them in the first time.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Where lekhika's core expects to find the pre-trained dictionary.
LEKHIKA_DICT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/lekhika-core"
LEKHIKA_DICT="$LEKHIKA_DICT_DIR/lekhikadict.akshardb"
LEKHIKA_DICT_URL='https://github.com/khumnath/fcitx5-lekhika/releases/download/dictionary/lekhikadict.akshardb'

want_dictionary=false
for arg in "$@"; do
  case "$arg" in
    --dictionary) want_dictionary=true ;;
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

# shellcheck disable=SC2046  # intentional word-splitting of the package list
packages=$(grep -vE '^[[:space:]]*(#|$)' "$HERE/packages.txt")
# shellcheck disable=SC2046
aur_packages=$(grep -vE '^[[:space:]]*(#|$)' "$HERE/packages-aur.txt")

# --- Privilege gate --------------------------------------------------------
#
# `sudo -n true` NEVER prompts and NEVER counts as an authentication attempt.
# Running the real work without a cached credential instead means pacman/yay
# ask via $SUDO_ASKPASS, and each empty or wrong answer spends one of the three
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

# --- Official repositories -------------------------------------------------
echo "==> fcitx5: installing packages from the official repos"
# shellcheck disable=SC2086
sudo pacman -S --needed --noconfirm $packages

# --- AUR (compiled from source) -------------------------------------------
#
# Deliberately non-fatal: the Nepali engine is the newest and least
# packaged piece here. If it fails to build, Japanese still works and the
# Nepali group can simply be left alone.
echo "==> fcitx5: installing the Nepali engine from the AUR"
aur_ok=true
if command -v yay >/dev/null 2>&1; then
  # shellcheck disable=SC2086
  yay -S --needed --noconfirm $aur_packages || aur_ok=false
else
  aur_ok=false
  cat >&2 <<'EOF'

  WARNING: no AUR helper found, so the Nepali engine was skipped.
           Install one (e.g. `sudo pacman -S paru` or `yay`), then run:
             yay -S liblekhika-git fcitx5-lekhika-git

EOF
fi

# The authoritative check is the inputmethod descriptor that
# fcitx5-lekhika installs, not the exit status above.
lekhika_conf=/usr/share/fcitx5/inputmethod/fcitx5lekhika.conf
if [[ ! -f $lekhika_conf ]]; then
  aur_ok=false
  cat >&2 <<EOF

  WARNING: the Nepali engine is not installed ($lekhika_conf is missing),
           but ./profile lists fcitx5lekhika as the Nepali group's input
           method. Fcitx5 does not crash on this -- it logs
           "Group Item fcitx5lekhika ... is not valid. Removed." and the
           Nepali group degenerates into a second, redundant US keyboard
           group that Ctrl+Shift+Space will still cycle to.

           Once the build succeeds, re-seed so the profile takes effect:
             rm ~/.config/fcitx5/profile && ./setup.sh

EOF
fi

# --- Optional dictionary ---------------------------------------------------
if [[ $want_dictionary == true ]]; then
  if [[ -s $LEKHIKA_DICT ]]; then
    echo "==> lekhika: dictionary already present, skipping"
  else
    echo "==> lekhika: downloading word-suggestion dictionary (113 MB)"
    mkdir -p "$LEKHIKA_DICT_DIR"
    # -C - so an interrupted download resumes instead of restarting.
    curl -fL --progress-bar -C - -o "$LEKHIKA_DICT" "$LEKHIKA_DICT_URL" || {
      rm -f "$LEKHIKA_DICT"
      echo "==> lekhika: dictionary download failed" >&2
    }
  fi
fi

# --- Seed config ----------------------------------------------------------
if pgrep -x fcitx5 >/dev/null 2>&1; then
  cat <<'EOF'

  note: fcitx5 is already running. Stop it from the tray icon (or `fcitx5-rm`)
        before hand-editing ~/.config/fcitx5, otherwise its save-on-exit will
        overwrite the changes.

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

  Ctrl+Space         toggle the IME in the current language
  Ctrl+Shift+Space   switch language:  Japanese  <->  Nepali

Japanese: Ctrl+Space, type `nihongo`, press Space to convert.

Check the current state any time with `fcitx5-remote` (1 = ASCII,
2 = IME on). Run `fcitx5-diagnose` if anything misbehaves.
EOF

if [[ $aur_ok == true ]]; then
  cat <<'EOF'

Nepali: Ctrl+Shift+Space, Ctrl+Space, type `namaste`, press Space.
EOF
else
  cat <<'EOF'

Nepali is NOT usable yet -- see the warnings above. Only Japanese is
working at this point; Ctrl+Shift+Space is not needed for it.
EOF
fi

if ! fc-list :lang=ja >/dev/null 2>&1; then
  cat <<'EOF'

note: no CJK font found, so Japanese will render as boxes:
  sudo pacman -S noto-fonts-cjk
EOF
fi

if [[ $want_dictionary != true && $aur_ok == true ]]; then
  cat <<'EOF'

The Nepali engine transliterates correctly without any dictionary; the
database only adds word suggestions. To add them later:
  ./setup.sh --dictionary
EOF
fi
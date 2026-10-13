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
7. **screenshots** — `yay -S --needed omasnap-bin tesseract tesseract-data-eng`
   (Omasnap, from the AUR; binds are in the tracked `hypr/` config).

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
  `nautilus --new-window`; `SUPER+B` opens the default browser via
  `dms ipc call defaultApp browser`.
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

## sudo from scripts and agent tool calls

`bin/sudo-askpass.sh` gives `sudo` a graphical prompt (zenity on Wayland) via
`SUDO_ASKPASS` + `SUDO_ASKPASS_REQUIRE=force`, exported from `zsh/zshenv` so it
also applies to non-interactive shells and agent tool calls.

**The constraint that shapes everything here:** `/etc/pam.d/system-auth` enables
`pam_faillock`, and `/etc/security/faillock.conf` is entirely commented out, so
the built-in defaults apply — `deny=3`, `fail_interval=900`, `unlock_time=600`.
That means:

- Only **3** failed sudo attempts before the account locks for 10 minutes.
- During a lockout, `pam_faillock.so preauth` rejects auth *before* the password
  is checked, so the **correct password fails everywhere**, terminals included.
- An empty answer from askpass counts as a failure, and sudo retries 3 times on
  its own. A helper that gave up on the first dismissed dialog would therefore
  burn all three strikes at once and lock you out.

Consequences:

- `sudo-askpass.sh` re-prompts until it gets a password instead of exiting on an
  empty one, and no longer hides zenity's stderr — swallowed errors previously
  made a failed dialog look like a wrong password.
- Non-interactive scripts must check `sudo -n true` and abort if it fails.
  `-n` never prompts and never spends a strike; `sudo -v` still spends strikes
  on failure. `fcitx5/setup.sh` does this.

If you do get locked out, the lock clears itself after `unlock_time` (10 min);
`faillock` shows the pending records and `faillock -u dipesh` clears them as root.

## Japanese + Nepali input (Fcitx5 + Mozc + m17n)

Japanese uses Mozc (Google Japanese Input); Nepali uses m17n's `ne-rom`, the
romanized **keyboard layout** published by MPP (Madan Puraskar Pustakalaya) —
the same layout as the "Nepali Romanized" Keyman keyboard. Both engines are
official-repo packages, no AUR.

Set up with `./fcitx5/setup.sh`; the Hyprland side (env vars, autostart) is
already configured in `hypr/hyprland.lua`.

| Key | Action |
| --- | --- |
| `Ctrl+Space` | next language: U.S. → Japanese → Nepali → U.S. |
| `Ctrl+Shift+Space` | previous language |

All three live in **one group**, so `Ctrl+Space` walks the list the way macOS
cycles input sources. There is no separate IME on/off toggle: the `keyboard-us`
entry *is* the off state. So Japanese is `Ctrl+Space` then `nihongo` + `Space`;
Nepali is `Ctrl+Space` again, then `k a Q m a x w M` → काठमाडौं.

`Ctrl+Space` is used because Hyprland does not bind it — `Super+Space` and
`Alt+Space` are DMS spotlight. The `Ctrl+Space` in `fcitx5/config` is
*EnumerateForwardKeys*, not the built-in *TriggerKeys* (also `Ctrl+Space`).
Trigger is matched first, so it is cleared in `config` to stop it swallowing the
chord and toggling on/off instead of walking.

### Kana modes (the macOS "ひらがな / カタカナ" menu)

There is no menu, because in Mozc the kana widths are not separate input
sources — they are modes *inside* the one Japanese entry, switched from the
keyboard. These are Mozc's compiled-in defaults and match macOS' Google IME:

| Key | Result |
| --- | --- |
| `F6` / `Ctrl+u` | ひらがな |
| `F7` / `Ctrl+i` | 全角カタカナ |
| `F8` / `Ctrl+o` | 半角カタカナ |
| `F9` / `Ctrl+p` | 全角ＡＢＣ |
| `F10` / `Ctrl+t` | 半角abc |
| `Space` | 変換 — kanji candidates |
| `Tab` | prediction |

`Hiragana` / `Katakana` / `Eisu` / `Muhenkan` are physical JIS keys, so on a US
keyboard `F6`–`F10` is the way in.

### Nepali — MPP romanized layout

`ne-rom` is a *fixed keyboard layout*, not a transliteration like Lekhika: each
key produces one glyph, there is no candidate list, and **case matters**.
Uppercase generally gives independent vowels and aspirates, lowercase gives
consonants and vowel *signs* (matras).

Consonants (mostly lowercase — note `c`/`C` and `s`/`z` invert the usual case):

```
 k क    K ख    g ग    G घ    < ङ
 c छ    C च    j ज    J झ    Y ञ
 q ट    Q ठ    x ड    X ढ    N ण
 t त    T थ    d द    D ध    n न
 p प    P फ    b ब    B भ    m म
 y य    r र    l ल    v व
 s स    S श    z ष    h ह
```

Vowels — independent (upper) vs. vowel sign / matra (lower):

```
 H अ    A आ    a ा
 [ इ    { ई    i ि    I ी
 f उ    F ऊ    u ु    U ू
 Z ऋ    R ृ
 ] ए    } ऐ    e े    E ै
 O ओ    W औ    o ो    w ौ
```

Marks and punctuation:

```
 M ं  (anusvara)    V ँ  (candrabindu)   / ्  (halant)
 . ।  (danda)       > ॥  (double danda)  | ः  (visarga)
 ~ ऽ                ` ़  (nukta)         \ ॐ    $ रु
 0-9 → ०-९
```

Note the halant: consonant clusters need `/` (्). So `k a Q m a x w M` is
क + ा + ठ + म + ा + ड + ौ + ं = **काठमाडौं**; `n e p a l` is **नेपाल**; and
`n m s / t e` is **नमस्ते** (न + म + स + ् + त + े). Plain `n m s t e` gives
नमसते. The authoritative map is `/usr/share/m17n/ne-rom.mim`.

Notes:

- The group uses the `us` XKB layout, even for Nepali. `ne-rom` maps the ASCII
  keysyms of a US layout to Devanagari, so it needs plain US keys, not an `np`
  keymap. Fcitx's XKB-layout management only works on KDE/GNOME anyway; on
  Hyprland the group layout must match `input.kb_layout`, which here inherits
  `XKB_DEFAULT_LAYOUT = us`.
- The Nepali item is named `m17n_ne_rom`. `fcitx5-m17n` builds entry names as
  `m17n_<lang>_<name>` (`im/engine.cpp`), so it is not the bare `ne-rom`. Other
  Nepali engines `m17n-db` ships: `m17n_ne_rom_translit` (Google-style
  transliteration), `m17n_ne_trad` and `m17n_ne_trad_ttf` (MPP traditional).
- Lekhika was dropped in favour of `ne-rom`. If it is still installed, remove it
  with `yay -Rns fcitx5-lekhika-git liblekhika-git` (and delete
  `~/.local/share/lekhika-core`).
- fcitx5-m17n labels every m17n entry `"<name> (M17N)"`, so `ne-rom` would show
  as the ugly `rom (M17N)`. The display name is fixed with a user override: copy
  `/usr/share/fcitx5/m17n/default` to `~/.local/share/fcitx5/m17n/default`
  (fcitx5-m17n *replaces* the system file, it does not merge it) and change
  `ne:rom:1` to `ne:rom:1:Nepali (MPP Romanized)`. That override is already in
  place on this machine; re-create it after an `m17n-db` upgrade that changes
  the list.
- The active IM and mode are shown in the transient indicator
  (`ShowInputMethodInformation`) on each switch — the closest thing to macOS'
  menu-bar あ/A badge. DMS' bar has no persistent fcitx widget.
- IME is disabled in password fields, so a half-typed romaji preedit cannot be
  committed into a password prompt.
- **`GTK_IM_MODULE` is deliberately not set.** Per the fcitx5 "Using Fcitx 5 on
  Wayland" guide, GTK3/4 reach fcitx through text-input-v3, and a global
  `GTK_IM_MODULE` is the documented cause of the candidate window blinking. The
  im module is requested per-toolkit via `gtk-im-module=fcitx` in
  `~/.config/gtk-3.0/settings.ini` and `~/.config/gtk-4.0/settings.ini` instead.
  `QT_IM_MODULE` stays set (needed on non-KDE for Qt < 6.7), as do
  `SDL_IM_MODULE` and `XMODIFIERS` (for XWayland).
- Profile/config are **copied**, not symlinked, by `setup.sh`. Fcitx5 rewrites
  `~/.config/fcitx5/*` on exit, so a symlink would leave the dotfiles repo
  permanently dirty. Stop Fcitx5 from the tray before editing those by hand.
- Requires `noto-fonts-cjk` for Japanese glyphs and `noto-fonts` for Devanagari;
  `setup.sh` warns if either is missing.
- Check status with `fcitx5-remote` (`1` = ASCII, `2` = IME on); diagnose with
  `fcitx5-diagnose`.

## Screenshots (Omasnap)

Screenshots use **Omasnap** — a native Wayland capture + annotation editor for
Hyprland (the tool extracted from Omarchy) — replacing DMS's built-in
`dms screenshot` bindings:

- `Print` — smart picker (drag = region, click = window, click empty = monitor)
- `CTRL + Print` — full monitor
- `ALT + Print` — window

It also does scroll capture with auto-stitching, annotation (shapes, arrows,
highlighter, text, redaction), OCR, floating previews, and pins.

Install from the AUR (not in the official repos; needs `yay`/`paru`):

```bash
yay -S --needed omasnap-bin tesseract tesseract-data-eng   # tesseract = OCR
```

The binds live in `hypr/dms/binds-user.lua` and the `no_anim` layer rule in
`hypr/hyprland.lua`. Do **not** add `no_screen_share = true` to the Omasnap
layer rule: Hyprland replaces the layer's rectangle with black in captures,
which breaks scroll stitching.

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

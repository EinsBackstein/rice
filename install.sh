#!/usr/bin/env bash
# rice installer — drop-in setup for Kubuntu 26.04 (Plasma 6, Wayland).
#
#   ./install.sh               everything (asks for sudo once)
#   ./install.sh --dry-run     print what would happen, change nothing
#   ./install.sh --no-root     user-level only: dotfiles, binaries, desktop settings
#   ./install.sh --root-only   only the sudo part (packages, uinput, boot splash, login screen)
#   ./install.sh --no-settings skip KDE/GTK/dconf settings
#
# Idempotent: re-run it any time. Existing files that differ are moved to ~/.rice-backup/<timestamp>/.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY=0; DO_ROOT=1; DO_USER=1; DO_SETTINGS=1
for a in "$@"; do
  case "$a" in
    --dry-run) DRY=1 ;;
    --no-root) DO_ROOT=0 ;;
    --root-only) DO_USER=0; DO_SETTINGS=0 ;;
    --no-settings) DO_SETTINGS=0 ;;
    -h|--help) sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $a (see --help)" >&2; exit 2 ;;
  esac
done
export RICE_DRY="$DRY"

[[ $EUID -ne 0 ]] || { echo "Run as your normal user, not root (sudo is called where needed)." >&2; exit 1; }

say()  { printf '\n\033[1;35m▸ %s\033[0m\n' "$*"; }
run()  { if ((DRY)); then echo "+ $*"; else "$@"; fi; }
BACKUP="$HOME/.rice-backup/$(date +%Y%m%dT%H%M%S)"

# ── sanity checks ─────────────────────────────────────────────────────────────
. /etc/os-release
if [[ "${ID:-}" != ubuntu ]] || [[ "${XDG_CURRENT_DESKTOP:-}" != *KDE* && $DRY == 0 && $DO_USER == 1 ]]; then
  echo "Note: made for Kubuntu/KDE (found ${PRETTY_NAME:-?}, desktop '${XDG_CURRENT_DESKTOP:-none}'). Continuing anyway."
fi

backup_and_link() { # src dst
  local src="$1" dst="$2"
  if [[ -L "$dst" && "$(readlink -f "$dst")" == "$(readlink -f "$src")" ]]; then return; fi
  if [[ -e "$dst" || -L "$dst" ]]; then
    run mkdir -p "$BACKUP/$(dirname "${dst#$HOME/}")"
    run mv "$dst" "$BACKUP/${dst#$HOME/}"
  fi
  run mkdir -p "$(dirname "$dst")"
  run ln -s "$src" "$dst"
}

# ── 1. packages + binaries ────────────────────────────────────────────────────
root_packages() {
  say "apt packages (no recommends, so no GNOME Shell/GDM comes along with Nautilus)"
  run sudo apt-get update -qq
  # shellcheck disable=SC2046
  run sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    $(grep -v -e '^#' -e '^$' "$REPO/packages/apt.txt")
}

# ── 2. root-owned files ───────────────────────────────────────────────────────
root_system() {
  say "system files (uinput for xremap, plymouth, SDDM)"
  local f dest
  # plain files mirrored from system/ (the Plymouth theme dir is handled separately below)
  while IFS= read -r -d '' f; do
    dest="/${f#"$REPO/system/"}"
    [[ "$dest" == /usr/share/plymouth/* ]] && continue
    run sudo install -D -m644 "$f" "$dest"
  done < <(find "$REPO/system" -type f -print0)

  # fixed-metrics UI font, system-wide so the SDDM greeter (runs as user "sddm") can use it
  run sudo install -d /usr/local/share/fonts/rice
  run sudo install -m644 "$REPO"/home/.local/share/fonts/SpaceGroteskFixed/*.ttf /usr/local/share/fonts/rice/
  run sudo fc-cache -f /usr/local/share/fonts/rice

  # xremap needs /dev/uinput + input devices
  run sudo modprobe uinput
  run sudo udevadm control --reload
  run sudo udevadm trigger --name-match=uinput
  if [[ " $(id -nG "$USER") " != *" input "* ]]; then
    run sudo usermod -aG input "$USER"
    NEED_RELOGIN=1
  fi
  run sudo systemctl daemon-reload

  # login screen: wallpaper + accent for whichever SDDM theme exists
  local t tdir
  for t in kubuntu breeze; do
    tdir="/usr/share/sddm/themes/$t"; [[ -d "$tdir" ]] || continue
    run sudo install -m644 "$REPO/assets/wallpapers/ryoku-dreamchaser.png" "$tdir/rice-wallpaper.png"
    if ((DRY)); then echo "+ write $tdir/theme.conf.user"; else
      sed "s|@WALLPAPER@|$tdir/rice-wallpaper.png|" "$REPO/templates/sddm-theme.conf.user.tpl" | sudo tee "$tdir/theme.conf.user" >/dev/null
    fi
  done

  # boot splash
  local theme=/usr/share/plymouth/themes/rice stamp=/var/lib/rice/plymouth.stamp new cur="" cur_alt
  new="$(cat "$REPO"/system/usr/share/plymouth/themes/rice/* "$REPO/assets/wallpapers/ryoku-dreamchaser.png" "$REPO/system/etc/systemd/system/plymouth-quit.service.d/retain-splash.conf" | sha256sum | cut -d' ' -f1)"
  [[ -r "$stamp" ]] && cur="$(cat "$stamp")"
  cur_alt="$(readlink -f /usr/share/plymouth/themes/default.plymouth 2>/dev/null || true)"
  if [[ "$new" == "$cur" && "$cur_alt" == "$theme/rice.plymouth" ]]; then
    echo "plymouth theme already installed"
  else
    run sudo rm -rf "$theme"
    run sudo install -d "$theme"
    run sudo install -m644 "$REPO"/system/usr/share/plymouth/themes/rice/* "$theme/"
    run sudo install -m644 "$REPO/assets/wallpapers/ryoku-dreamchaser.png" "$theme/wallpaper.png"
    run sudo update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth "$theme/rice.plymouth" 200
    run sudo update-alternatives --set default.plymouth "$theme/rice.plymouth"
    run sudo update-initramfs -u
    run sudo install -d /var/lib/rice
    ((DRY)) || echo "$new" | sudo tee "$stamp" >/dev/null
    NEED_REBOOT=1
  fi
}

# ── 3. user files ─────────────────────────────────────────────────────────────
user_files() {
  say "dotfiles (symlinked into \$HOME, backups in ~/.rice-backup)"
  local f rel
  while IFS= read -r -d '' f; do
    rel="${f#"$REPO/home/"}"
    case "$rel" in
      .local/share/fonts/*|.config/systemd/user/*|.config/gtk-4.0/rice-adwaita.css) continue ;;  # copied / merged, not linked
    esac
    backup_and_link "$f" "$HOME/$rel"
  done < <(find "$REPO/home" -type f -print0)

  # fonts + systemd unit: real copies (fontconfig and systemd dislike symlinks into a git checkout)
  run mkdir -p "$HOME/.local/share/fonts/SpaceGroteskFixed" "$HOME/.config/systemd/user"
  run cp -u "$REPO"/home/.local/share/fonts/SpaceGroteskFixed/*.ttf "$HOME/.local/share/fonts/SpaceGroteskFixed/"
  run install -m644 "$REPO/home/.config/systemd/user/xremap.service" "$HOME/.config/systemd/user/xremap.service"
  run fc-cache -f "$HOME/.local/share/fonts"

  # Ubuntu names these differently
  [[ -x /usr/bin/fdfind ]]  && [[ ! -e "$HOME/.local/bin/fd"  ]] && run ln -s /usr/bin/fdfind  "$HOME/.local/bin/fd"
  [[ -x /usr/bin/batcat ]]  && [[ ! -e "$HOME/.local/bin/bat" ]] && run ln -s /usr/bin/batcat  "$HOME/.local/bin/bat"

  # ~/.zshrc: one managed line at the end, the rest of the file stays yours
  local zline='[[ -r ~/.config/zsh/rice.zsh ]] && source ~/.config/zsh/rice.zsh   # rice'
  touch "$HOME/.zshrc"
  if ! grep -qF '.config/zsh/rice.zsh' "$HOME/.zshrc"; then
    run mkdir -p "$BACKUP"; run cp "$HOME/.zshrc" "$BACKUP/zshrc"
    ((DRY)) && echo "+ append rice line to ~/.zshrc" || printf '\n%s\n' "$zline" >> "$HOME/.zshrc"
  fi
  [[ "$(basename "${SHELL:-}")" == zsh ]] || echo "Note: your login shell is not zsh. Use: chsh -s \$(command -v zsh)"

  # handbook: ~/Documents/cli-tools.md -> repo
  local docs; docs="$(xdg-user-dir DOCUMENTS 2>/dev/null || echo "$HOME/Documents")"
  run mkdir -p "$docs"; backup_and_link "$REPO/docs/cli-tools.md" "$docs/cli-tools.md"

  say "binaries not in apt (termscp, yazi, xremap, SpaceMono Nerd Font)"
  if ((DRY)); then echo "+ scripts/fetch-binaries.sh"; else "$REPO/scripts/fetch-binaries.sh"; fi

  say "xremap service (Alt+C/V/X as copy/paste/cut)"
  run systemctl --user daemon-reload
  run systemctl --user enable xremap.service
  if [[ " $(id -nG) " == *" input "* && -w /dev/uinput ]]; then
    run systemctl --user restart xremap.service
  else
    echo "xremap will start at your next login (needs the 'input' group)."
    NEED_RELOGIN=1
  fi
}

NEED_RELOGIN=0; NEED_REBOOT=0
if ((DO_ROOT)); then
  ((DRY)) || sudo -v
  root_packages
fi
((DO_USER)) && user_files
((DO_ROOT)) && root_system
if ((DO_SETTINGS)); then
  say "desktop settings (KDE, GTK, dconf)"
  "$REPO/scripts/apply-settings.sh"
fi

say "done"
((NEED_RELOGIN)) && echo "• Log out and back in (new 'input' group, fonts, shortcuts)."
((NEED_REBOOT))  && echo "• Reboot to see the new boot splash and login screen."
echo "• Optional: let your Claude Code status line feed 'ai-usage' — see README."
((DRY)) && echo "(dry run: nothing was changed)"
exit 0

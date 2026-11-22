#!/usr/bin/env bash
# Desktop settings that live in KDE / GTK / dconf rather than in plain dotfiles.
# Idempotent. Run it inside the graphical session (install.sh does).
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DRY="${RICE_DRY:-0}"
FONT="Space Grotesk Fixed"
WALL="$HOME/Pictures/Wallpapers/ryoku-dreamchaser.png"

have() { command -v "$1" >/dev/null 2>&1; }
font_installed() { local l; l="$(fc-list : family 2>/dev/null)"; [[ "$l" == *"$FONT"* ]]; }
run()  { if [[ "$DRY" == 1 ]]; then echo "+ $*"; else "$@"; fi; }
kw()   { have kwriteconfig6 && run kwriteconfig6 "$@"; }
gs()   { have gsettings && { run gsettings set "$@" 2>/dev/null || true; }; }

echo "== wallpaper =="
mkdir -p "$HOME/Pictures/Wallpapers"
[[ -f "$WALL" ]] || run cp "$REPO/assets/wallpapers/ryoku-dreamchaser.png" "$WALL"
have plasma-apply-wallpaperimage && run plasma-apply-wallpaperimage "$WALL" >/dev/null 2>&1 || true
kw --file kscreenlockerrc --group Greeter --key WallpaperPlugin org.kde.image
kw --file kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General --key Image "file://$WALL"

echo "== default terminal + file manager =="
kw --file kdeglobals --group General --key TerminalApplication ghostty
kw --file kdeglobals --group General --key TerminalService com.mitchellh.ghostty.desktop
have xdg-mime && run xdg-mime default org.gnome.Nautilus.desktop inode/directory 2>/dev/null || true
gs org.gnome.desktop.default-applications.terminal exec 'ghostty'
gs org.gnome.desktop.default-applications.terminal exec-arg '-e'

echo "== shortcuts (Ctrl+Alt+T terminal, Meta+E files) =="
kw --file kglobalshortcutsrc --group services --group com.mitchellh.ghostty.desktop --key _launch "Ctrl+Alt+T"
kw --file kglobalshortcutsrc --group services --group org.gnome.Nautilus.desktop --key _launch "Meta+E"
kw --file kglobalshortcutsrc --group services --group org.kde.dolphin.desktop --key _launch none
kw --file kglobalshortcutsrc --group services --group kitty.desktop --key _launch none

echo "== fonts: UI font with corrected metrics, no hinting =="
if font_installed; then
  f() { echo "$FONT,$1,-1,5,${2:-400},0,0,0,0,0,0,0,0,0,0,1"; }
  kw --file kdeglobals --group General --key font "$(f 10)"
  kw --file kdeglobals --group General --key menuFont "$(f 10)"
  kw --file kdeglobals --group General --key toolBarFont "$(f 10)"
  kw --file kdeglobals --group General --key smallestReadableFont "$(f 8)"
  kw --file kdeglobals --group WM --key activeFont "$(f 10 500)"
  gs org.gnome.desktop.interface font-name "$FONT 10"
else
  echo "  ($FONT not installed yet, skipping font selection)"
fi
kw --file kdeglobals --group General --key XftHintStyle hintnone
kw --file kdeglobals --group General --key XftAntialias true
kw --file kdeglobals --group General --key XftSubPixel none
gs org.gnome.desktop.interface font-hinting 'none'
# GTK4 applies slight hinting even when hinting is "none" and then clips glyph tops at fractional scales.
gs org.gnome.desktop.interface font-rendering 'manual'
gs org.gnome.desktop.interface color-scheme 'prefer-dark'

echo "== login: no splash, no session restore =="
kw --file ksplashrc --group KSplash --key Engine none
kw --file ksplashrc --group KSplash --key Theme None
kw --file ksmserverrc --group General --key loginMode emptySession

echo "== touchpad: natural scrolling, slower; mice stay classic =="
if have busctl; then
  for dev in $(busctl --user tree org.kde.KWin 2>/dev/null | grep -o '/org/kde/KWin/InputDevice/event[0-9]*'); do
    P=(busctl --user get-property org.kde.KWin "$dev" org.kde.KWin.InputDevice)
    [[ "$("${P[@]}" touchpad 2>/dev/null)" == "b true" ]] || continue
    name="$("${P[@]}" name | sed 's/^s "//; s/"$//')"
    vendor="$("${P[@]}" vendor | awk '{print $2}')"; product="$("${P[@]}" product | awk '{print $2}')"
    echo "  $name ($vendor:$product)"
    kw --file kcminputrc --group Libinput --group "$vendor" --group "$product" --group "$name" --key NaturalScroll true
    kw --file kcminputrc --group Libinput --group "$vendor" --group "$product" --group "$name" --key ScrollFactor 0.7
    run busctl --user set-property org.kde.KWin "$dev" org.kde.KWin.InputDevice naturalScroll b true
    run busctl --user set-property org.kde.KWin "$dev" org.kde.KWin.InputDevice scrollFactor d 0.7
  done
fi

echo "== GTK settings + libadwaita palette =="
set_ini() { # file key value
  [[ "$DRY" == 1 ]] && { echo "+ $1: $2=$3"; return; }
  python3 -I - "$1" "$2" "$3" <<'PY'
import os, re, sys
p, k, v = sys.argv[1:]
os.makedirs(os.path.dirname(p), exist_ok=True)
txt = open(p).read() if os.path.exists(p) else ""
if "[Settings]" not in txt:
    txt = "[Settings]\n" + txt
pat = re.compile(r"^" + re.escape(k) + r"=.*$", re.M)
txt = pat.sub(f"{k}={v}", txt) if pat.search(txt) else txt.replace("[Settings]\n", f"[Settings]\n{k}={v}\n", 1)
open(p, "w").write(txt)
PY
}
for v in 3.0 4.0; do
  ini="$HOME/.config/gtk-$v/settings.ini"
  font_installed && set_ini "$ini" gtk-font-name "$FONT, 10"
  set_ini "$ini" gtk-hint-font-metrics 0
  set_ini "$ini" gtk-xft-hintstyle hintnone
  set_ini "$ini" gtk-xft-antialias 1
  set_ini "$ini" gtk-application-prefer-dark-theme true
done
css="$HOME/.config/gtk-4.0/gtk.css"
if [[ "$DRY" != 1 ]] && ! grep -qs "rice: Ryoku Dark palette" "$css"; then
  mkdir -p "$(dirname "$css")"; { echo; cat "$REPO/home/.config/gtk-4.0/rice-adwaita.css"; } >> "$css"
fi

echo "== Nautilus =="
gs org.gnome.nautilus.preferences default-folder-viewer 'list-view'
gs org.gnome.nautilus.preferences show-hidden-files false
gs org.gtk.Settings.FileChooser sort-directories-first true

echo "== autostart clean-up (GNOME leftovers pulled in with Nautilus) =="
mkdir -p "$HOME/.config/autostart"
for n in localsearch-3 org.gnome.Evolution-alarm-notify geoclue-demo-agent spice-vdagent orca-autostart; do
  src="/etc/xdg/autostart/$n.desktop"; dst="$HOME/.config/autostart/$n.desktop"
  if [[ -f "$src" && ! -f "$dst" ]]; then
    [[ "$DRY" == 1 ]] && echo "+ hide $n" || { cp "$src" "$dst"; sed -i '/^Hidden=/d' "$dst"; echo "Hidden=true" >> "$dst"; }
  fi
done
have systemctl && run systemctl --user disable spice-vdagent.service >/dev/null 2>&1 || true

echo "== window icons: desktop files for apps whose Wayland app-id differs from their .desktop name =="
alias_desktop() { # app-id source-desktop-file
  local dst="$HOME/.local/share/applications/$1.desktop" src
  [[ -f "/usr/share/applications/$1.desktop" || -f "$dst" ]] && return
  for src in "$HOME/.local/share/applications/$2" "/usr/share/applications/$2"; do
    if [[ -f "$src" ]]; then
      [[ "$DRY" == 1 ]] && { echo "+ $1.desktop <- $src"; return; }
      mkdir -p "$(dirname "$dst")"; cp "$src" "$dst"; sed -i '/^NoDisplay=/d' "$dst"
      sed -i '/^\[Desktop Entry\]/a NoDisplay=true' "$dst"; return
    fi
  done
}
alias_desktop zen zen-browser.desktop
alias_desktop code com.microsoft.VSCode.desktop

echo "== Plasma panel: AI Usage widget, launchers =="
if have qdbus6 && qdbus6 org.kde.plasmashell /PlasmaShell >/dev/null 2>&1; then
  run qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
    var p = panels()[0]; var has = false;
    p.widgetIds.forEach(function (id) { if (p.widgetById(id).type == "org.local.aiusage") has = true; });
    if (!has) p.addWidget("org.local.aiusage");
    panels().forEach(function (pn) { pn.widgetIds.forEach(function (id) {
      var w = pn.widgetById(id);
      if (w.type == "org.kde.plasma.icontasks") {
        w.currentConfigGroup = ["General"];
        var l = w.readConfig("launchers", "");
        l = l.replace("applications:kitty.desktop", "applications:com.mitchellh.ghostty.desktop")
             .replace("applications:org.kde.dolphin.desktop", "applications:org.gnome.Nautilus.desktop");
        w.writeConfig("launchers", l); w.reloadConfig();
      } }); });' >/dev/null 2>&1 || true
else
  echo "  (plasmashell not reachable, skipped; re-run install.sh from inside the Plasma session)"
fi

have kbuildsycoca6 && run kbuildsycoca6 >/dev/null 2>&1 || true
have systemctl && run systemctl --user restart plasma-kglobalaccel.service >/dev/null 2>&1 || true
echo "settings: done"

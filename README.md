# rice

My Kubuntu 26.04 desktop. Plasma 6 on Wayland, Ghostty, Nautilus, a zsh and tmux command line setup, macOS style Alt+C/V/X shortcuts, an AI usage tracker in the panel, a custom boot splash and login screen, and a few font rendering fixes. Colours come from Ryoku Dark: rose on dark.

I built this for one machine, mine. It lives in a private repo so I can reinstall it quickly, not because it is ready for anyone else.

## This is a personal setup

Read this before you run `install.sh`.

- It assumes my hardware, my Kubuntu version (26.04) and the accounts I already have. A clean install will not match any of that.
- The installer calls sudo and writes outside your home directory: udev rules, a systemd drop-in, a Plymouth theme, SDDM config, and fonts in `/usr/local/share/fonts`.
- `ai-usage` reads credentials that already exist on this machine (Claude, Codex, OpenCode Go) and sends them only to their own providers. The provider endpoints it calls are undocumented and can change without warning.
- I have not run any of this on a second machine. Expect something to break, and read `install.sh` before you run it.

If a few files here are useful, copy those. There is no support, and no promise that this still works after the next Kubuntu or Plasma release.

## Install

```sh
git clone <this repo> ~/Coding/rice
cd ~/Coding/rice
./install.sh --dry-run   # print every action, change nothing
./install.sh             # apply them, asks for sudo once
```

Run the installer from inside the Plasma session. The settings step talks to KWin and plasmashell. You can re-run it at any time. It is idempotent. Before it overwrites a file, it moves the old one to `~/.rice-backup/<timestamp>/`.

| Option | What it does |
|---|---|
| `--dry-run` | print every action, change nothing |
| `--no-root` | user level only: dotfiles, binaries, desktop settings |
| `--root-only` | only the sudo part |
| `--no-settings` | skip the KDE, GTK and dconf settings |

## What you get

| Area | Details |
|---|---|
| Terminal | Ghostty, with the kitty config ported over: palette, SpaceMono Nerd Font, 92 % opacity and blur. `Alt+C` copies only when text is selected and `Alt+V` pastes. Ghostty is the default terminal and opens with `Ctrl+Alt+T`. |
| Alt+C, Alt+V, Alt+X | xremap (KDE build) maps them to Ctrl+C, Ctrl+V, Ctrl+X in every app except the terminal. It runs as a user service from `home/.config/xremap/config.yml`. It needs the `input` group, so log in again after the first install. |
| Scrolling | Touchpads scroll naturally and slower (factor 0.7). Mice keep their settings. |
| Files | Nautilus is the default file manager and opens with Meta+E. Rose libadwaita palette, plus the right-click entries "Open in Ghostty" and "Copy path". It is installed with `--no-install-recommends` so GNOME Shell and GDM do not come along. |
| CLI | tmux, fzf, fd, bat, eza, zoxide, ripgrep, btop, lazygit, neovim, delta, tealdeer, ncdu, duf, hyperfine, gping, procs, httpie, starship, and the pinned binaries termscp and yazi. The handbook `docs/cli-tools.md` is copied to `~/Documents/cli-tools.md`. |
| AI usage | The `ai-usage` command, a Plasma panel widget that shows plan limits and a pulsing dot while an agent works, and a tmux status segment. |
| Boot and login | Plymouth theme "rice" (wallpaper and dot spinner, kept on screen until SDDM starts), the same wallpaper on SDDM and the lock screen, Plasma splash off, no session restore at login. |
| Rendering fixes | Space Grotesk Fixed with corrected line metrics, hinting off, GTK4 `font-rendering=manual` (fixes clipped glyph tops at 125 % scale), and icons for apps whose Wayland app id has no matching `.desktop` file (Zen, VS Code). |

## Layout

```
install.sh                 orchestrator
LICENSE                    MIT
packages/apt.txt           apt packages (no recommends)
home/                      mirrors $HOME; most files are symlinked into place
  .config/ghostty|tmux|xremap|zsh|starship.toml|systemd/user|gtk-4.0/rice-adwaita.css
  .local/bin/ai-usage
  .local/share/plasma/plasmoids/org.local.aiusage   panel widget
  .local/share/nautilus-python/extensions            Nautilus right-click entries
  .local/share/fonts/SpaceGroteskFixed               patched UI font
system/                    mirrors /; needs sudo (udev rule for xremap, plymouth drop-in,
                           SDDM font, plymouth theme)
templates/                 rendered by install.sh (SDDM theme.conf.user)
assets/wallpapers/         wallpaper for desktop, lock screen, SDDM and boot splash
scripts/
  apply-settings.sh        KDE/GTK/dconf settings (kwriteconfig6, gsettings, plasmashell)
  fetch-binaries.sh        termscp, yazi, xremap, SpaceMono Nerd Font: pinned version, SHA-256
  patch-font.py            regenerates SpaceGroteskFixed from the system font
docs/cli-tools.md          handbook for every installed tool
```

## Editing files

Dotfiles are symlinks into this repo, so edit them here and commit. Some files are not symlinked. The fonts and the systemd unit are copied. The Plasma plasmoid is copied because KPackage requires every file to sit inside the package root. The GTK4 palette is appended to `~/.config/gtk-4.0/gtk.css` once. Run `install.sh` again after you change one of those. To reapply the palette after an edit, remove the rice block from `gtk.css` first.

Settings that live in KDE or dconf are set by `scripts/apply-settings.sh`. Change them there so a reinstall keeps them.

## AI usage tracker

```sh
ai-usage            # coloured overview (also: alias `ai`)
ai-usage active     # threads running right now, with minutes
ai-usage short      # one line for tmux: ▶Cl 4m │  Cl 23%·36%  Cx 12%·64% ...
ai-usage json       # used by the widget
```

Sources: the Claude Code status-line hook (fallback: the OAuth usage endpoint), Codex rollout logs, `agy -p "/usage"`, and the OpenCode Go per-key usage endpoint (keys read from CLIProxyAPI's `~/.cli-proxy-api/opencode-go-key-*.json`). Tokens go only to their own provider and are never copied or printed. If you do not use a tool, its section shows "No data".

Claude Code needs one line of setup, because this repo does not edit your Claude settings. Add this to `~/.claude/settings.json`:

```json
{ "statusLine": { "type": "command", "command": "ai-usage statusline" } }
```

If you already have a status-line command, let it feed the tracker first:

`input=$(cat); echo "$input" | ai-usage statusline >/dev/null; ...your command, using $input...`

## Assumptions and caveats

- Targets Kubuntu 26.04 on x86_64. The installer warns on other systems, and the pinned binaries are x86_64 only.
- The Bibata cursor theme, Papirus-Dark icons and the base Plasma colour scheme come from an earlier base setup. They are not in this repo.
- The SHA-256 hashes in `scripts/fetch-binaries.sh` were recorded when each file was first fetched. Upgrade by changing the version and the hash together.
- I checked the `--no-install-recommends` package list on my machine, not on a pristine install. If a package misses a recommend that it needs, add the package to `packages/apt.txt`.
- Hardware specific pieces (ASUS ROG laptop tweaks, NVIDIA) are deliberately left out.
- `assets/wallpapers/ryoku-dreamchaser.png` comes from the Ryoku project (GPL-3.0).

## Undo

| What | How |
|---|---|
| Any overwritten file | copy it back from `~/.rice-backup/<timestamp>/` |
| Boot splash | `sudo update-alternatives --set default.plymouth /usr/share/plymouth/themes/kubuntu-logo/kubuntu-logo.plymouth && sudo update-initramfs -u` |
| Alt+C, Alt+V, Alt+X | `systemctl --user disable --now xremap` |
| Login screen | `sudo rm /usr/share/sddm/themes/*/theme.conf.user /etc/sddm.conf.d/30-rice.conf` |
| Boot to login handoff | `sudo rm /etc/systemd/system/plymouth-quit.service.d/retain-splash.conf` |
| Session restore | `kwriteconfig6 --file ksmserverrc --group General --key loginMode restorePreviousLogout` |
| GTK4 text fix | `gsettings reset org.gnome.desktop.interface font-rendering` |

## License

MIT, see [LICENSE](LICENSE).

Some files keep their own license: `assets/wallpapers/ryoku-dreamchaser.png` comes from the Ryoku project under GPL-3.0, and the Space Grotesk fonts in `home/.local/share/fonts` are under the SIL Open Font License.

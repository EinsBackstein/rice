# rice

Drop-in desktop configuration for **Kubuntu 26.04 (Plasma 6, Wayland)**: Ghostty, Nautilus, a tidy zsh/tmux/CLI toolbox, macOS-style Alt+C/V/X, an AI-usage tracker (Claude · Codex · Antigravity · OpenCode Go) with live "thread running for N min" indicator, boot splash, login screen, and a handful of rendering fixes. Rose-on-dark "Ryoku Dark" palette.

```sh
git clone <this repo> ~/Coding/rice && cd ~/Coding/rice
./install.sh --dry-run     # read what it would do
./install.sh               # do it (asks for sudo once)
```
Re-run it any time; it is idempotent. Files it would overwrite are moved to `~/.rice-backup/<timestamp>/` first. Run it from inside the Plasma session (the settings step talks to KWin and plasmashell).

| Option | Meaning |
|---|---|
| `--dry-run` | print everything, change nothing |
| `--no-root` | user level only: dotfiles, binaries, desktop settings |
| `--root-only` | only the sudo part |
| `--no-settings` | skip KDE/GTK/dconf settings |

## What you get

| Area | Details |
|---|---|
| Terminal | **Ghostty**, config ported from kitty (palette, SpaceMono Nerd Font, 92 % opacity + blur). `Alt+C` copies only when text is selected, `Alt+V` pastes; default terminal + `Ctrl+Alt+T`. |
| Alt+C / V / X | **xremap** (KDE build) turns them into Ctrl+C/V/X in every non-terminal app (user service, `home/.config/xremap/config.yml`). Needs the `input` group → re-login once. |
| Scrolling | Touchpad: natural + slower (factor 0.7), mice untouched. Touchpads are detected automatically. |
| Files | **Nautilus** as default (Meta+E, taskbar), rose libadwaita palette, "Open in Ghostty" / "Copy path" right-click entries. Installed with `--no-install-recommends` so GNOME Shell/GDM do not come along. |
| CLI | tmux, fzf, fd, bat, eza, zoxide, ripgrep, btop, lazygit, neovim, delta, tealdeer, ncdu, duf, hyperfine, gping, procs, httpie, starship (one-line prompt), plus **termscp** and **yazi** (pinned binaries). Handbook: [`docs/cli-tools.md`](docs/cli-tools.md) → `~/Documents/cli-tools.md`. |
| AI usage | `ai-usage` CLI, Plasma panel widget (limits + pulsing dot with minutes while an agent works), tmux status segment. See below. |
| Boot / login | Plymouth theme "rice" (wallpaper + dot spinner, splash retained until SDDM takes over), SDDM + lock screen use the same wallpaper, Plasma splash off, no app restore at login. |
| Rendering fixes | `Space Grotesk Fixed` (corrected line metrics), hinting off, GTK4 `font-rendering=manual` (stops clipped glyph tops at 125 % scale), icons for apps whose Wayland app-id has no matching `.desktop` (Zen, VS Code). |

## Layout

```
install.sh                 orchestrator
packages/apt.txt           apt packages (no recommends)
home/                      mirrors $HOME; files are symlinked into place (fonts + systemd unit are copied)
  .config/ghostty|tmux|xremap|zsh|starship.toml|systemd/user|gtk-4.0/rice-adwaita.css
  .local/bin/ai-usage
  .local/share/plasma/plasmoids/org.local.aiusage   panel widget
  .local/share/nautilus-python/extensions            Nautilus right-click entries
  .local/share/fonts/SpaceGroteskFixed               patched UI font
system/                    mirrors /; needs sudo (udev rule for xremap, plymouth drop-in, SDDM font, plymouth theme)
templates/                 rendered by install.sh (SDDM theme.conf.user)
assets/wallpapers/         the wallpaper used for desktop, lock screen, SDDM and the boot splash
scripts/
  apply-settings.sh        KDE/GTK/dconf settings (kwriteconfig6, gsettings, plasmashell scripting)
  fetch-binaries.sh        termscp, yazi, xremap, SpaceMono Nerd Font — pinned version + SHA-256
  patch-font.py            regenerates SpaceGroteskFixed from the system font
docs/cli-tools.md          handbook for every installed tool
```
Because dotfiles are symlinks, **edit the files in this repo** (or the symlinked paths, same thing) and `git commit`. Settings that live in KDE/dconf are expressed in `scripts/apply-settings.sh`; change them there so they survive a reinstall.

## AI usage tracker

```sh
ai-usage            # coloured overview (also: alias `ai`)
ai-usage active     # threads running right now, with minutes
ai-usage short      # one line for tmux: ▶Cl 4m │  Cl 23%·36%  Cx 12%·64% ...
ai-usage json       # used by the widget
```
Sources: Claude Code status-line hook (fallback: OAuth usage endpoint), Codex rollout logs, `agy -p "/usage"`, OpenCode Go per-key usage endpoint (keys read from CLIProxyAPI's `~/.cli-proxy-api/opencode-go-key-*.json`). Nothing is ever copied or printed; tokens only go to their own provider. If you do not use a tool, its section just shows "No data".

**Claude Code needs one line of setup** (this repo does not edit your Claude settings). In `~/.claude/settings.json`:
```json
{ "statusLine": { "type": "command", "command": "ai-usage statusline" } }
```
or, if you already have a status-line command, make it feed the tracker first:
`input=$(cat); echo "$input" | ai-usage statusline >/dev/null; …your command, using $input…`

## Assumptions and caveats

- Targets Kubuntu 26.04 on x86_64. The installer warns on other systems; the pinned binaries are x86_64 only.
- Cursor theme (Bibata), icon theme (Papirus-Dark) and the base Plasma colour scheme come from the earlier base setup and are not part of this repo.
- Release downloads are verified against SHA-256 hashes recorded when they were first fetched (trust on first use); upgrade by changing version and hash together in `scripts/fetch-binaries.sh`.
- The `--no-install-recommends` package set was verified on the machine it was built on, not on a pristine install. If a package turns out to miss a hard-needed recommend, add it to `packages/apt.txt`.
- Hardware-specific bits (ASUS ROG laptop tweaks, NVIDIA) are deliberately not here.
- `assets/wallpapers/ryoku-dreamchaser.png` comes from the Ryoku project (GPL-3.0).

## Undo

| What | How |
|---|---|
| Any overwritten file | copy it back from `~/.rice-backup/<timestamp>/` |
| Boot splash | `sudo update-alternatives --set default.plymouth /usr/share/plymouth/themes/kubuntu-logo/kubuntu-logo.plymouth && sudo update-initramfs -u` |
| Alt+C/V/X | `systemctl --user disable --now xremap` |
| Login screen | `sudo rm /usr/share/sddm/themes/*/theme.conf.user /etc/sddm.conf.d/30-rice.conf` |
| Smoother boot→login handoff | `sudo rm /etc/systemd/system/plymouth-quit.service.d/retain-splash.conf` |
| Session restore | `kwriteconfig6 --file ksmserverrc --group General --key loginMode restorePreviousLogout` |
| GTK4 text fix | `gsettings reset org.gnome.desktop.interface font-rendering` |

# CLI tools on this machine

Kubuntu 26.04 · zsh · Ghostty · tmux · installed 2026-11-22.
Everything below is installed and wired into `~/.zshrc` (block *"rice: CLI tools"*). Open a new terminal to pick up the aliases.

**Contents**
1. [Quick reference](#1-quick-reference)
2. [Shell setup: aliases, history, prompt](#2-shell-setup)
3. [Search and navigation](#3-search-and-navigation): ripgrep, fd, fzf, zoxide, yazi
4. [Viewing files](#4-viewing-files): bat, eza, delta
5. [Terminal multiplexer: tmux](#5-tmux)
6. [Git: lazygit, delta](#6-git)
7. [System and network](#7-system-and-network): btop, procs, duf, ncdu, gping, httpie
8. [Editors and clipboard: neovim, wl-clipboard](#8-editor-and-clipboard)
9. [Remote files: termscp](#9-termscp)
10. [Docs and benchmarks: tldr, hyperfine](#10-docs-and-benchmarks)
11. [Terminal and keyboard: Ghostty, macOS-style Alt+C/V/X](#11-terminal-and-keyboard)
12. [AI usage tracker: ai-usage](#12-ai-usage-tracker)
13. [Maintenance: update, remove, where configs live](#13-maintenance)

---

## 1. Quick reference

| You want to… | Command | Tool |
|---|---|---|
| search file *contents* | `rg "TODO" src/` | ripgrep |
| find files by *name* | `fd config` | fd |
| fuzzy-pick a file / history entry / directory | `Ctrl+T` / `Ctrl+R` / `Alt+C` | fzf |
| jump to a frequently used directory | `cd proj` (fuzzy, learns from use) | zoxide |
| browse files in the terminal | `yazi` | yazi |
| `cat` with colours and line numbers | `cat file` (alias for `bat`) | bat |
| `ls` with icons, git status, tree | `ls`, `ll`, `lt` | eza |
| split terminal / keep sessions alive | `tmux` | tmux |
| git in a TUI | `lg` | lazygit |
| watch CPU / RAM / disks / network | `top` (alias for `btop`) | btop |
| kill or inspect a process | `procs`, `procs firefox` | procs |
| free disk space overview | `duf` | duf |
| what is eating my disk | `ncdu ~` | ncdu |
| ping with a live graph | `gping 1.1.1.1` | gping |
| test an HTTP API | `http GET api.example.com/x` | httpie |
| SFTP/SCP/FTP/S3/SMB file transfer UI | `termscp` | termscp |
| short examples for any command | `tldr tar` | tealdeer |
| benchmark two commands | `hyperfine 'a' 'b'` | hyperfine |
| plan limits (Claude / Codex) | `ai-usage` or `ai` | ai-usage |

---

## 2. Shell setup

**Aliases** (defined in `~/.zshrc`)

| Alias | Expands to | Note |
|---|---|---|
| `ls` | `eza --icons --group-directories-first` | |
| `ll` | `eza -lah --icons --group-directories-first --git` | long list incl. hidden + git status |
| `lt` | `eza --tree --level=2 --icons` | two-level tree |
| `cat` | `bat --paging=never` | use `\cat file` or `/bin/cat` for the real `cat`, e.g. in pipes to other programs |
| `lg` | `lazygit` | |
| `vim` | `nvim` | `EDITOR` is also `nvim` |
| `top` | `btop` | |
| `ai` | `ai-usage` | |

Bypass any alias once by prefixing a backslash: `\ls`, `\cat`.

**Other settings**
- History: 50 000 entries, shared between sessions, commands starting with a space are not stored (`setopt hist_ignore_space`).
- `zsh-autosuggestions`: grey ghost text from history; press `→` (or `End`) to accept.
- `zsh-syntax-highlighting`: valid commands green, typos red, as you type.
- Prompt: **starship** (config `~/.config/starship.toml`), minimal single line: `~/Coding/rice main +2 ~1 ❯` (directory in rose, git branch/status, Python venv, command duration ≥ 3 s), clock on the right. No powerline glyphs. Git symbols: `+` staged, `~` modified, `?` untracked, `-` deleted, `↑↓` ahead/behind, `!` conflict.
- `man` pages are rendered through `bat`.

**fzf key bindings** (active in zsh)

| Keys | Action |
|---|---|
| `Ctrl+R` | fuzzy search command history |
| `Ctrl+T` | pick a file (inserts the path at the cursor) |
| `Alt+C` | pick a directory and `cd` into it* |
| `**<Tab>` | fuzzy completion: `vim **<Tab>`, `kill -9 <Tab>`, `ssh **<Tab>` |

\* In Ghostty `Alt+C` is also the *copy* shortcut, see [section 11](#11-terminal-and-keyboard). With text selected it copies; with nothing selected it reaches fzf. If you prefer, rebind fzf: `bindkey '^[j' fzf-cd-widget` in `~/.zshrc`.

---

## 3. Search and navigation

### ripgrep (`rg`)
Fast recursive content search. Respects `.gitignore`, skips hidden and binary files by default.

```sh
rg "pattern"                  # search current directory
rg -i "pattern"               # case-insensitive
rg -w word                    # whole word
rg -F "a.b(c)"                # literal string, no regex
rg "foo" -g '*.py'            # only Python files
rg "foo" -g '!node_modules'   # exclude
rg -t rust "unsafe"           # by file type (see: rg --type-list)
rg -l "foo"                   # only list file names
rg -c "foo"                   # count per file
rg -C 3 "foo"                 # 3 lines of context
rg --hidden "foo"             # include dotfiles
rg -uuu "foo"                 # ignore nothing (no gitignore, hidden, binary)
rg "foo" -r "bar"             # show what a replacement would look like (does not edit)
rg -n "TODO|FIXME"            # regex alternation
rg --files | rg README        # list files, then filter
```

### fd
Friendlier `find`. Installed from Ubuntu as `fdfind`; `~/.local/bin/fd` is a symlink.

```sh
fd name                 # files/dirs whose name matches "name"
fd -e md                # by extension
fd -t d src             # only directories (-t f files, -t l symlinks)
fd -H -I secret         # include hidden (-H) and gitignored (-I)
fd . /etc -e conf       # search a specific directory
fd -e log -x rm {}      # run a command per match (careful!)
fd -e jpg -X ls -lh     # one command with all matches
fd --changed-within 1d  # modified in the last day
```
fzf uses `fd` as its file source, so `Ctrl+T` also shows dotfiles but skips `.git`.

### fzf
Fuzzy finder for anything that is a list.

```sh
history | fzf                         # pick from any pipe
vim $(fzf)                            # open the selected file
fzf --preview 'bat --color=always {}' # live preview pane
rg -l foo | fzf --multi               # Tab selects several, Enter confirms
git branch | fzf | xargs git checkout # pick a branch
```
Inside the picker: `↑/↓` or `Ctrl+J/K` move, `Tab` multi-select, `Enter` accept, `Esc` cancel. Search syntax: `foo bar` (both), `'exact`, `^start`, `end$`, `!not`, `a | b`.
Colours follow the Ryoku palette (`FZF_DEFAULT_OPTS`).

### zoxide
Smarter `cd`. `cd` itself is replaced (`zoxide init zsh --cmd cd`), and it learns directories you visit.

```sh
cd ~/Coding/rice     # normal cd still works and gets remembered
cd rice              # jumps to the best match for "rice"
cd co ri             # several keywords, all must match in order
cdi                  # interactive pick with fzf
cd -                 # previous directory
zoxide query -ls     # show the database with scores
zoxide remove /path  # forget a directory
```
Needs a few visits before it knows a directory. `_ZO_DOCTOR=0` silences its init warning; the init line has to stay at the very end of `~/.zshrc`.

### yazi
Terminal file manager (installed to `~/.local/bin`, with its helper `ya`).

```sh
yazi                 # start in the current directory
```
Keys (vim-like): `h` parent · `l`/`Enter` open · `j/k` move · `Space` select · `y` copy (yank) · `x` cut · `p` paste · `d` trash · `D` delete permanently · `a` create (end name with `/` for a directory) · `r` rename · `.` toggle hidden · `/` search · `f` filter · `z` jump via fzf · `~` help · `q` quit. Config lives in `~/.config/yazi/` (created on first edit).

---

## 4. Viewing files

### bat
`cat` with syntax highlighting, line numbers and git markers. Ubuntu names the binary `batcat`; `~/.local/bin/bat` is a symlink. Theme is `ansi` (follows the terminal palette).

```sh
bat file.py                  # (the `cat` alias runs: bat --paging=never)
bat -n file                  # numbers only (-p plain, -A show whitespace)
bat -r 20:40 file            # only lines 20 to 40
bat -l json                  # force language when reading stdin
bat --list-themes
curl -s api/x | bat -l json
```
`man` uses bat as pager. Use `\cat` when you need the unmodified `cat` (e.g. `\cat file | something`).

### eza
`ls` replacement.

```sh
ls                     # icons, directories first
ll                     # long, hidden, git status column
lt                     # tree, 2 levels
eza -T --level=4 src   # deeper tree
eza -l --sort=size -r  # biggest first
eza -l --sort=modified # oldest first (add -r for newest first)
eza -lD                # only directories
eza --git-ignore -T    # tree without gitignored files
```
Icons need a Nerd Font, which Ghostty is set up with (SpaceMono Nerd Font).

### delta
Syntax-highlighting pager for `git diff`/`git log -p`. It is installed but **not yet enabled** in git. To turn it on:

```sh
git config --global core.pager delta
git config --global interactive.diffFilter 'delta --color-only'
git config --global delta.navigate true      # n / N jump between files
git config --global delta.line-numbers true
git config --global merge.conflictStyle zdiff3
```
Side-by-side: `git config --global delta.side-by-side true`. lazygit also uses `delta` once `core.pager` is set (see below).

---

## 5. tmux

Version 3.6. Config: `~/.config/tmux/tmux.conf`. The **prefix is the default `Ctrl+B`**.

```sh
tmux                      # new session
tmux new -s work          # named session
tmux ls                   # list
tmux attach -t work       # (or: tmux a -t work)
tmux kill-session -t work
```

**Keys** (press the prefix, release, then the key)

| Keys | Action |
|---|---|
| `Ctrl+B` `\|` | split side by side (keeps current directory) |
| `Ctrl+B` `-` | split top/bottom (keeps current directory) |
| `Ctrl+B` `c` | new window (keeps current directory) |
| `Ctrl+B` `1…9` | go to window N (numbering starts at 1) |
| `Ctrl+B` `n` / `p` | next / previous window |
| `Ctrl+B` `,` | rename window |
| `Ctrl+B` `←↑↓→` | move between panes (mouse click works too) |
| `Ctrl+B` `z` | zoom the current pane (toggle) |
| `Ctrl+B` `x` | close the pane |
| `Ctrl+B` `d` | detach (session keeps running) |
| `Ctrl+B` `s` | session picker |
| `Ctrl+B` `[` | copy mode (vi keys) |
| `Ctrl+B` `r` | reload the config |
| `Ctrl+B` `?` | list all key bindings |

**Copy mode:** `Ctrl+B [`, move with `h j k l` / `/` to search, `v` starts selection, `y` copies to the Wayland clipboard (via `wl-copy`) and leaves copy mode. Mouse selection also works; `set-clipboard on` lets tmux copy through the terminal (OSC 52).

**Other settings:** mouse on, 50 000 lines of scrollback, true colour, 10 ms escape delay (no lag in neovim), windows renumber when one closes, status bar in Ryoku colours.
The right side of the status bar shows `ai-usage short` (Claude/Codex limits) and the time, refreshed every 30 s.

---

## 6. Git

### lazygit (`lg`)
Full-screen git UI: stage hunks, commit, rebase, resolve conflicts, browse the log.

| Key | Action |
|---|---|
| `1`–`5` | switch panel (Status, Files, Branches, Commits, Stash) |
| `Space` | stage / unstage file (in the diff view: a line or hunk) |
| `a` | stage all |
| `c` | commit · `C` commit in editor |
| `P` / `p` | push / pull |
| `n` | new branch · `Space` checkout (Branches panel) |
| `M` | merge into current · `r` rebase onto |
| `d` | discard changes (asks first) |
| `e` | edit file · `o` open |
| `s` | stash · `g` pop stash (Files panel) |
| `i` | interactive rebase actions (Commits panel: `s` squash, `f` fixup, `r` reword, `d` drop) |
| `z` | undo (reflog based) · `Ctrl+R` redo |
| `/` | filter · `?` full key list · `q` quit |

Config: `~/.config/lazygit/config.yml`. To show diffs through delta, add:
```yaml
git:
  paging:
    colorArg: always
    pager: delta --dark --paging=never
```

---

## 7. System and network

### btop (`top`)
Resource monitor (CPU per core, memory, disks, network, processes). Version 1.4.6.
Keys: `m` cycle presets · `1/2/3/4` toggle CPU/mem/net/proc boxes · `f` filter processes · `t` tree view · `k` kill · `+/-` reorder · `Esc` menu / options · `q` quit. Config `~/.config/btop/btop.conf`; themes in the options menu.

### procs
Modern `ps`: coloured, with ports, Docker and tree support.
```sh
procs                  # all processes
procs firefox          # filter by name, user, pid or command
procs --tree           # process tree
procs --watch          # live refresh
procs --sortd cpu      # sort descending by CPU
```

### duf
Mounted filesystems as a readable table: `duf`, `duf /home`, `duf --only local`, `duf --json`.

### ncdu
Interactive disk-usage browser (version 1.22).
```sh
ncdu ~                 # scan home
ncdu -x /              # stay on one filesystem
```
Keys: `↑↓` move · `→/Enter` open · `←` back · `d` delete (asks) · `n/s` sort by name/size · `g` toggle percentage/graph · `r` rescan · `q` quit.

### gping
Ping with a live graph: `gping 1.1.1.1`, `gping google.com cloudflare.com` (compare several hosts in one graph), `gping --cmd 'curl -s -o /dev/null https://example.com'` (graph how long any command takes). `q` quits.

### httpie (`http`, `https`)
Human-friendly HTTP client.
```sh
http api.example.com/users                       # GET
http POST api.example.com/users name=Ada age:=30 # JSON body (:= = raw JSON/number)
http -a user:pass GET api/secure                 # basic auth
http GET api/x Authorization:"Bearer $TOKEN"     # headers use Name:value
http -f POST api/form field=value                # form-encoded
http --download example.com/file.zip
http -v GET api/x                                # show request and response
http api/x | jq .                                # pipe JSON to jq (installed)
```

---

## 8. Editor and clipboard

### neovim (`nvim`, also `vim`)
Version 0.11.6, **default configuration** (no plugins yet). Config goes to `~/.config/nvim/init.lua`.
Survival kit: `i` insert · `Esc` normal · `:w` save · `:q` quit · `:wq` save+quit · `:q!` discard · `/text` search · `u` undo · `Ctrl+R` redo · `dd` delete line · `yy` copy line · `p` paste · `gg`/`G` top/bottom · `:help` docs · `:Tutor` interactive tutorial.
For an IDE-like setup, install [LazyVim](https://www.lazyvim.org) (`git clone https://github.com/LazyVim/starter ~/.config/nvim`, then start `nvim`).

### wl-clipboard (`wl-copy`, `wl-paste`) and xclip
Clipboard from the command line (Wayland; `xclip` covers X11 apps).
```sh
echo hello | wl-copy         # to clipboard
wl-paste                     # print clipboard
wl-paste > clip.txt
wl-copy < image.png          # (also works for images)
pwd | wl-copy                # copy current path
wl-copy --primary            # the middle-click selection instead
```
tmux copy mode uses `wl-copy`.

---

## 9. termscp

Terminal UI for SFTP / SCP / FTP(S) / S3 / SMB / WebDAV-style transfers. Version 1.2.2, installed as a static binary in `~/.local/bin/termscp`.

```sh
termscp                                          # opens the connection form
termscp sftp://user@host                         # connect directly
termscp sftp://user@host:2222:/var/www           # with port and start directory
termscp scp://user@host                          # SCP
termscp ftp://user@host                          # FTP
termscp smb://user@server/share                  # SMB
termscp s3://bucket@eu-central-1:default:/       # AWS S3 with profile
termscp -b mybookmark                            # saved bookmark
termscp user@a.example  user@b.example           # two remotes: copy between them
termscp -P 'pass' sftp://user@host               # password on the CLI (visible in shell history!)
termscp --help
```
Keys in the file browser: `Tab` switch between local/remote panel · `Enter` enter directory · `Space` select · `C` copy · `R` rename · `G` go to path · `D` make directory · `Del`/`E` delete · `V`/`O` open · `S` save/download · `U` go up · `F` find · `A` toggle hidden · `Ctrl+C` abort transfer · `?` help · `Q` quit.
Saved bookmarks and recent hosts live in `~/.config/termscp/`; passwords are stored in the system keyring (use `--wno-keyring` to disable).
For plain `sftp`, `ssh` and `scp`, the normal OpenSSH tools are still available.

---

## 10. Docs and benchmarks

### tldr (tealdeer)
Community cheat sheets with real examples.
```sh
tldr --update          # download the pages once (needs internet; run this first)
tldr tar               # examples for tar
tldr git commit        # sub-commands: use a dash or a space
tldr --list | fzf      # browse all pages
```

### hyperfine
Statistical command-line benchmarking.
```sh
hyperfine 'fd -e py' 'find . -name "*.py"'
hyperfine --warmup 3 --runs 20 'make'
hyperfine --export-markdown bench.md 'cmd a' 'cmd b'
hyperfine -L n 1,2,4 'cmd --jobs {n}'     # parameter scan
```

---

## 11. Terminal and keyboard

### Ghostty
Default terminal (`Ctrl+Alt+T`). Config: `~/.config/ghostty/config`; validate with `ghostty +validate-config`; reload with `Ctrl+Shift+,`. Full option list: `ghostty +show-config --default --docs`.
Defaults to remember: `Ctrl+Shift+T` new tab · `Ctrl+Shift+N` new window · `Ctrl+Shift+W` close · `Ctrl+Shift+O` split right · `Ctrl+Shift+E` split down · `Ctrl+Alt+arrows` move between splits · `Ctrl+Shift+C/V` copy/paste · `Ctrl+Shift+F` search.
Selecting text copies it to the clipboard automatically (`copy-on-select = clipboard`).

### macOS-style clipboard: Alt+C / Alt+V / Alt+X
| App type | Alt+C | Alt+V | Alt+X |
|---|---|---|---|
| normal apps (browser, editor, Nautilus…) | copy | paste | cut |
| Ghostty | copy (only if text is selected; otherwise the key passes through) | paste | – |

- **Outside terminals** this is done by [xremap](https://github.com/xremap/xremap) (`~/.local/bin/xremap`, built with KDE support). It rewrites `Alt+C/V/X` to `Ctrl+C/V/X` per window. Config: `~/.config/xremap/config.yml`; the list of excluded terminals is the regex under `application: not:`.
- **In Ghostty** the two keybinds are in its own config, so `Ctrl+C` stays *interrupt* and `Alt+C` still reaches readline/fzf if nothing is selected.
- Service: `systemctl --user status xremap` · `restart` after config edits (`--watch=config` also reloads automatically) · `disable --now xremap` to switch the feature off. It starts at login; it needs the user to be in the `input` group (done; takes effect after a re-login) and the udev rule `/etc/udev/rules.d/99-uinput.rules`.
- Want more macOS keys? Add lines like `Alt-a: C-a`, `Alt-z: C-z`, `Alt-s: C-s`, `Alt-f: C-f`, `Alt-w: C-w`, `Alt-t: C-t` under `remap:`.

### Natural scrolling (touchpad only)
KDE keeps this per device: the touchpad scrolls like macOS, mice keep normal direction (`~/.config/kcminputrc`, also System Settings → Mouse & Touchpad). Touchpad scroll speed is `ScrollFactor=0.7`; edit the value there (1.0 = default) and re-login, or change it live with
`busctl --user set-property org.kde.KWin /org/kde/KWin/InputDevice/<eventN> org.kde.KWin.InputDevice scrollFactor d 0.6` (the device number changes; list with `busctl --user tree org.kde.KWin`).

---

## 12. AI usage tracker

`ai-usage` (alias `ai`) shows your plan limits (5-hour, weekly, monthly windows) for all AI tools in one place. Script: `~/.local/bin/ai-usage` (plain Python, standard library only).

```sh
ai-usage            # coloured overview
ai-usage active     # agent threads running right now and for how long
ai-usage short      # one line, used in the tmux status bar:  ▶Cl 4m │  Cl 23%·36%  Cx 12%·64%  Ag 0%·0%  Oc1 0%·7%  Oc2 0%·37%
ai-usage json       # machine-readable, used by the Plasma panel widget
```
(`short` starts with `▶Cl 4m │` while a thread is running (Claude, Codex or OpenCode, with minutes), then 5-hour · weekly usage. `Cl` Claude, `Cx` Codex, `Ag` Antigravity Claude/GPT pool, `Oc1`/`Oc2` your two OpenCode Go keys.)

- **Live activity:** a thread counts as *active* while Claude Code reports `busy` (`~/.claude/sessions/*.json`), Codex has an unfinished `task_started` in its rollout log (and a `codex` process exists), or the OpenCode service lists it under `/api/session/active`. The panel widget shows a pulsing dot and the minutes (`● 4m`, `+N` for more threads), the popup lists each thread with project and name, tmux shows `▶Cl 4m`. Not supported: Antigravity (no activity signal).
- **Plasma widget** "AI Usage": in the panel, click it for the detail view (scrollable; bars, reset countdown). Refreshes every 60 s. Source: `~/.local/share/plasma/plasmoids/org.local.aiusage`. After editing the QML run `systemctl --user restart plasma-plasmashell`.
- **Claude:** Claude Code passes its limits to its *status line command*; the tracker records them via `ai-usage statusline` (your status-line command must call it, see below). Fallback: Anthropic's OAuth usage endpoint, at most every 10 minutes (backs off on HTTP 429).
- **Codex:** read locally from the newest rate-limit snapshot in `~/.codex/sessions/`. Only as current as your last Codex turn (age is shown).
- **Antigravity:** runs `agy -p "/usage"` (the CLI's own quota table: Claude/GPT pool, Gemini pools, weekly and 5-hour) at most every 5 minutes. Needs `agy` to be signed in. Pools other than Claude/GPT are shown in the widget only; the Gemini pools currently report 0 % remaining (100 % used).
- **OpenCode Go:** calls `https://opencode.ai/zen/go/v1/usage` once per API key (the keys CLIProxyAPI stores in `~/.cli-proxy-api/opencode-go-key-*.json`, so both of your accounts), at most every 5 minutes. Rolling 5-hour, weekly, monthly percentage used.
- Cache and state: `~/.cache/ai-usage/`. No credentials are ever printed or copied; keys/tokens are only sent to their own provider.

> **Claude status-line hook:** if `~/.claude/settings.json` has a custom `statusLine`, make it also feed the tracker by starting the command with
> `input=$(cat); echo "$input" | ai-usage statusline >/dev/null; …your existing command using $input…`

---

## 13. Maintenance

**Update** (apt packages): `sudo apt update && sudo apt upgrade`.
**Manually installed binaries** (not updated by apt):
- `xremap`, `termscp`, `yazi` and the Nerd Font are pinned (version + SHA-256) in the repo's `scripts/fetch-binaries.sh`: change the version and hash there, delete the old binary from `~/.local/bin`, run `./install.sh --no-root`.

**Remove a tool:** `sudo apt remove <package>`; for the manual ones delete the file in `~/.local/bin/`.

**Names that differ from the package:** `fd` → `fdfind`, `bat` → `batcat` (symlinks in `~/.local/bin`), `tldr` → package `tealdeer`, `http` → package `httpie`, `lg` → alias for `lazygit`.

**Where things live**
| What | File |
|---|---|
| shell aliases, fzf, zoxide, plugins | `~/.zshrc` |
| prompt | `~/.config/starship.toml` |
| terminal | `~/.config/ghostty/config` |
| tmux | `~/.config/tmux/tmux.conf` |
| Alt+C/V/X | `~/.config/xremap/config.yml` |
| the whole setup (single source of truth), installer, rollback | `~/Coding/rice` (see its `README.md`); most files above are symlinks into `~/Coding/rice/home/` |

**Installed via apt:** ghostty, tmux, fzf, bat, eza, btop, lazygit, neovim, wl-clipboard, xclip, git-delta, tealdeer, ncdu, duf, hyperfine, gping, procs, httpie, zsh-autosuggestions, zsh-syntax-highlighting (plus already present: ripgrep, fd-find, zoxide, jq, fastfetch, starship).

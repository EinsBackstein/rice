# rice — shell setup. Sourced from the end of ~/.zshrc (install.sh adds the line).
# Safe to source on any zsh; every tool is optional.

path=("$HOME/.local/bin" $path)
typeset -U path

# completion system (the fzf completion below needs it)
(( $+functions[compdef] )) || { autoload -Uz compinit && compinit -C; }

HISTSIZE=50000
SAVEHIST=50000
setopt hist_ignore_space inc_append_history share_history

command -v starship >/dev/null && eval "$(starship init zsh)"

[[ -r /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
command -v fzf >/dev/null && source <(fzf --zsh)

export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS='--height=40% --layout=reverse --border=rounded --color=bg+:#352328,fg+:#f1dcd6,hl:#e0707a,hl+:#ff8a94,pointer:#e0707a,prompt:#e0707a,info:#b99ea0,border:#6b5558'
export BAT_THEME=ansi
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export EDITOR=nvim

alias ls='eza --icons --group-directories-first'
alias ll='eza -lah --icons --group-directories-first --git'
alias lt='eza --tree --level=2 --icons'
alias cat='bat --paging=never'
alias lg=lazygit
alias vim=nvim
alias top=btop
alias ai='ai-usage'

# syntax highlighting must be sourced last, zoxide must be initialised last
[[ -r /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
export _ZO_DOCTOR=0
command -v zoxide >/dev/null && eval "$(zoxide init zsh --cmd cd)"

# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git)

source $ZSH/oh-my-zsh.sh

# Environment

export TERMINAL="alacritty"
export FILEMANAGER="thunar"
export BROWSER=firefox

if command -v prime-run &> /dev/null; then
    alias firefox="prime-run firefox"
fi

# Colored system aliases
alias ll="ls -lah --color=auto"
alias la="ls -A --color=auto"
alias l="ls -CF --color=auto"
alias ls="ls --color=auto"
alias grep="grep --color=auto"
alias diff="diff --color=auto"
alias ip="ip -color"

# SSH terminal compatibility alias
alias ssh="TERM=xterm-256color ssh"

# Log colorizer (no dependencies)
clog() {
    sed -E '
    s/\b(INFO)\b/\x1b[32m\1\x1b[0m/g;
    s/\b(WARN|WARNING)\b/\x1b[33m\1\x1b[0m/g;
    s/\b(ERROR|FATAL|FAIL)\b/\x1b[31m\1\x1b[0m/g;
    s/(\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\])/\x1b[36m\1\x1b[0m/g;
    s/([a-zA-Z0-9_]+=)([0-9a-zA-Z_:-]+)/\1\x1b[35m\2\x1b[0m/g
    ' "$@"
}

fastfetch

[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

#
# ~/.bashrc
#


# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls -la --color=auto'
alias grep='grep --color=auto'
alias fz='tmux-sessionizer'
alias hyprland='start-hyprland'
alias projects='cd ~/pombo/projects/'

PS1='[\u@\h \W]\$ '


export PATH="$HOME/.local/bin:$PATH"

# Editor for git commit, sudoedit, crontab -e... (no vi/nano installed)
export EDITOR=nvim
export VISUAL=nvim

# History: big, without duplicates, saved after every command and shared between open terminals.
# A command typed with a leading space isn't saved (handy for anything secret).
HISTSIZE=50000
HISTFILESIZE=100000
HISTCONTROL=ignoreboth:erasedups
shopt -s histappend
PROMPT_COMMAND+=('history -a; history -n')

# fzf in the shell: Ctrl+R searches the history, Ctrl+T inserts files, Alt+C jumps into a folder,
# and `**` + Tab fuzzy-completes paths (nvim **<Tab>, cd **<Tab>). Tab completion for commands
# (git, pacman, systemctl...) comes from bash-completion, loaded by /etc/bash.bashrc.
# Files are listed with fd: hidden ones included, .gitignore respected, .git and caches skipped.
if command -v fzf >/dev/null; then
    fd_skip='--hidden --exclude .git --exclude .cache --exclude node_modules'
    export FZF_DEFAULT_COMMAND="fd --type f $fd_skip"
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND="fd --type d $fd_skip"
    export FZF_CTRL_T_OPTS="--preview 'file --mime {} | grep -q binary && echo \"(binary file)\" || head -n 200 {}'"
    export FZF_ALT_C_OPTS="--preview 'ls -la --color=always {}'"
    # shellcheck disable=SC2086  # $fd_skip holds several options on purpose
    _fzf_compgen_path() { fd $fd_skip . "$1"; }
    # shellcheck disable=SC2086
    _fzf_compgen_dir() { fd --type d $fd_skip . "$1"; }
    eval "$(fzf --bash)"
fi

# mise (Node and other runtimes)
if command -v mise >/dev/null; then
    eval "$(mise activate bash)"
fi

# conda from Miniforge; base is not auto-activated (see ~/.condarc)
if [ -f "$HOME/miniforge3/etc/profile.d/conda.sh" ]; then
    . "$HOME/miniforge3/etc/profile.d/conda.sh"
fi

# Machine-local additions, kept out of this repo
if [ -f "$HOME/.bashrc.local" ]; then
    . "$HOME/.bashrc.local"
fi

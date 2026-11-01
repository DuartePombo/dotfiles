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

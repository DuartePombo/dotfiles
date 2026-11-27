# Start-up file for the terminal Neovim opens (<leader>tt, <leader>rr; lua/custom/run.lua): your normal ~/.bashrc,
# then the Python environment Neovim uses (picked with <leader>vs, else the project's .venv) is activated for real,
# like VS Code does in its terminals: `python`, `pip`, `pytest` are the env's and the prompt shows (env).
# It has to happen here, after ~/.bashrc: a new shell's mise activation resets PATH to the copy saved when your first
# shell started, which drops whatever Neovim put in front of PATH.
# shellcheck shell=bash
# shellcheck disable=SC1091  # your own ~/.bashrc
[ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"

if [ -n "${NVIM_PYTHON_ENV:-}" ]; then
    if [ -d "$NVIM_PYTHON_ENV/conda-meta" ] && declare -F conda >/dev/null; then
        conda activate "$NVIM_PYTHON_ENV"
    elif [ -f "$NVIM_PYTHON_ENV/bin/activate" ]; then
        # shellcheck disable=SC1091  # the venv's own script
        . "$NVIM_PYTHON_ENV/bin/activate"
    fi
fi
unset NVIM_PYTHON_ENV

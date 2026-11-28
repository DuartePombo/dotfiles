# Neovim cheat sheet

`Space` is the leader key. Press it and wait: which-key lists everything under it. `<leader>sk` searches all keys.

The full tutorial, with exercises and mnemonics, is a local folder: `~/pombo/projects/nvim-tutorial` (not in this repo).
`<leader>?` opens it, `<leader>s?` searches it.

## What works per language

| Language | Language server (completion, errors, go to definition) | Format (`<leader>f`) | Run (`<leader>rr`) | Debug (`F5`) |
|---|---|---|---|---|
| Python | basedpyright (types) + Ruff (lint, imports) | Ruff | selected env | debugpy |
| C, C++ | clangd (with clang-tidy) | clang-format | gcc/g++ `-g` | codelldb |
| JavaScript, TypeScript, React | vtsls + ESLint (if the project has a config) | Prettier (the project's own, with its plugins) | node | js-debug (Node, Chrome) |
| HTML, CSS, SCSS | html, cssls, emmet | Prettier | HTML: opens in the browser | |
| C# (.NET) | Roslyn (Microsoft's, as in VS Code); opens the nearest .sln | Roslyn, by the project's .editorconfig | `dotnet run` in a terminal | netcoredbg |
| JSON, YAML | jsonls, yamlls (with schemas: package.json, compose...) | Prettier | | |
| Shell | bashls + shellcheck | shfmt | bash | |
| Markdown, Dockerfile, Compose, TOML | marksman, dockerls, compose, taplo | Prettier / taplo | | |
| Lua | lua_ls | stylua | `nvim -l` | |
| Java | jdtls (`<leader>c...`) | | `java File.java` | |

Format on save is off: format with `<leader>f`. TypeScript runs directly with Node (no build step).
Inlay hints (`<leader>th`) show types, return types and parameter names in Python, TypeScript/JavaScript and C#
(the servers have them off by default; VS Code is set to the same choices).
C#: needs the .NET SDKs from packages/pacman.txt (the current one, also for Roslyn, and 8). They build .NET 6
projects too; Arch dropped .NET 6 itself, so run such an app on .NET 8 with `DOTNET_ROLL_FORWARD=Major dotnet run`.
`F5` in a .cs file attaches to a running process (start the app yourself with `dotnet run`); the second entry
launches a built .dll. A project outside the .sln (e.g. a test project) gets fewer features.
Web apps: Chrome debugging asks for the dev server's address (remembered) and maps sources from the app's own
folder (nearest package.json), so it works in repos with several apps. Vite's dev server already reloads the page.
C/C++: language standard is gnu23 / gnu++23 everywhere (clangd, run, debug). For a project with several files, use
its build (make/CMake: `-DCMAKE_EXPORT_COMPILE_COMMANDS=ON` so clangd follows it) and "debug an executable".

## Python environment (like VS Code's "Select Interpreter")
| Keys | Action |
|---|---|
| `<leader>vs` | pick the environment: Miniforge conda envs, conda base, the project's `.venv` (uv) |
| `<leader>vi` | show the active interpreter |
| `<leader>vd` | deactivate (back to the system python) |

The statusline shows the active env in Python files. The choice applies to the language server, `<leader>rr`, the
debugger, Jupyter kernels and terminals opened from Neovim, and it's remembered per project. With nothing picked:
an env active in the shell you started Neovim from, then `./.venv`, then the system `python3`.

## Run and terminal
| Keys | Action |
|---|---|
| `<leader>rr` | run the current file (in the terminal at the bottom) |
| `<leader>ra` | run with arguments |
| `<leader>rl` | run the last command again |
| `<leader>tt` | show/hide the terminal (`Esc Esc` leaves terminal mode) |

## Debugging
| Keys | Action |
|---|---|
| `F5` / `<leader>dd` | debug the current file; continue when stopped |
| `F9` / `<leader>db` | toggle breakpoint |
| `<leader>dB` | conditional breakpoint (`i > 3`) |
| `<leader>dl` | log point: prints a message (`x is {x}`) instead of stopping |
| `F10` / `<leader>dn` | step over (next line) |
| `F11` / `<leader>di` | step into |
| `Shift+F11` / `<leader>do` | step out |
| `<leader>dC` | run to the cursor |
| `<leader>dk` / `<leader>dj` | move up / down the call stack |
| `<leader>de` | evaluate the expression under the cursor (or the selection) |
| `<leader>dw` | add the expression under the cursor to the watches |
| `<leader>dr` | REPL: run code in the paused program |
| `<leader>dE` | stop on exceptions (pick: raised / uncaught...) |
| `<leader>dp` | pause |
| `Shift+F5` / `<leader>dx` | stop |
| `Ctrl+Shift+F5` / `<leader>dR` | restart |
| `<leader>dc` | pick a configuration: with arguments, attach to a process, Chrome, a project's `.vscode/launch.json` |
| `<leader>dL` | run the last configuration again |
| `<leader>dt` / `<leader>dT` | Python: debug the test method / class under the cursor (pytest or unittest) |
| `<leader>dX` | clear all breakpoints |
| `F7` / `<leader>du` | show/hide the debugger panels |

The panels open by themselves: variables, watches, call stack, breakpoints, and the program's terminal (type input
there). Values also show next to the code. The panels stay open after the program ends; `<leader>du` closes them.
C/C++: `F5` compiles first; compile errors land in the quickfix list. Python needs no debugpy in your env.
Chrome: start the dev server (`npm run dev`), then `<leader>dc` → "Chrome: open a URL".

## Jupyter notebooks
`nvim notebook.ipynb` opens it as Python with `# %%` lines between cells (`# %% [markdown]` for text cells), so
completion, errors and formatting work (the debugger needs a real .py file: plain `.py` files with `# %%` cells
work with both F5 and the `<leader>j` keys). `:w` saves the `.ipynb`, including the outputs of the
cells you ran. `nvim new.ipynb` creates a new notebook. The same cells work in plain `.py` files.

| Keys | Action |
|---|---|
| `<leader>ji` | start a kernel for the env picked with `<leader>vs` (the run keys do this too) |
| `<leader>jr` | run the cell (in visual mode: the selection) |
| `<leader>jn` | run the cell and go to the next one (adds a cell at the end) |
| `<leader>ja` / `<leader>jA` | run all cells / all cells down to this one |
| `<leader>jl` | run the line |
| `]j` / `[j` | next / previous cell |
| `<leader>jb` / `<leader>jm` | new code / markdown cell below |
| `<leader>jo` | open the output in a window (press again to enter it and scroll) |
| `<leader>jh` | hide the output window |
| `<leader>jd` | delete the cell's output |
| `<leader>jx` | interrupt the running code |
| `<leader>jR` | restart the kernel (clears all variables) |
| `<leader>jq` | stop the kernel |
| `<leader>jk` | pick any Jupyter kernel from a list |
| `<leader>je` | write the outputs into the `.ipynb` now (`:w` does it too) |

Outputs show under each cell; plots show as images in kitty (also inside tmux). The env needs `ipykernel`
(the `jupyter` env has it; otherwise `conda install -n <env> ipykernel`, or `uv add --dev ipykernel` in a uv
project). Each env is registered as a Jupyter kernel on first use, so JupyterLab lists it too.
IPython magics (`%timeit`, `!pip install`) run normally.

## Editing and code navigation
| Keys | Action |
|---|---|
| `K` | documentation of the symbol under the cursor |
| `gd` (or `grd`) / `grD` | go to definition / declaration |
| `grr` | references |
| `gri` / `grt` | implementations / type definition |
| `grn` | rename everywhere |
| `gra` | code actions (quick fixes, organize imports...) |
| `gO` / `gW` | symbols in the file / in the project |
| `[d` / `]d` | previous / next error or warning |
| `<C-w>d` | show the error under the cursor |
| `<leader>q` | all errors in a list |
| `<leader>th` | inlay hints (types and parameter names inline) |
| `v` then `an` `an`... / `in` | grow / shrink the selection by syntax node |
| `gc` / `gcc` | comment selection / line |
| `sa` / `sd` / `sr` | add / delete / replace surrounding quotes or brackets (`saiw"`, `sd(`, `sr"'`) |
| `<C-h/j/k/l>` | move between windows |
| `\` | file tree |

## Search (Telescope)
`<leader>sf` files, `<leader>sg` grep, `<leader>sw` word under the cursor, `<leader><leader>` open buffers,
`<leader>/` in this file, `<leader>s.` recent files, `<leader>sd` diagnostics, `<leader>sh` help,
`<leader>sk` keys, `<leader>sr` resume the last search.

## Git and AI
Like VS Code's Source Control:

| Keys | Action |
|---|---|
| `<leader>gg` | Source Control screen (Neogit): `s` stage, `u` unstage, `x` discard, `Tab` inline diff, `c c` commit, `P` push, `p` pull, `b` branches, `l` log, `Z` stash, `?` help, `q` close |
| `<leader>gd` | all changes side by side, changed files as a tree on the left, staged / unstaged (Diffview; `-` stage, `X` discard, `q` close) |
| `<leader>gc` then `c` | commit the staged changes (message buffer: `:wq` commits, `q` cancels; `a` amends, `w` rewords) |
| `<leader>gl` / `<leader>gh` | commit graph / history of this file |
| `<leader>gb` | switch branch |
| `]c` / `[c` | next / previous change (margin: `+` added, `~` changed, `_` deleted) |
| `<leader>hp` / `<leader>hs` / `<leader>hr` | preview / stage / reset the change (hunk); `hS` / `hR` the whole file |
| `<leader>hb` / `<leader>tb` | blame the line / show blame on every line you're on |
| `<leader>hd` / `<leader>hD` | diff the file against the staged version / the last commit |
| `<leader>ac` | Claude Code in a new kitty window, in the project folder. Back to Neovim: `Alt+H`/`Alt+L` (or `Alt+Shift+S` to park it in the scratchpad, `Alt+S` to show/hide). Review its edits with `<leader>gd` |

## Markdown
Rendered in place (`<leader>tm` switches to raw). Enter (or `gd`) on a link opens it, `Ctrl+o` comes back;
Enter on a `- [ ]` task ticks it. Link targets can be `file.md#heading`, `code.lua#text` (first line with that
text) or `code.lua#L12`.
Notes with screenshots: `Super+Shift+S` copies a screenshot, `p` (or `<leader>pi`) pastes it (img-clip: saved as a
PNG in `./assets` next to the note, link inserted); images show inline in kitty (image.nvim's Markdown integration).
`p` with only an image on the clipboard: in Markdown it pastes the image, elsewhere it says so and pastes nothing
(`lua/custom/paste.lua`; Neovim's clipboard asks for text only, so a screenshot never becomes raw PNG bytes).
Deleting the link leaves the PNG in `assets/`.
Work notes (`lua/custom/notes.lua`; folder = first line of `~/.work-notes.local`, else `~/notes/work`): `daily/` (one
note per day) and `projects/<project>/` (README.md overview + one `YYYY-MM-DD-title.md` per note). `<leader>nd` today's
note (template: Catch-up, Notes, To-do; meetings go in project notes, or in an "Other" project), `<leader>nn` new note
(title asked; outside a project: picker, a new name creates the project), `<leader>nl` a project's notes newest first,
`<leader>np` a project's overview (its `## Notes` section is rebuilt from the folder, newest first, on every new note
and every opening), `<leader>nt` all open to-dos, `<leader>nf` / `<leader>ns` find / search notes. The work-notes window opens on today's
note (`app-launch work-notes`).

## Maintenance
- `:Lazy` plugins (`:Lazy update`, then commit `lazy-lock.json`), `:Mason` language tools,
  `:MasonToolsInstallSync` installs the configured ones, `:checkhealth` for problems.
- Notebook support runs in the conda env `nvim` (`packages/conda/nvim.yml`). After updating molten, or if the
  `<leader>j` keys say it isn't registered: `:UpdateRemotePlugins` and restart Neovim.
- Running tmux sessions pick up the image setting after `tmux source ~/.config/tmux/tmux.conf`.

## Inside VS Code (VSCode Neovim)
VS Code's `asvetliakov.vscode-neovim` extension runs this same config as its editor, in a "VS Code mode"
(`vim.g.vscode` is set). The editing is real Neovim; VS Code does the IDE part.
- Only plugins marked `vscode = true` load (mini.nvim: mini.ai, mini.surround): lazy.nvim's `defaults.cond` in
  `init.lua`. The Jupyter plugins, the custom paste and run helpers stay off too.
- `lua/custom/vscode.lua` gives the Space keys the same meaning with VS Code's commands: `Space s f` Quick Open,
  `Space s g` the Search view, `gra` quick fixes, `Space g g` Source Control, `Space d ...` VS Code's debugger,
  `Space j ...` notebook cells (or the Interactive Window for `# %%` cells in a `.py` file), `Space a c` Claude.
  Keys without a VS Code counterpart say "only in Neovim" instead of falling through to Vim.
- No which-key there, so `timeout` is off (a slow `Space s g` never turns into Vim commands); the keys typed so far
  show in VS Code's status bar, and so does the mode (`-- INSERT --`...), through a one-item status line rather than
  `showmode` (the extension can miss the clear after Esc); yank/put use VS Code's clipboard.
- Markdown: `Enter` / `gd` on a link open it with VS Code's Open Link, `Enter` on `- [ ]` ticks it (the link and
  task detection come from `lua/custom/markdown_links.lua`).
- VS Code side, in each profile's settings (local, not in this repo): `vscode-neovim.neovimExecutablePaths.linux`
  `/usr/bin/nvim`, `editor.lineNumbers` relative, `editor.cursorSurroundingLines` 10 (scrolloff), `search.smartCase`,
  `extensions.experimental.affinity` for the extension (its own extension host). keybindings.json: `Ctrl+l` from a
  side bar list back to the code, `\` / `q` close the explorer (as in neo-tree), `Ctrl+k` from a panel list.
- After changing this config: Command Palette → **Neovim: Restart Extension**. Logs: **Neovim: View Extension Logs**.
- Every key, side by side with Neovim's: the tutorial's `reference/vscode.md`.

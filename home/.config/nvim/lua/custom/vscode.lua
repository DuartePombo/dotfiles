-- VS Code mode: this Neovim config running inside VS Code, through the vscode-neovim extension.
--
-- VS Code shows the text and does the IDE work (language servers, completion, search, git, debugging, terminal);
-- Neovim does the editing, so motions, text objects, operators, macros, registers, `.` and `:s` are real Neovim.
-- This file gives the Space keys of the Neovim setup the same meaning there, calling VS Code's own commands
-- instead of Telescope / LSP / Neogit / DAP. Loaded at the end of init.lua when vim.g.vscode is set; only plugins
-- marked `vscode = true` load then (mini.ai text objects, mini.surround).
--
-- Already done by the extension itself (no mapping here):
--   gd / K / gh / gf / gD / gH / gO        definition, hover, declaration, peek, references, symbols
--   grn grr gri grt                         Neovim's own LSP keys: vim.lsp.buf.* runs the VS Code command
--   an / in (visual)                        Neovim's own syntax-node selection (tree-sitter), shown as VS Code's
--   gc gcc, = == gq                         VS Code's comment and format, so they know every language
--   z folds, <C-w> windows (= editor groups), :w :q :e :split :tabnext, <C-o>/<C-i> jumps (VS Code's history)
--   file explorer: j k h l, Enter, a/A new file/folder, r rename, d delete, y/x/p copy/cut/paste
-- VS Code settings that mirror init.lua's options (relative numbers, scrolloff, smartcase) live in its settings.json.

local vscode = require 'vscode'

-- No which-key here, so wait for the rest of a key sequence as long as it takes (which-key waits too), instead of
-- running a slowly typed Space s g as Vim commands after 300 ms (Space = one letter right, s = delete a letter)
vim.o.timeout = false

-- VS Code's status bar shows what Neovim reports: the mode (-- INSERT --, -- VISUAL --) and half-typed keys
-- (Space s ...), but not Neovim's own status line (file, line, column: VS Code shows those itself)
vim.o.showmode = true
vim.o.laststatus = 0

local function map(modes, lhs, rhs, desc) vim.keymap.set(modes, lhs, rhs, { desc = desc, silent = true }) end

-- A mapping that runs a VS Code command (args: the command's argument, if it takes one)
local function act(cmd, args)
  return function() vscode.action(cmd, args and { args = args } or nil) end
end

-- Same, but falls back to another command if the first one isn't available
local function act_or(cmd, fallback)
  return function()
    vscode.action(cmd, { callback = function(err) if err then vscode.action(fallback) end end })
  end
end

-- Ask VS Code something (JavaScript, see the extension's README); nil if it fails or takes over a second
local function ask(js)
  local ok, res = pcall(vscode.eval, js, {}, 1000)
  return ok and res or nil
end
local function debugging() return ask 'return vscode.debug.activeDebugSession !== undefined' == true end
local function in_notebook()
  return ask "return vscode.window.activeTextEditor?.document.uri.scheme === 'vscode-notebook-cell'" == true
end

-- Keys of the Neovim setup that have no sensible VS Code counterpart: say so, instead of letting the keys fall
-- through to Vim (an unmapped <leader>sh would run `s`: delete a character and start typing)
local function neovim_only(lhs, what)
  map('n', lhs, function() vscode.notify(what .. ': only in Neovim') end, what .. ' (Neovim only)')
end

-- Moving around ---------------------------------------------------------------------------------------------------
-- Ctrl+h/j/k/l: like Neovim's windows, but across all of VS Code: file explorer, editor groups, panel (terminal).
-- Back from the file explorer: Ctrl+l, or \ / q to close it as in neo-tree; from a list in the panel (Problems):
-- Ctrl+k (those are in VS Code's keybindings.json). In the terminal, Ctrl+h/j/k/l stay the shell's keys (in
-- Neovim you'd leave terminal mode first): Ctrl+1 goes back to the code, Ctrl+` hides the terminal.
map('n', '<C-h>', act 'workbench.action.navigateLeft', 'Focus left (explorer, editor group)')
map('n', '<C-j>', act 'workbench.action.navigateDown', 'Focus down (panel: terminal, problems)')
map('n', '<C-k>', act 'workbench.action.navigateUp', 'Focus up')
map('n', '<C-l>', act 'workbench.action.navigateRight', 'Focus right')
map('n', '\\', act 'workbench.files.action.showActiveFileInExplorer', 'File tree: show this file (\\ or q there closes it)')

-- [S]earch (Telescope in Neovim) -------------------------------------------------------------------------------
map('n', '<leader>sf', act 'workbench.action.quickOpen', '[S]earch [F]iles')
map('n', '<leader>sg', act 'workbench.action.findInFiles', '[S]earch by [G]rep (whole project)')
map('n', '<leader>sw', function()
  vscode.action('workbench.action.findInFiles', { args = { query = vim.fn.expand '<cword>' } })
end, '[S]earch current [W]ord')
map('x', '<leader>sw', act 'workbench.action.findInFiles', '[S]earch the selection')
map('n', '<leader>s/', act('workbench.action.findInFiles', { onlyOpenEditors = true }), '[S]earch [/] in open files')
map('n', '<leader>sd', act 'workbench.actions.view.problems', '[S]earch [D]iagnostics')
map('n', '<leader>sr', act 'workbench.view.search', '[S]earch [R]esume: the last search')
map('n', '<leader>s.', act 'workbench.action.openRecent', '[S]earch recent files and folders')
map('n', '<leader>sk', act 'workbench.action.openGlobalKeybindings', '[S]earch [K]eymaps')
map('n', '<leader>ss', act 'workbench.action.showCommands', '[S]earch [S]elect: every command')
map('n', '<leader><leader>', act 'workbench.action.showAllEditorsByMostRecentlyUsed', '[ ] Open files (buffers)')
map('n', '<leader>/', act 'actions.find', '[/] Search in this file')
map('n', '<leader>q', act 'workbench.actions.view.problems', 'Diagnostics list (Problems)')
neovim_only('<leader>sh', 'Search help')
neovim_only('<leader>sn', 'Search the Neovim config')
neovim_only('<leader>s?', 'Search the tutorial') -- <leader>? (open it) works: :edit opens files in VS Code

-- Code (the LSP in Neovim) ----------------------------------------------------------------------------------------
map({ 'n', 'x' }, 'gra', act 'editor.action.quickFix', '[G]oto Code [A]ction: quick fixes (Ruff fixes too)')
map('n', 'grd', act 'editor.action.revealDefinition', '[G]oto [D]efinition')
map('n', 'grD', act 'editor.action.revealDeclaration', '[G]oto [D]eclaration')
map('n', 'gW', act 'workbench.action.showAllSymbols', 'Open Workspace Symbols')
map('n', ']d', act 'editor.action.marker.next', 'Next diagnostic')
map('n', '[d', act 'editor.action.marker.prev', 'Previous diagnostic')
map('n', '<leader>f', act 'editor.action.formatDocument', '[F]ormat buffer')
map('x', '<leader>f', act 'editor.action.formatSelection', '[F]ormat selection')
map('n', '<leader>th', function()
  local on = vscode.get_config 'editor.inlayHints.enabled' == 'on'
  vscode.update_config('editor.inlayHints.enabled', on and 'offUnlessPressed' or 'on', 'global')
end, '[T]oggle inlay [H]ints (VS Code remembers it)')

-- [G]it (Neogit / Diffview / gitsigns in Neovim) ------------------------------------------------------------------
map('n', '<leader>gg', act 'workbench.view.scm', '[G]it: Source Control')
map('n', '<leader>gc', act 'git.commit', '[G]it [C]ommit')
map('n', '<leader>gl', act_or('workbench.scm.history.focus', 'workbench.view.scm'), '[G]it [L]og: commit graph')
map('n', '<leader>gb', act 'git.checkout', '[G]it [B]ranches: switch')
map('n', '<leader>gd', act 'git.viewChanges', '[G]it [D]iff: all changes side by side')
map('n', '<leader>gh', act 'timeline.focus', '[G]it [H]istory of this file (Timeline)')
map('n', ']c', act 'workbench.action.editor.nextChange', 'Jump to next git [c]hange')
map('n', '[c', act 'workbench.action.editor.previousChange', 'Jump to previous git [c]hange')
map({ 'n', 'x' }, '<leader>hs', act 'git.stageSelectedRanges', 'git [s]tage hunk / selection')
map({ 'n', 'x' }, '<leader>hr', act 'git.revertSelectedRanges', 'git [r]eset hunk / selection')
map({ 'n', 'x' }, '<leader>hu', act 'git.unstageSelectedRanges', 'git [u]ndo stage hunk')
map('n', '<leader>hS', act 'git.stage', 'git [S]tage buffer')
map('n', '<leader>hR', act 'git.clean', 'git [R]eset buffer (VS Code asks first)')
map('n', '<leader>hp', act 'editor.action.dirtydiff.next', 'git [p]review hunk')
map('n', '<leader>hb', act 'git.blame.toggleEditorDecoration', 'git [b]lame (toggle)')
map('n', '<leader>hd', act 'git.openChange', 'git [d]iff this file')
map('n', '<leader>hD', act 'git.openChange', 'git [D]iff this file')
map('n', '<leader>tb', act 'git.blame.toggleEditorDecoration', '[T]oggle git [b]lame')
neovim_only('<leader>tD', 'Toggle deleted lines')

-- Terminal and [R]un (lua/custom/run.lua in Neovim) ------------------------------------------------------------
map('n', '<leader>tt', act 'workbench.action.terminal.toggleTerminal', '[T]oggle [T]erminal')
map('n', '<leader>rr', function()
  vscode.action(vim.bo.filetype == 'python' and 'python.execInTerminal' or 'workbench.action.debug.run')
end, '[R]un current file')
map('n', '<leader>rl', act 'workbench.action.terminal.runRecentCommand', '[R]un [L]ast command (pick, Enter)')
neovim_only('<leader>ra', 'Run with arguments')

-- [D]ebug (nvim-dap in Neovim; F5 / F9 / F10 / F11 are VS Code's own and the same in both) -------------------------
map('n', '<leader>dd', function()
  vscode.action(debugging() and 'workbench.action.debug.continue' or 'workbench.action.debug.start')
end, '[D]ebug current file / continue')
map('n', '<leader>dc', function()
  vscode.action(debugging() and 'workbench.action.debug.continue' or 'workbench.action.debug.selectandstart')
end, '[C]ontinue / pick a configuration')
map('n', '<leader>dL', act 'workbench.action.debug.start', 'Run [L]ast configuration again')
map('n', '<leader>dC', act 'editor.debug.action.runToCursor', 'Run to [C]ursor')
map('n', '<leader>db', act 'editor.debug.action.toggleBreakpoint', 'Toggle [B]reakpoint')
map('n', '<leader>dB', act 'editor.debug.action.conditionalBreakpoint', 'Conditional [B]reakpoint')
map('n', '<leader>dl', act 'editor.debug.action.addLogPoint', '[L]og point')
map('n', '<leader>dX', act 'workbench.debug.viewlet.action.removeAllBreakpoints', 'Clear all breakpoints')
map('n', '<leader>dE', act 'workbench.debug.action.focusBreakpointsView', '[E]xception breakpoints (Breakpoints view)')
map('n', '<leader>dn', act 'workbench.action.debug.stepOver', 'Step over ([N]ext line)')
map('n', '<leader>di', act 'workbench.action.debug.stepInto', 'Step [I]nto')
map('n', '<leader>do', act 'workbench.action.debug.stepOut', 'Step [O]ut')
map('n', '<leader>dk', act 'workbench.action.debug.callStackUp', 'Call stack up (caller)')
map('n', '<leader>dj', act 'workbench.action.debug.callStackDown', 'Call stack down')
map('n', '<leader>dp', act 'workbench.action.debug.pause', '[P]ause')
map('n', '<leader>dx', act 'workbench.action.debug.stop', 'Stop (terminate)')
map('n', '<leader>dR', act 'workbench.action.debug.restart', '[R]estart')
map('n', '<leader>du', act 'workbench.view.debug', 'Toggle debugger [U]I (Run and Debug view)')
map('n', '<leader>dr', act 'workbench.debug.action.toggleRepl', 'Toggle [R]EPL (Debug Console)')
map('n', '<leader>de', act 'editor.debug.action.showDebugHover', '[E]valuate expression under the cursor')
map({ 'n', 'x' }, '<leader>dw', act 'editor.debug.action.selectionToWatch', '[W]atch expression')
map('n', '<leader>dt', act 'testing.debugAtCursor', 'Debug [T]est at the cursor')
map('n', '<leader>dT', act 'testing.debugCurrentFile', 'Debug [T]ests in this file')

-- [V]env: the Python interpreter (venv-selector in Neovim; VS Code shows it in the status bar) ----------------------
map('n', '<leader>vs', act 'python.setInterpreter', '[V]env [S]elect (Python interpreter)')
neovim_only('<leader>vi', 'Venv info (VS Code shows the interpreter in the status bar)')
neovim_only('<leader>vd', 'Venv deactivate')

-- [J]upyter: in a real notebook (.ipynb) the notebook's commands; in a .py file with # %% cells the Interactive
-- Window (Jupyter extension). Molten's output-window keys (jo jh jq je) have no counterpart: outputs show inline.
local function nb(notebook_cmd, py_cmd)
  return function() vscode.action(in_notebook() and notebook_cmd or py_cmd) end
end
-- A new # %% cell after the current one, as add_cell() in lua/custom/plugins/jupyter.lua does it
local function add_py_cell(markdown)
  local marker = '# %%' .. (markdown and ' [markdown]' or '')
  local body = markdown and '# ' or ''
  local next = vim.fn.search('^# %%', 'nW') -- the next cell's marker (0: none); the cursor doesn't move
  local at, lines, row
  if next > 0 then
    at, lines = next - 1, { marker, body, '' } -- before the next cell, keeping one blank line between cells
    row = at + 2
  else
    at = vim.fn.line '$'
    lines = vim.fn.getline(at):match '^%s*$' and { marker, body } or { '', marker, body }
    row = at + #lines
  end
  vim.api.nvim_buf_set_lines(0, at, at, false, lines)
  vim.api.nvim_win_set_cursor(0, { row, #body })
end
map('n', '<leader>ji', nb('notebook.selectKernel', 'python.setInterpreter'), '[I]nit kernel (selected Python env)')
map('n', '<leader>jk', nb('notebook.selectKernel', 'python.setInterpreter'), 'Pick a [K]ernel')
map('n', '<leader>jr', nb('notebook.cell.execute', 'jupyter.runcurrentcell'), '[R]un cell')
map('x', '<leader>jr', act 'jupyter.execSelectionInteractive', '[R]un selection')
map('n', '<leader>jn', nb('notebook.cell.executeAndSelectBelow', 'jupyter.runcurrentcelladvance'), 'Run cell, go to [N]ext')
map('n', '<leader>ja', nb('notebook.execute', 'jupyter.runallcells'), 'Run [A]ll cells')
-- (action, not call: call would block Neovim until the cells have finished; VS Code queues them in this order)
map('n', '<leader>jA', function()
  if in_notebook() then
    vscode.action 'notebook.cell.executeCellsAbove'
    vscode.action 'notebook.cell.execute'
  else
    vscode.action 'jupyter.runallcellsabove'
    vscode.action 'jupyter.runcurrentcell'
  end
end, 'Run [A]ll cells above, and this one')
map('n', '<leader>jl', act 'jupyter.execSelectionInteractive', 'Run [L]ine')
map('n', '<leader>jd', act 'notebook.cell.clearOutputs', '[D]elete cell output')
map('n', '<leader>jx', nb('notebook.cancelExecution', 'jupyter.interruptkernel'), 'Interrupt (stop running code)')
map('n', '<leader>jR', act 'jupyter.restartkernel', '[R]estart kernel (clears variables)')
map('n', '<leader>jb', function()
  if in_notebook() then vscode.action 'notebook.cell.insertCodeCellBelow' else add_py_cell(false) end
end, 'New code cell [B]elow')
map('n', '<leader>jm', function()
  if in_notebook() then vscode.action 'notebook.cell.insertMarkdownCellBelow' else add_py_cell(true) end
end, 'New [M]arkdown cell below')
map({ 'n', 'x' }, ']j', function()
  if in_notebook() then vscode.action 'notebook.focusNextEditor' else vim.fn.search('^# %%', 'W') end
end, 'Next notebook cell')
map({ 'n', 'x' }, '[j', function()
  if in_notebook() then vscode.action 'notebook.focusPreviousEditor' else vim.fn.search('^# %%', 'bW') end
end, 'Previous notebook cell')
for _, k in ipairs { 'jo', 'jh', 'jq', 'je' } do neovim_only('<leader>' .. k, 'Molten output window / export') end

-- [A]I, [T]oggles, the rest -------------------------------------------------------------------------------------
map('n', '<leader>ac', act 'claude-vscode.editor.openLast', '[A]I: [C]laude Code (the panel)')
-- (its own key for this, Alt+K, is Hyprland's focus-up key, so it never reaches VS Code)
map('x', '<leader>ac', act 'claude-vscode.insertAtMention', '[A]I: the selection into [C]laude (@file#lines)')
map('n', '<leader>tm', act 'markdown.showPreviewToSide', '[T]oggle [M]arkdown preview (beside)')
neovim_only('<leader>pi', 'Paste image') -- in VS Code, Ctrl+V pastes an image into Markdown by itself
for _, k in ipairs { 'co', 'crv', 'crc', 'crm' } do neovim_only('<leader>' .. k, 'Java refactoring (jdtls)') end

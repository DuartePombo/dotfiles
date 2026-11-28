-- Work notes: one note per day, one note per project, and keys to reach them from anywhere (<leader>n = [N]otes).
--   <leader>nd  today's daily note (created from a template: Catch-up, Meetings, Notes, To-do)
--   <leader>np  project picker: Enter opens a project note; a name that matches nothing creates it
--   <leader>nl  log entry: today's date heading in the project's Log section, ready to type
--   <leader>nt  every open to-do (- [ ] ...) in all notes; <leader>nf find a note, <leader>ns search all notes
-- The folder: the first non-comment line of ~/.work-notes.local (local, never in the repo), else ~/notes/work: the
-- same rule as `app-launch work-notes`, which opens today's note in its own window (workspace 4).
--   daily/YYYY-MM-DD.md   projects/<name>.md   index.md (yours, untouched)
local M = {}

-- The notes folder (vim.g.work_notes_dir overrides it, for tests)
function M.root()
  if vim.g.work_notes_dir then return vim.fn.expand(vim.g.work_notes_dir) end
  local root = vim.fn.expand '~/notes/work'
  local config = vim.fn.expand '~/.work-notes.local'
  if vim.fn.filereadable(config) == 1 then
    for _, line in ipairs(vim.fn.readfile(config)) do
      if not line:match '^%s*#' and not line:match '^%s*$' then
        root = vim.fn.expand(vim.trim(line))
        break
      end
    end
  end
  return root
end

local function create(path, lines)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ':h'), 'p')
  vim.fn.writefile(lines, path)
end

local function open(path) vim.cmd.edit(vim.fn.fnameescape(path)) end

-- Today's daily note, created on first use with a link to the previous one
function M.daily()
  local dir = M.root() .. '/daily'
  local today = os.date '%Y-%m-%d'
  local path = dir .. '/' .. today .. '.md'
  if vim.fn.filereadable(path) == 0 then
    local lines = { '# ' .. os.date '%A, %d %B %Y', '' }
    local earlier = vim.tbl_filter(function(name) return name < today end,
      vim.tbl_map(function(f) return vim.fn.fnamemodify(f, ':t:r') end, vim.fn.glob(dir .. '/*.md', false, true)))
    table.sort(earlier)
    local previous = earlier[#earlier]
    if previous then vim.list_extend(lines, { 'Previous day: [' .. previous .. '](' .. previous .. '.md)', '' }) end
    vim.list_extend(lines, { '## Catch-up', '', '', '## Meetings', '', '', '## Notes', '', '', '## To-do', '', '- [ ] ', '' })
    create(path, lines)
  end
  open(path)
end

local function project_path(name) return M.root() .. '/projects/' .. name .. '.md' end

-- Open a project note; with create = true a new one gets the template (spaces and slashes in the name become -)
function M.open_project(name, create_new)
  local file_name = vim.trim(name):gsub('[/\\]', '-'):gsub('%s+', '-')
  local path = project_path(file_name)
  if vim.fn.filereadable(path) == 0 then
    if not create_new then return end
    create(path, { '# ' .. vim.trim(name), '', 'What it is: ', '', '## Links', '', '', '## Decisions', '', '',
      '## Log', '', '## To-do', '', '- [ ] ', '' })
  end
  open(path)
end

-- Pick a project note (Telescope, with a preview); after = a function run once the note is open
function M.projects(after)
  local dir = M.root() .. '/projects'
  local names = vim.tbl_map(function(f) return vim.fn.fnamemodify(f, ':t:r') end, vim.fn.glob(dir .. '/*.md', false, true))
  table.sort(names)
  local conf = require('telescope.config').values
  local actions, state = require 'telescope.actions', require 'telescope.actions.state'
  require('telescope.pickers').new({}, {
    prompt_title = 'Projects (Enter opens; a new name creates it)',
    finder = require('telescope.finders').new_table {
      results = names,
      entry_maker = function(name) return { value = name, display = name, ordinal = name, path = dir .. '/' .. name .. '.md' } end,
    },
    sorter = conf.generic_sorter {},
    previewer = conf.file_previewer {},
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local entry, typed = state.get_selected_entry(), state.get_current_line()
        actions.close(prompt_bufnr)
        if entry then
          M.open_project(entry.value)
        elseif vim.trim(typed) ~= '' then
          M.open_project(typed, true)
        else
          return
        end
        if after then vim.schedule(after) end
      end)
      return true
    end,
  }):find()
end

-- A log entry in the current project note (outside one: pick the project first). Newest day first: today's
-- "### YYYY-MM-DD" goes right under "## Log", a new "- " line under it, and you're typing.
function M.log()
  local name = vim.api.nvim_buf_get_name(0)
  if not vim.startswith(name, M.root() .. '/projects/') then return M.projects(M.log) end
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local log_row
  for i, line in ipairs(lines) do
    if line:match '^## Log%s*$' then
      log_row = i
      break
    end
  end
  if not log_row then
    vim.api.nvim_buf_set_lines(0, -1, -1, false, { '', '## Log' })
    log_row = #lines + 2
    lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  end
  local section_end = #lines + 1
  for i = log_row + 1, #lines do
    if lines[i]:match '^## ' then
      section_end = i
      break
    end
  end
  local today = '### ' .. os.date '%Y-%m-%d'
  local row
  for i = log_row + 1, section_end - 1 do
    if lines[i] == today then
      vim.api.nvim_buf_set_lines(0, i, i, false, { '- ' })
      row = i + 1
      break
    end
  end
  if not row then
    vim.api.nvim_buf_set_lines(0, log_row, log_row, false, { '', today, '- ' })
    row = log_row + 3
  end
  vim.api.nvim_win_set_cursor(0, { row, 0 })
  vim.cmd 'startinsert!'
end

-- Every open to-do with text (- [ ] something) in all notes; Enter jumps there, Ctrl+q puts them in the quickfix list
function M.todos()
  require('telescope.builtin').grep_string {
    prompt_title = 'Open to-dos (all notes)',
    search = [[- \[ \] \S]],
    use_regex = true,
    cwd = M.root(),
    additional_args = { '--glob', '*.md' },
  }
end

function M.find() require('telescope.builtin').find_files { prompt_title = 'Find a note', cwd = M.root() } end
function M.search() require('telescope.builtin').live_grep { prompt_title = 'Search all notes', cwd = M.root() } end

function M.setup()
  local function map(lhs, fn, desc) vim.keymap.set('n', lhs, fn, { desc = desc }) end
  map('<leader>nd', M.daily, '[N]otes: [D]aily note (today)')
  map('<leader>np', function() M.projects() end, '[N]otes: [P]roject (pick, or type a new name)')
  map('<leader>nl', M.log, '[N]otes: [L]og entry in a project')
  map('<leader>nt', M.todos, '[N]otes: open [T]o-dos in all notes')
  map('<leader>nf', M.find, '[N]otes: [F]ind a note')
  map('<leader>ns', M.search, '[N]otes: [S]earch all notes')
end

return M

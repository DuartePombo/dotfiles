-- Work notes: one note per day, a folder per project with one file per note, and keys to reach them from anywhere
-- (<leader>n = [N]otes).
--   <leader>nd  today's daily note (created from a template: Catch-up, Notes, To-do)
--   <leader>nn  new note: asks a title, creates projects/<project>/YYYY-MM-DD-title.md (outside a project: pick one;
--               a name that matches nothing creates the project)
--   <leader>nl  list the project's notes, newest first, with a preview
--   <leader>np  a project's overview page (its README.md: what it is, links, decisions, to-dos)
--   <leader>nt  every open to-do (- [ ] ...) in all notes; <leader>nf find a note, <leader>ns search all notes
-- The folder: the first non-comment line of ~/.work-notes.local (local, never in the repo), else ~/notes/work: the
-- same rule as `app-launch work-notes`, which opens today's note in its own window (workspace 4).
--   daily/YYYY-MM-DD.md   projects/<project>/README.md   projects/<project>/YYYY-MM-DD-title.md   index.md (yours)
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

-- File and folder names: letters (accents too), digits, - and _ only; anything else becomes one -. A project keeps
-- its case, a note's file name is lowercase; the title inside the file stays exactly as typed.
local function clean(name)
  return (vim.trim(name):gsub('[^%w%-_\128-\255]', '-'):gsub('%-+', '-'):gsub('^%-', ''):gsub('%-$', ''))
end

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
    vim.list_extend(lines, { '## Catch-up', '', '', '## Notes', '', '', '## To-do', '', '- [ ] ', '' })
    create(path, lines)
  end
  open(path)
end

local function projects_dir() return M.root() .. '/projects' end

-- The project folder exists afterwards (title = the name as typed, for a new README). A project from the first
-- version of these notes (a single projects/<name>.md) is moved in as the folder's README.md, text unchanged.
local function ensure_project(name, title)
  local dir = projects_dir() .. '/' .. name
  local old = dir .. '.md'
  if vim.fn.isdirectory(dir) == 0 and vim.fn.filereadable(old) == 1 then
    vim.fn.mkdir(dir, 'p')
    vim.fn.rename(old, dir .. '/README.md')
    vim.notify(name .. '.md moved to ' .. name .. '/README.md (a folder per project now)')
  end
  if vim.fn.filereadable(dir .. '/README.md') == 0 then
    create(dir .. '/README.md', { '# ' .. (title or name), '', 'What it is: ', '', '## Links', '', '', '## Decisions', '',
      '', '## To-do', '', '- [ ] ', '' })
  end
  return dir
end

-- The project of the current buffer (a file inside projects/<project>/), or nil
local function current_project()
  local prefix = projects_dir() .. '/'
  local name = vim.api.nvim_buf_get_name(0)
  if not vim.startswith(name, prefix) then return nil end
  local project = name:sub(#prefix + 1):match '^([^/]+)/'
  return project
end

-- A Telescope list of paths (newest first for notes), with a preview; Enter opens the chosen one
local function file_picker(title, paths, display)
  local conf = require('telescope.config').values
  require('telescope.pickers').new({}, {
    prompt_title = title,
    finder = require('telescope.finders').new_table {
      results = paths,
      entry_maker = function(path) return { value = path, display = display(path), ordinal = display(path), path = path } end,
    },
    sorter = conf.generic_sorter {},
    previewer = conf.file_previewer {},
  }):find()
end

-- Pick a project (Telescope, preview = its README); a name that matches nothing creates it. on_pick(name) runs after.
function M.pick_project(on_pick)
  local dir = projects_dir()
  local names, seen = {}, {}
  for _, path in ipairs(vim.fn.glob(dir .. '/*', false, true)) do
    local name = vim.fn.fnamemodify(path, ':t'):gsub('%.md$', '')
    if not seen[name] and (vim.fn.isdirectory(path) == 1 or path:match '%.md$') then
      seen[name] = true
      table.insert(names, name)
    end
  end
  table.sort(names)
  local conf = require('telescope.config').values
  local actions, state = require 'telescope.actions', require 'telescope.actions.state'
  require('telescope.pickers').new({}, {
    prompt_title = 'Projects (Enter picks; a new name creates it)',
    finder = require('telescope.finders').new_table {
      results = names,
      entry_maker = function(name)
        local readme = dir .. '/' .. name .. '/README.md'
        return { value = name, display = name, ordinal = name,
          path = vim.fn.filereadable(readme) == 1 and readme or dir .. '/' .. name .. '.md' }
      end,
    },
    sorter = conf.generic_sorter {},
    previewer = conf.file_previewer {},
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local entry, typed = state.get_selected_entry(), state.get_current_line()
        actions.close(prompt_bufnr)
        local name, title
        if entry then
          name = entry.value
        elseif vim.trim(typed) ~= '' then
          name, title = clean(typed), vim.trim(typed)
        else
          return
        end
        ensure_project(name, title)
        vim.schedule(function() on_pick(name) end)
      end)
      return true
    end,
  }):find()
end

-- The project's overview page (README.md)
function M.project()
  M.pick_project(function(name) open(projects_dir() .. '/' .. name .. '/README.md') end)
end

-- A new note in a project: asks for a title, creates YYYY-MM-DD-title.md, and you're typing under the title
function M.new_note_in(project)
  vim.ui.input({ prompt = 'New note in ' .. project .. ', title: ' }, function(title)
    if title == nil then return end
    title = vim.trim(title)
    if title == '' then title = 'note' end
    local date = os.date '%Y-%m-%d'
    local base = projects_dir() .. '/' .. project .. '/' .. date .. '-' .. vim.fn.tolower(clean(title))
    local path, n = base .. '.md', 2
    while vim.fn.filereadable(path) == 1 do
      path, n = base .. '-' .. n .. '.md', n + 1
    end
    create(path, { '# ' .. title, '', date .. ' · [' .. project .. '](README.md)', '', '' })
    open(path)
    vim.api.nvim_win_set_cursor(0, { 5, 0 })
    vim.cmd 'startinsert'
  end)
end

function M.new_note()
  local project = current_project()
  if project then return M.new_note_in(project) end
  M.pick_project(M.new_note_in)
end

-- The notes of a project, newest first (their names start with the date)
function M.list_notes_in(project)
  local dir = projects_dir() .. '/' .. project
  local paths = vim.tbl_filter(function(path) return vim.fn.fnamemodify(path, ':t') ~= 'README.md' end,
    vim.fn.glob(dir .. '/*.md', false, true))
  -- by the date in the name, then by when the file was made (several notes on one day: the latest first)
  local function key(path)
    local stat = vim.uv.fs_stat(path)
    local made = stat and (stat.birthtime.sec > 0 and stat.birthtime or stat.mtime) or { sec = 0, nsec = 0 }
    return vim.fn.fnamemodify(path, ':t'):sub(1, 10) .. string.format('%012d%09d', made.sec, made.nsec)
  end
  table.sort(paths, function(a, b) return key(a) > key(b) end)
  if #paths == 0 then return vim.notify('No notes in ' .. project .. ' yet: Space n n makes one') end
  file_picker('Notes in ' .. project .. ' (newest first)', paths, function(path) return vim.fn.fnamemodify(path, ':t:r') end)
end

function M.list_notes()
  local project = current_project()
  if project then return M.list_notes_in(project) end
  M.pick_project(M.list_notes_in)
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
  map('<leader>nn', M.new_note, '[N]otes: [N]ew note in a project')
  map('<leader>nl', M.list_notes, "[N]otes: [L]ist a project's notes")
  map('<leader>np', M.project, "[N]otes: a [P]roject's overview (README)")
  map('<leader>nt', M.todos, '[N]otes: open [T]o-dos in all notes')
  map('<leader>nf', M.find, '[N]otes: [F]ind a note')
  map('<leader>ns', M.search, '[N]otes: [S]earch all notes')
end

return M

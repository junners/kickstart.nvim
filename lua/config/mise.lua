local M = {}

local root_markers = { 'mise.toml', '.mise.toml', 'mise.local.toml', '.mise.local.toml' }
local notified = {}
local tool_cache = {}
local shell = vim.fn.exepath('sh')

if shell == '' then
  shell = 'sh'
end

local unpack = table.unpack

local function dedupe_key(...)
  return table.concat({ ... }, '\0')
end

local function notify_once(key, message)
  if notified[key] then
    return
  end

  notified[key] = true
  vim.schedule(function()
    vim.notify(message, vim.log.levels.WARN, { title = 'Neovim Tooling' })
  end)
end

local function tool_scope(root)
  if root then
    return root
  end

  return 'the active global mise environment'
end

local function tool_missing_message(tool, root)
  if root then
    return ('Missing required project tool "%s" for %s. Add it to that project\'s mise.toml and install it; this config will not fall back to PATH.'):format(tool, root)
  end

  return ('Missing required tool "%s" in %s. Install it with mise; this config will not fall back to PATH.'):format(tool, tool_scope(root))
end

local function mise_missing_message()
  return 'The `mise` executable is required for LSP, formatting, and other external tools. Install `mise` to use this Neovim config.'
end

local function missing_command(message)
  return {
    shell,
    '-c',
    'printf "%s\\n" "$1" >&2; exit 127',
    'sh',
    message,
  }
end

local function normalize_start(start)
  if type(start) == 'number' then
    start = vim.api.nvim_buf_get_name(start)
  end

  if start == nil or start == '' then
    start = vim.uv.cwd()
  end

  start = vim.fs.normalize(start)
  if vim.fn.isdirectory(start) == 0 then
    start = vim.fs.dirname(start)
  end

  return start
end

function M.root_markers()
  return vim.deepcopy(root_markers)
end

function M.find_root(start)
  local path = normalize_start(start)
  local found = vim.fs.find(root_markers, { path = path, upward = true })[1]
  return found and vim.fs.dirname(found) or nil
end

function M.has_mise()
  return vim.fn.executable('mise') == 1
end

function M.has_tool(tool, root)
  if not M.has_mise() then
    return false
  end

  local key = dedupe_key(root or '__global__', tool)
  if tool_cache[key] ~= nil then
    return tool_cache[key]
  end

  local cmd = { 'mise', 'which' }
  if root then
    vim.list_extend(cmd, { '-C', root })
  end
  table.insert(cmd, tool)

  local result = vim.system(cmd, { text = true }):wait()
  local ok = result.code == 0 and result.stdout ~= nil and vim.trim(result.stdout) ~= ''
  tool_cache[key] = ok

  if not ok then
    notify_once(key, tool_missing_message(tool, root))
  end

  return ok
end

function M.command(tool, args, opts)
  opts = opts or {}

  if not M.has_mise() then
    local message = mise_missing_message()
    notify_once('missing-mise', message)
    return missing_command(message)
  end

  local project_root = M.find_root(opts.root or opts.bufnr or opts.cwd)

  if not M.has_tool(tool, project_root) then
    return missing_command(tool_missing_message(tool, project_root))
  end

  local lookup = project_root and 'toolpath=$(mise which -C "$root" "$tool" 2>/dev/null)' or 'toolpath=$(mise which "$tool" 2>/dev/null)'
  local message = project_root and 'printf "Missing required project tool \\"%s\\" for %s. Add it to that project\\47s mise.toml and install it; this config will not fall back to PATH.\\n" "$tool" "$root" >&2' or 'printf "Missing required tool \\"%s\\" in the active global mise environment. Install it with mise; this config will not fall back to PATH.\\n" "$tool" >&2'

  local cmd = { 'mise', 'exec' }
  if project_root then
    vim.list_extend(cmd, { '-C', project_root })
  end
  vim.list_extend(cmd, {
    '--',
    shell,
    '-c',
    lookup .. ' || { ' .. message .. '; exit 127; }; exec "$toolpath" "$@"',
    'sh',
  })

  if project_root then
    table.insert(cmd, project_root)
  end
  table.insert(cmd, tool)

  vim.list_extend(cmd, args or {})
  return cmd
end

function M.conform(tool, args)
  local function resolve(ctx)
    return M.command(tool, args, { root = ctx.dirname })
  end

  return {
    command = function(_, ctx)
      return resolve(ctx)[1]
    end,
    args = function(_, ctx)
      local cmd = resolve(ctx)
      return { unpack(cmd, 2) }
    end,
    cwd = function(_, ctx)
      return M.find_root(ctx.dirname)
    end,
  }
end

function M.collect_tools()
  local tools = {
    'aura-language-server',
    'typescript-language-server',
    'lua-language-server',
    'intellij-server',
    'lwc-language-server',
    'mdx-language-server',
    'cspell-lsp',
    'prettierd',
    'prettier',
    'ktfmt',
  }

  table.sort(tools)
  return tools
end

return M

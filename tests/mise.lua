local failures = {}

local function expect_equal(actual, expected, message)
  if actual ~= expected then
    table.insert(failures, ('%s\nexpected: %s\nactual: %s'):format(message, vim.inspect(expected), vim.inspect(actual)))
  end
end

local function expect_truthy(value, message)
  if not value then
    table.insert(failures, message)
  end
end

local mise = require('config.mise')

local original_has_mise = mise.has_mise
local original_find_root = mise.find_root
local original_has_tool = mise.has_tool
local original_which = mise.which
local cspell_path = vim.trim(vim.system({ 'mise', 'which', 'cspell-lsp' }, { text = true }):wait().stdout or '')

mise.has_mise = function()
  return true
end

mise.find_root = function()
  return nil
end

local requested_tools = {}

mise.has_tool = function(tool, root)
  table.insert(requested_tools, { tool = tool, root = root })
  return true
end

mise.which = function(tool, root)
  expect_equal(root, nil, 'expected global fallback lookup when no project-local mise root exists')

  if tool == 'prettier' then
    return '/tmp/prettier'
  end

  if tool == 'cspell-lsp' then
    return cspell_path
  end

  if tool == 'node' then
    return '/tmp/node'
  end

  error('unexpected tool lookup: ' .. tool)
end

local cmd = mise.command('prettier', { '--version' }, { root = '/tmp/no-mise-toml-here' })
local cspell_cmd = mise.command('cspell-lsp', { '--stdio' }, { root = '/tmp/no-mise-toml-here' })

local temp_root = vim.fn.tempname()
vim.fn.mkdir(temp_root, 'p')
vim.fn.mkdir(temp_root .. '/outer/inner/leaf', 'p')
vim.fn.writefile({ '[tools]' }, temp_root .. '/outer/mise.toml')
vim.fn.writefile({}, temp_root .. '/outer/inner/mise.toml')

mise.has_mise = original_has_mise
mise.find_root = original_find_root
mise.has_tool = original_has_tool
mise.which = original_which

expect_truthy(type(cmd) == 'table', 'expected mise.command to return a command array')
expect_equal(cmd[1], 'mise', 'expected command to execute via mise')
expect_equal(cmd[2], 'exec', 'expected command to use mise exec')
expect_equal(cmd[3], '--', 'expected global fallback to avoid forcing -C without a project-local root')
expect_equal(cmd[4], '/tmp/prettier', 'expected direct execution of the resolved binary')

expect_truthy(type(cspell_cmd) == 'table', 'expected mise.command to return a command array for cspell-lsp')
expect_equal(cspell_cmd[1], 'mise', 'expected cspell-lsp command to execute via mise')
expect_equal(cspell_cmd[2], 'exec', 'expected cspell-lsp command to use mise exec')
expect_equal(cspell_cmd[3], '--', 'expected global fallback to avoid forcing -C without a project-local root')
expect_equal(cspell_cmd[4], 'node', 'expected JavaScript entrypoints to run through node')
expect_truthy(cspell_cmd[5]:match('cspell%-lsp'), 'expected cspell-lsp to resolve to its entrypoint path')

expect_equal(#requested_tools, 3, 'expected tool checks for prettier, cspell-lsp, and node')
expect_equal(requested_tools[1].tool, 'prettier', 'expected prettier to be checked first')
expect_equal(requested_tools[2].tool, 'cspell-lsp', 'expected cspell-lsp to be checked before node')
expect_equal(requested_tools[3].tool, 'node', 'expected node to be checked for JavaScript entrypoints')

expect_equal(
  mise.find_root(temp_root .. '/outer/inner/leaf'),
  temp_root .. '/outer',
  'expected blank mise.toml files to be ignored in root discovery'
)

if #failures > 0 then
  error(table.concat(failures, '\n\n'))
end

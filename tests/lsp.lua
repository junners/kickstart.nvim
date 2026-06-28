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

package.preload['blink.cmp'] = function()
  return {
    get_lsp_capabilities = function()
      return {}
    end,
  }
end

local mise = require('config.mise')
local original_has_mise = mise.has_mise
local original_find_root = mise.find_root
local original_has_tool = mise.has_tool
local original_which = mise.which
local original_command = mise.command

mise.has_mise = function()
  return true
end

mise.find_root = function()
  return nil
end

mise.has_tool = function()
  return true
end

mise.which = function(tool)
  if tool == 'cspell-lsp' then
    return '/tmp/cspell-lsp.bundle.mjs'
  end

  return '/tmp/' .. tool
end

mise.command = function(tool, args)
  local cmd = { 'mise', 'exec', '--' }
  if tool == 'cspell-lsp' then
    vim.list_extend(cmd, { 'node', '/tmp/cspell-lsp.bundle.mjs' })
  else
    vim.list_extend(cmd, { '/tmp/' .. tool })
  end
  vim.list_extend(cmd, args or {})
  return cmd
end

local original_config = vim.lsp.config
local original_enable = vim.lsp.enable

local configs = {}

vim.lsp.config = function(name, config)
  configs[name] = config
end

vim.lsp.enable = function()
end

require('config.lsp').setup()

mise.has_mise = original_has_mise
mise.find_root = original_find_root
mise.has_tool = original_has_tool
mise.which = original_which
mise.command = original_command
vim.lsp.config = original_config
vim.lsp.enable = original_enable

local cspell = configs.cspell_ls
local kotlin = configs.kotlin_lsp
local kotlin_lsp_path = vim.fn.exepath('kotlin-lsp')

expect_truthy(type(cspell) == 'table', 'expected cspell_ls config to be registered')
expect_truthy(type(cspell.cmd) == 'table', 'expected cspell_ls to have a concrete command before root detection')
expect_equal(cspell.cmd[1], 'mise', 'expected cspell_ls to execute through mise')
expect_equal(cspell.cmd[2], 'exec', 'expected cspell_ls to use mise exec')
expect_equal(cspell.cmd[3], '--', 'expected cspell_ls to avoid forcing a project root at registration time')
expect_equal(cspell.cmd[4], 'node', 'expected cspell-lsp to run through node when registered')
expect_truthy(vim.inspect(cspell.cmd):match('cspell%-lsp'), 'expected cspell-lsp entrypoint to be present in the command')

expect_truthy(type(kotlin) == 'table', 'expected kotlin_lsp config to be registered')
expect_truthy(type(kotlin.cmd) == 'table', 'expected kotlin_lsp to have a concrete command')
expect_equal(kotlin.cmd[1], kotlin_lsp_path, 'expected kotlin_lsp to use the Homebrew-installed binary')
expect_equal(kotlin.cmd[2], '--stdio', 'expected kotlin_lsp to start in stdio mode')

if #failures > 0 then
  error(table.concat(failures, '\n\n'))
end

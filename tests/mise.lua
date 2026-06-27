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

mise.has_mise = function()
  return true
end

mise.find_root = function()
  return nil
end

mise.has_tool = function(tool, root)
  expect_equal(tool, 'prettier', 'expected the requested tool name to be preserved')
  expect_equal(root, nil, 'expected global fallback lookup when no project-local mise root exists')
  return true
end

local cmd = mise.command('prettier', { '--version' }, { root = '/tmp/no-mise-toml-here' })

mise.has_mise = original_has_mise
mise.find_root = original_find_root
mise.has_tool = original_has_tool

expect_truthy(type(cmd) == 'table', 'expected mise.command to return a command array')
expect_equal(cmd[1], 'mise', 'expected command to execute via mise')
expect_equal(cmd[2], 'exec', 'expected command to use mise exec')
expect_equal(cmd[3], '--', 'expected global fallback to avoid forcing -C without a project-local root')

if #failures > 0 then
  error(table.concat(failures, '\n\n'))
end

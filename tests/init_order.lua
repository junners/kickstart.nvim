local failures = {}
local calls = {}

local function expect_equal(actual, expected, message)
  if actual ~= expected then
    table.insert(failures, ('%s\nexpected: %s\nactual: %s'):format(message, vim.inspect(expected), vim.inspect(actual)))
  end
end

local function mark(name)
  table.insert(calls, name)
end

for _, name in ipairs { 'config.options', 'config.keymaps', 'config.autocmds', 'config.lazy', 'config.lsp', 'config.format' } do
  package.preload[name] = function()
    mark(name)
    return {}
  end
end

require('config')

expect_equal(calls[1], 'config.options', 'expected options to load first')
expect_equal(calls[2], 'config.keymaps', 'expected keymaps to load second')
expect_equal(calls[3], 'config.autocmds', 'expected autocmds to load third')
expect_equal(calls[4], 'config.lazy', 'expected lazy bootstrap before lsp setup')
expect_equal(calls[5], 'config.lsp', 'expected lsp setup after lazy bootstrap')
expect_equal(calls[6], 'config.format', 'expected formatter setup after lazy bootstrap')

if #failures > 0 then
  error(table.concat(failures, '\n\n'))
end

local failures = {}

local function expect(condition, message)
  if not condition then
    table.insert(failures, message)
  end
end

expect(vim.g.mapleader == ' ', 'expected <Space> leader during bootstrap')
expect(package.loaded.lazy ~= nil, 'expected lazy.nvim to be bootstrapped')
expect(package.loaded['config.options'] ~= nil, 'expected config.options module to load')
expect(package.loaded['config.keymaps'] ~= nil, 'expected config.keymaps module to load')
expect(package.loaded['config.autocmds'] ~= nil, 'expected config.autocmds module to load')
expect(package.loaded['config.lsp'] ~= nil, 'expected config.lsp module to load')
expect(package.loaded['config.format'] ~= nil, 'expected config.format module to load')
expect(package.loaded.plugins ~= nil, 'expected plugins module to load')
expect(vim.fn.exists(':Mason') == 0, 'expected Mason commands to be absent')
expect(vim.fn.isdirectory(vim.fn.stdpath('config') .. '/lua/kickstart') == 0, 'expected legacy lua/kickstart tree to be removed')
expect(vim.fn.isdirectory(vim.fn.stdpath('config') .. '/lua/custom') == 0, 'expected legacy lua/custom tree to be removed')

if #failures > 0 then
  error(table.concat(failures, '\n'))
end

vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking text',
  group = vim.api.nvim_create_augroup('jun-highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

local java_decompile = require 'config.java_decompile'

vim.api.nvim_create_autocmd('BufReadPost', {
  desc = 'Decompile Java class files from build output directories',
  group = vim.api.nvim_create_augroup('jun-java-decompile', { clear = true }),
  callback = function(event)
    local path = vim.api.nvim_buf_get_name(event.buf)
    if not java_decompile.should_decompile(path) then
      return
    end

    local lines, err = java_decompile.decompile(path)
    if not lines then
      vim.notify(err, vim.log.levels.WARN, { title = 'Java Decompiler' })
      return
    end

    vim.bo[event.buf].modifiable = true
    vim.api.nvim_buf_set_lines(event.buf, 0, -1, false, lines)
    vim.bo[event.buf].modifiable = false
    vim.bo[event.buf].modified = false
    vim.bo[event.buf].swapfile = false
    vim.bo[event.buf].filetype = 'java'
  end,
})

vim.filetype.add {
  extension = {
    apex = 'apex',
    app = 'aura',
    auradoc = 'aura',
    cls = 'apex',
    cmp = 'aura',
    design = 'aura',
    evt = 'aura',
    intf = 'aura',
    mdx = 'mdx',
    tokens = 'aura',
    trigger = 'apex',
  },
}

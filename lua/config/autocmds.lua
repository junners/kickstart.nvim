vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking text',
  group = vim.api.nvim_create_augroup('jun-highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
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

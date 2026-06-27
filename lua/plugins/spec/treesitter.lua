return {
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    dependencies = {
      'nvim-tree/nvim-web-devicons',
    },
    config = function()
      vim.treesitter.language.register('markdown', 'mdx')
      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'mdx',
        callback = function(args)
          vim.treesitter.start(args.buf, 'markdown')
        end,
      })
    end,
  },
}

return {
  {
    'j-hui/fidget.nvim',
    opts = {},
  },
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      'j-hui/fidget.nvim',
      'saghen/blink.cmp',
    },
    config = function()
      require('config.lsp').setup()
    end,
  },
}

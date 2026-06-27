return {
  {
    'stevearc/conform.nvim',
    config = function()
      require('config.format').setup()
    end,
  },
}

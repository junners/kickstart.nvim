return {
  {
    'L3MON4D3/LuaSnip',
    version = 'v2.*',
    build = function()
      if vim.fn.has('win32') == 1 or vim.fn.executable('make') ~= 1 then
        return
      end

      return 'make install_jsregexp'
    end,
    config = function()
      require('luasnip').setup {}
    end,
  },
  {
    'saghen/blink.cmp',
    version = '1.*',
    dependencies = {
      'L3MON4D3/LuaSnip',
    },
    config = function()
      require('blink.cmp').setup {
        keymap = {
          preset = 'default',
        },
        appearance = {
          nerd_font_variant = 'mono',
        },
        completion = {
          documentation = { auto_show = false, auto_show_delay_ms = 500 },
        },
        sources = {
          default = { 'lsp', 'path', 'snippets' },
        },
        snippets = { preset = 'luasnip' },
        fuzzy = { implementation = 'lua' },
        signature = { enabled = true },
      }
    end,
  },
}

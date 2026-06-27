return {
  {
    'NMAC427/guess-indent.nvim',
    config = function()
      require('guess-indent').setup {}
    end,
  },
  {
    'nvim-tree/nvim-web-devicons',
    enabled = vim.g.have_nerd_font,
  },
  {
    'folke/which-key.nvim',
    opts = {
      delay = 0,
      icons = { mappings = vim.g.have_nerd_font },
      spec = {
        { '<leader>s', group = '[S]earch', mode = { 'n', 'v' } },
        { '<leader>t', group = '[T]oggle' },
        { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
        { 'gr', group = 'LSP Actions', mode = { 'n' } },
      },
    },
  },
  {
    'scottmckendry/cyberdream.nvim',
    opts = {
      variant = 'default',
      transparent = true,
      saturation = 0,
      italic_comments = true,
      hide_fillchars = true,
      borderless_pickers = true,
      terminal_colors = true,
      cache = false,
      highlights = {
        Comment = { fg = '#696969', bg = 'NONE', italic = true },
      },
      overrides = function(colors)
        return {
          Comment = { fg = colors.green, bg = 'NONE', italic = true },
          ['@property'] = { fg = colors.magenta, bold = true },
        }
      end,
      extensions = {
        telescope = true,
        notify = true,
        mini = true,
        cmp = true,
        gitsigns = true,
        base = true,
      },
    },
    config = function(_, opts)
      require('cyberdream').setup(opts)
    end,
  },
  {
    'navarasu/onedark.nvim',
    opts = {
      style = 'darker',
    },
    config = function(_, opts)
      require('onedark').setup(opts)
    end,
  },
  {
    'folke/tokyonight.nvim',
    priority = 1000,
    opts = {
      styles = {
        comments = { italic = false },
      },
    },
    config = function(_, opts)
      require('tokyonight').setup(opts)
      vim.cmd.colorscheme 'tokyonight-night'
    end,
  },
  {
    'folke/todo-comments.nvim',
    opts = {
      signs = false,
    },
  },
  {
    'nvim-mini/mini.nvim',
    config = function()
      require('mini.ai').setup {
        mappings = {
          around_next = 'aa',
          inside_next = 'ii',
        },
        n_lines = 500,
      }

      require('mini.surround').setup()

      local statusline = require 'mini.statusline'
      statusline.setup { use_icons = vim.g.have_nerd_font }
      statusline.section_location = function()
        return '%2l:%-2v'
      end
    end,
  },
}

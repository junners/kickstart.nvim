local M = {}

local mise = require('config.mise')

local enabled_filetypes = {
  css = true,
  html = true,
  javascript = true,
  javascriptreact = true,
  json = true,
  kotlin = true,
  markdown = true,
  mdx = true,
  scss = true,
  typescript = true,
  typescriptreact = true,
  yaml = true,
}

vim.keymap.set({ 'n', 'v' }, '<leader>f', function()
  require('conform').format { async = true }
end, { desc = '[F]ormat buffer' })

function M.setup()
  require('conform').setup {
    notify_on_error = true,
    notify_no_formatters = true,
    format_on_save = function(bufnr)
      if enabled_filetypes[vim.bo[bufnr].filetype] then
        return { timeout_ms = 500 }
      end

      return nil
    end,
    default_format_opts = {
      lsp_format = 'fallback',
    },
    formatters = {
      mise_prettierd = vim.tbl_deep_extend('force', {
        inherit = false,
        stdin = true,
      }, mise.conform('prettierd', { '$FILENAME' })),
      mise_prettier = vim.tbl_deep_extend('force', {
        inherit = false,
        stdin = true,
      }, mise.conform('prettier', { '--stdin-filepath', '$FILENAME' })),
      mise_ktfmt = vim.tbl_deep_extend('force', {
        inherit = false,
        stdin = true,
      }, mise.conform('ktfmt', { '--kotlinlang-style', '-' })),
    },
    formatters_by_ft = {
      css = { 'mise_prettierd', 'mise_prettier', stop_after_first = true },
      html = { 'mise_prettierd', 'mise_prettier', stop_after_first = true },
      javascript = { 'mise_prettierd', 'mise_prettier', stop_after_first = true },
      javascriptreact = { 'mise_prettierd', 'mise_prettier', stop_after_first = true },
      json = { 'mise_prettierd', 'mise_prettier', stop_after_first = true },
      kotlin = { 'mise_ktfmt' },
      markdown = { 'mise_prettierd', 'mise_prettier', stop_after_first = true },
      mdx = { 'mise_prettierd', 'mise_prettier', stop_after_first = true },
      scss = { 'mise_prettierd', 'mise_prettier', stop_after_first = true },
      typescript = { 'mise_prettierd', 'mise_prettier', stop_after_first = true },
      typescriptreact = { 'mise_prettierd', 'mise_prettier', stop_after_first = true },
      yaml = { 'mise_prettierd', 'mise_prettier', stop_after_first = true },
    },
  }
end

return M

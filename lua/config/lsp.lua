local M = {}

local mise = require('config.mise')

local function on_lsp_attach(event)
  local map = function(keys, func, desc, mode)
    vim.keymap.set(mode or 'n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
  end

  map('grn', vim.lsp.buf.rename, '[R]e[n]ame')
  map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })
  map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
  map('gd', vim.lsp.buf.definition, '[G]oto [D]efinition')

  local client = vim.lsp.get_client_by_id(event.data.client_id)
  if client and client:supports_method('textDocument/documentHighlight', event.buf) then
    local highlight_group = vim.api.nvim_create_augroup('jun-lsp-highlight', { clear = false })

    vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
      buffer = event.buf,
      group = highlight_group,
      callback = function()
        for _, active_client in ipairs(vim.lsp.get_clients { bufnr = event.buf }) do
          if active_client:supports_method('textDocument/documentHighlight', event.buf) then
            return vim.lsp.buf.document_highlight()
          end
        end
      end,
    })

    vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
      buffer = event.buf,
      group = highlight_group,
      callback = vim.lsp.buf.clear_references,
    })

    vim.api.nvim_create_autocmd('LspDetach', {
      group = vim.api.nvim_create_augroup('jun-lsp-detach', { clear = true }),
      callback = function(event2)
        vim.lsp.buf.clear_references()
        vim.api.nvim_clear_autocmds { group = 'jun-lsp-highlight', buffer = event2.buf }
      end,
    })
  end

  if client and client:supports_method('textDocument/inlayHint', event.buf) then
    map('<leader>th', function()
      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
    end, '[T]oggle Inlay [H]ints')
  end
end

local function with_mise(tool, args, config)
  config = config or {}
  local original_on_new_config = config.on_new_config

  config.on_new_config = function(new_config, new_root_dir)
    new_config.cmd = mise.command(tool, args, { root = new_root_dir })
    if original_on_new_config then
      original_on_new_config(new_config, new_root_dir)
    end
  end

  return config
end

local function servers()
  return {
    ts_ls = with_mise('typescript-language-server', { '--stdio' }),
    kotlin_lsp = with_mise('intellij-server', { '--stdio' }),
    mdx_analyzer = with_mise('mdx-language-server', {
      '--stdio',
    }, {
      capabilities = {
        workspace = {
          didChangeWatchedFiles = {
            dynamicRegistration = false,
            relativePatternSupport = false,
          },
        },
      },
    }),
    cspell_ls = with_mise('cspell-lsp', { '--stdio' }, {
      root_markers = { 'cspell.config.yaml', '.git', 'package.json' },
      settings = {
        cSpell = {
          configFile = 'cspell.config.yaml',
        },
      },
    }),
    lua_ls = with_mise('lua-language-server', nil, {
      on_init = function(client)
        client.server_capabilities.documentFormattingProvider = false

        if client.workspace_folders then
          local path = client.workspace_folders[1].name
          if path ~= vim.fn.stdpath('config')
            and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc'))
          then
            return
          end
        end

        client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
          runtime = {
            version = 'LuaJIT',
            path = { 'lua/?.lua', 'lua/?/init.lua' },
          },
          workspace = {
            checkThirdParty = false,
            library = vim.tbl_extend('force', vim.api.nvim_get_runtime_file('', true), {
              '${3rd}/luv/library',
              '${3rd}/busted/library',
            }),
          },
        })
      end,
      settings = {
        Lua = {
          format = { enable = false },
        },
      },
    }),
  }
end

function M.setup()
  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('jun-lsp-attach', { clear = true }),
    callback = on_lsp_attach,
  })

  local capabilities = require('blink.cmp').get_lsp_capabilities()

  for name, config in pairs(servers()) do
    config.capabilities = vim.tbl_deep_extend('force', capabilities, config.capabilities or {})
    vim.lsp.config(name, config)
    vim.lsp.enable(name)
  end
end

return M

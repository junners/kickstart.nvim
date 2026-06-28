local M = {}

local mise = require('config.mise')
local shell = vim.fn.exepath('sh')

if shell == '' then
  shell = 'sh'
end

local apex_jar_path = vim.fs.normalize(vim.fn.expand '~/.config/mise/salesforce/apex/v67.2.0/apex-jorje-lsp.jar')
local jdtls_path = vim.fs.normalize(vim.fn.expand '~/.config/mise/eclipse/jdtls/1.60.0/bin/jdtls')
local kotlin_lsp_path = vim.fn.exepath('kotlin-lsp')

local function missing_command(message)
  return {
    shell,
    '-c',
    'printf "%s\\n" "$1" >&2; exit 127',
    'sh',
    message,
  }
end

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
  local original_cmd = config.cmd

  config.cmd = original_cmd or mise.command(tool, args)

  config.on_new_config = function(new_config, new_root_dir)
    new_config.cmd = mise.command(tool, args, { root = new_root_dir })
    if original_on_new_config then
      original_on_new_config(new_config, new_root_dir)
    end
  end

  return config
end

local function jdtls_jvm_args()
  local env = os.getenv 'JDTLS_JVM_ARGS'
  local args = {}

  for arg in string.gmatch(env or '', '%S+') do
    table.insert(args, ('--jvm-arg=%s'):format(arg))
  end

  return args
end

local function jdtls_config()
  return {
    filetypes = { 'java' },
    root_markers = {
      'mvnw',
      'gradlew',
      'settings.gradle',
      'settings.gradle.kts',
      '.git',
      'build.xml',
      'pom.xml',
      'build.gradle',
      'build.gradle.kts',
    },
    on_new_config = function(new_config, new_root_dir)
      if not vim.uv.fs_stat(jdtls_path) then
        new_config.cmd = missing_command(
          ('Missing required JDT LS launcher at %s. Reinstall the Eclipse JDT Language Server archive.'):format(
            jdtls_path
          )
        )
        return
      end

      local data_dir = vim.fn.stdpath('cache') .. '/jdtls/workspace'
      if new_root_dir then
        data_dir = data_dir .. '/' .. vim.fn.fnamemodify(new_root_dir, ':p:h:t')
      end

      new_config.cmd = { jdtls_path, '-data', data_dir, table.unpack(jdtls_jvm_args()) }
    end,
  }
end

local function kotlin_lsp_config()
  if kotlin_lsp_path == '' then
    return {
      filetypes = { 'kotlin' },
      root_markers = {
        'gradlew',
        'mvnw',
        'settings.gradle',
        'settings.gradle.kts',
        'build.gradle',
        'build.gradle.kts',
        'pom.xml',
        '.git',
      },
      cmd = missing_command(
        'Missing required Kotlin language server at `kotlin-lsp`. Install `JetBrains/utils/kotlin-lsp` with Homebrew.'
      ),
    }
  end

  return {
    filetypes = { 'kotlin' },
    root_markers = {
      'gradlew',
      'mvnw',
      'settings.gradle',
      'settings.gradle.kts',
      'build.gradle',
      'build.gradle.kts',
      'pom.xml',
      '.git',
    },
    cmd = { kotlin_lsp_path, '--stdio' },
  }
end

local function apex_config()
  return {
    filetypes = { 'apex' },
    root_markers = { 'sfdx-project.json' },
    on_new_config = function(new_config, new_root_dir)
      if not vim.uv.fs_stat(apex_jar_path) then
        new_config.cmd = missing_command(
          ('Missing required Apex language server jar at %s. Reinstall apex-jorje-lsp.jar.'):format(apex_jar_path)
        )
        return
      end

      new_config.cmd = mise.command('java', {
        '-cp',
        apex_jar_path,
        '-Ddebug.internal.errors=true',
        '-Ddebug.semantic.errors=false',
        '-Ddebug.completion.statistics=false',
        '-Dlwc.typegeneration.disabled=true',
        'apex.jorje.lsp.ApexLanguageServerLauncher',
      }, { root = new_root_dir })
    end,
  }
end

local function servers()
  return {
    apex_ls = apex_config(),
    aura_ls = with_mise('aura-language-server', { '--stdio' }, {
      filetypes = { 'aura' },
      root_markers = { 'sfdx-project.json' },
    }),
    jdtls = jdtls_config(),
    ts_ls = with_mise('typescript-language-server', { '--stdio' }),
    kotlin_lsp = kotlin_lsp_config(),
    lwc_ls = with_mise('lwc-language-server', { '--stdio' }, {
      filetypes = { 'javascript', 'html' },
      root_markers = { 'sfdx-project.json' },
      init_options = {
        embeddedLanguages = {
          javascript = true,
        },
      },
    }),
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

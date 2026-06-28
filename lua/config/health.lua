local mise = require('config.mise')

local function check_version()
  local version = tostring(vim.version())

  if vim.version.ge and vim.version.ge(vim.version(), '0.12') then
    vim.health.ok(("Neovim version is '%s'"):format(version))
    return
  end

  vim.health.error(("Neovim is too old: '%s'. Upgrade to Neovim 0.12 or newer."):format(version))
end

local function check_base_tools()
  for _, executable in ipairs { 'git', 'make', 'unzip', 'rg', 'mise', 'kotlin-lsp' } do
    if vim.fn.executable(executable) == 1 then
      vim.health.ok(("Found executable: '%s'"):format(executable))
    else
      vim.health.warn(("Missing executable: '%s'"):format(executable))
    end
  end
end

local function check_project_tools()
  local cwd = vim.uv.cwd()
  local root = mise.find_root(cwd)

  if not root then
    vim.health.info(('No project-local mise.toml found above %s. Falling back to the active global mise environment.'):format(cwd))
  else
    vim.health.ok(("Using project-local mise config at '%s'"):format(root))
  end

  for _, tool in ipairs(mise.collect_tools()) do
    if mise.has_tool(tool, root) then
      vim.health.ok(("Resolved tool via mise: '%s'"):format(tool))
    else
      vim.health.warn(("Configured tool is missing from the current mise environment: '%s'"):format(tool))
    end
  end
end

return {
  check = function()
    vim.health.start 'config'
    vim.health.info 'External tools are resolved through mise, preferring project-local mise.toml and otherwise using the active global mise environment.'
    check_version()
    check_base_tools()
    check_project_tools()
  end,
}

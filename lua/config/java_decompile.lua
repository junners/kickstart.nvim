local M = {}

local fernflower_jar_path = vim.fs.normalize(
  vim.fn.expand '~/.local/share/mise/installs/github-fwcd-kotlin-language-server/1.3.13/lib/fernflower-1.0.jar'
)
local java = vim.fn.exepath('java')

if java == '' then
  java = 'java'
end

local function is_class_file(path)
  return path:sub(-6) == '.class'
end

local function is_build_output(path)
  local normalized = vim.fs.normalize(path)
  return normalized:find('/build/', 1, true) ~= nil or normalized:find('\\build\\', 1, true) ~= nil
end

local function temp_dir()
  local path = vim.fn.tempname()
  vim.fn.mkdir(path, 'p')
  return path
end

local function find_decompiled_file(output_dir)
  local matches = vim.fn.globpath(output_dir, '**/*.java', false, true)
  if #matches == 0 then
    return nil
  end

  table.sort(matches)
  return matches[1]
end

function M.should_decompile(path)
  return type(path) == 'string' and path ~= '' and is_class_file(path) and is_build_output(path)
end

function M.command(class_path, output_dir)
  return { java, '-jar', fernflower_jar_path, class_path, output_dir }
end

function M.decompile(class_path)
  if not vim.uv.fs_stat(fernflower_jar_path) then
    return nil, ('Missing FernFlower jar at %s'):format(fernflower_jar_path)
  end

  local output_dir = temp_dir()
  local result = vim.system(M.command(class_path, output_dir), { text = true }):wait()
  if result.code ~= 0 then
    return nil, vim.trim((result.stderr or result.stdout or ''):gsub('%s+$', ''))
  end

  local decompiled_path = find_decompiled_file(output_dir)
  if not decompiled_path then
    return nil, 'FernFlower did not produce a Java source file'
  end

  local ok, lines = pcall(vim.fn.readfile, decompiled_path)
  if not ok then
    return nil, ('Failed to read decompiled output %s'):format(decompiled_path)
  end

  return lines
end

return M

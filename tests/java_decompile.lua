local failures = {}

local function expect_equal(actual, expected, message)
  if actual ~= expected then
    table.insert(failures, ('%s\nexpected: %s\nactual: %s'):format(message, vim.inspect(expected), vim.inspect(actual)))
  end
end

local decompile = require('config.java_decompile')

local class_path = '/Users/jun/work/app/build/classes/java/main/com/example/Demo.class'
local java_path = vim.fn.exepath('java')
local javac_path = vim.fn.exepath('javac')

expect_equal(decompile.should_decompile(class_path), true, 'expected build output .class files to be decompiled')
expect_equal(decompile.should_decompile('/Users/jun/work/app/src/main/java/com/example/Demo.java'), false, 'expected source files to be ignored')

local command = decompile.command(class_path)
expect_equal(command[1], java_path, 'expected fernflower to run through the resolved java executable')
expect_equal(command[2], '-jar', 'expected fernflower to launch via jar')
expect_equal(
  command[3],
  vim.fs.normalize(vim.fn.expand '~/.local/share/mise/installs/github-fwcd-kotlin-language-server/1.3.13/lib/fernflower-1.0.jar'),
  'expected command to use the bundled fernflower jar'
)

local temp_root = vim.fn.tempname()
vim.fn.mkdir(temp_root, 'p')
vim.fn.mkdir(temp_root .. '/build/classes', 'p')
vim.fn.mkdir(temp_root .. '/src/com/example', 'p')
vim.fn.writefile({
  'package com.example;',
  '',
  'public class Demo {',
  '  public static String hi() {',
  '    return "hi";',
  '  }',
  '}',
}, temp_root .. '/src/com/example/Demo.java')

local compile_result = vim.system({ javac_path, '-d', temp_root .. '/build/classes', temp_root .. '/src/com/example/Demo.java' }, { text = true }):wait()
expect_equal(compile_result.code, 0, 'expected the fixture class to compile')

local lines, err = decompile.decompile(temp_root .. '/build/classes/com/example/Demo.class')
expect_equal(err, nil, 'expected decompiler to succeed on the compiled fixture')
expect_equal(lines[1], 'package com.example;', 'expected the decompiled output to begin with the package declaration')
expect_equal(vim.trim(lines[#lines]), '}', 'expected the decompiled output to end with the class body')

require('config.autocmds')
vim.cmd('edit ' .. vim.fn.fnameescape(temp_root .. '/build/classes/com/example/Demo.class'))
expect_equal(vim.bo.filetype, 'java', 'expected opening a build class file to switch the buffer to java filetype')
expect_equal(vim.api.nvim_buf_get_lines(0, 0, 1, false)[1], 'package com.example;', 'expected the buffer contents to be replaced with decompiled java')

if #failures > 0 then
  error(table.concat(failures, '\n\n'))
end

local ok, err = pcall(dofile, vim.fs.joinpath(vim.fn.stdpath('config'), 'tests', 'mise.lua'))

if ok then
  vim.cmd.qa()
  return
end

vim.api.nvim_err_writeln(err)
vim.cmd.cquit(1)

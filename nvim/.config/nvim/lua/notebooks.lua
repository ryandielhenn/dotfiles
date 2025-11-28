-- Template path
local notebook_template = vim.fn.expand('~/.config/nvim/templates/notebook.ipynb')

-- Create a command to make new notebooks
vim.api.nvim_create_user_command('NB', function(opts)
  local filename = opts.args
  if filename == '' then
    vim.notify('Usage: :NB <filename.ipynb>', vim.log.levels.ERROR)
    return
  end
  
  -- Add .ipynb extension if not present
  if not filename:match('%.ipynb$') then
    filename = filename .. '.ipynb'
  end
  
  -- Check if file already exists
  if vim.fn.filereadable(filename) == 0 then
    -- Copy template to new file before opening
    vim.fn.system(string.format('cp %s %s', notebook_template, vim.fn.shellescape(filename)))
  end
  
  vim.cmd('edit ' .. filename)
end, { nargs = 1 })

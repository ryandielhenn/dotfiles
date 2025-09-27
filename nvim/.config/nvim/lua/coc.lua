-- lua/coc.lua

-- helper
local function map(mode, lhs, rhs, opts)
  opts = vim.tbl_extend("force", { silent = true, noremap = true }, opts or {})
  vim.keymap.set(mode, lhs, rhs, opts)
end

-- backspace check for <Tab> behavior
local function check_backspace()
  local col = vim.fn.col(".") - 1
  if col <= 0 then
    return true
  end
  local ch = vim.fn.getline("."):sub(col, col)
  return ch:match("%s") ~= nil
end

-- Insert-mode mappings (expr)
map("i", "<Tab>", function()
  if vim.fn["coc#pum#visible"]() == 1 then
    return vim.fn
  end
  if check_backspace() then
    return "<Tab>"
  end
  vim.fn["coc#refresh"]()
  return ""
end, { expr = true })

map("i", "<S-Tab>", function()
  if vim.fn["coc#pum#visible"]() == 1 then
    return vim.fn
  end
  return "<C-h>"
end, { expr = true })

map("i", "<CR>", function()
  if vim.fn["coc#pum#visible"]() == 1 then
    return vim.fn["coc#pum#confirm"]()
  end
  return "<C-g>u<CR><C-r>=coc#on_enter()<CR>"
end, { expr = true })

map("i", "<C-Space>", "coc#refresh()", { expr = true, silent = true })

-- Normal/Visual mode Coc maps (use Plug, so noremap = false)
map("n", "gd", "<Plug>(coc-definition)", { noremap = false })
map("n", "gy", "<Plug>(coc-type-definition)", { noremap = false })
map("n", "gi", "<Plug>(coc-implementation)", { noremap = false })
map("n", "gr", "<Plug>(coc-references)", { noremap = false })
map("n", "[g", "<Plug>(coc-diagnostic-prev)", { noremap = false })
map("n", "]g", "<Plug>(coc-diagnostic-next)", { noremap = false })
map("n", "K", ":call CocAction('doHover')<CR>")
map("n", "<leader>rn", "<Plug>(coc-rename)", { noremap = false })
map("x", "<leader>f", "<Plug>(coc-format-selected)", { noremap = false })
map("n", "<leader>f", "<Plug>(coc-format-selected)", { noremap = false })

-- MarkdownPreview bits
vim.g.mkdp_filetypes = { "markdown" }
vim.g.mkdp_auto_close = 1
map("n", "<leader>mp", ":MarkdownPreviewToggle<CR>")

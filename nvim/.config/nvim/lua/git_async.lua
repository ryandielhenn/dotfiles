local map = function(m, l, r, o) o = vim.tbl_extend("force", { silent = true, noremap = true }, o or {}) vim.keymap.set(m,l,r,o) end
map("n", "gb", ":Git blame<CR>")
vim.g.asyncrun_open = 10
map("n", "<leader>ar", ":AsyncRun ")
map("n", "bn", ":bn<CR>")
map("n", "bp", ":bp<CR>")

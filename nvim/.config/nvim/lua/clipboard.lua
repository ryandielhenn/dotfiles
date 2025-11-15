local ok, osc52 = pcall(require, "osc52")
if not ok then return end

local function copy(lines, regtype)
  local text = table.concat(lines, "\n")
  
  if os.getenv("TMUX") then
    -- Use system clipboard command based on OS
    if vim.fn.has("mac") == 1 then
      vim.fn.system("pbcopy", text)
    elseif vim.fn.has("unix") == 1 then
      -- Try wl-copy (Wayland) first, then xclip (X11)
      if vim.fn.executable("wl-copy") == 1 then
        vim.fn.system("wl-copy", text)
      elseif vim.fn.executable("xclip") == 1 then
        vim.fn.system("xclip -selection clipboard", text)
      elseif vim.fn.executable("xsel") == 1 then
        vim.fn.system("xsel --clipboard --input", text)
      end
    end
  end
  
  -- Still try OSC 52 (works over SSH)
  osc52.copy(text)
end

local function paste()
  if os.getenv("TMUX") then
    local output
    if vim.fn.has("mac") == 1 then
      output = vim.fn.system("pbpaste")
    elseif vim.fn.has("unix") == 1 then
      if vim.fn.executable("wl-paste") == 1 then
        output = vim.fn.system("wl-paste --no-newline")
      elseif vim.fn.executable("xclip") == 1 then
        output = vim.fn.system("xclip -selection clipboard -o")
      elseif vim.fn.executable("xsel") == 1 then
        output = vim.fn.system("xsel --clipboard --output")
      end
    end
    
    if output and vim.v.shell_error == 0 and output ~= "" then
      return vim.split(output, "\n", { plain = true, trimempty = false }), "v"
    end
  end
  
  local s = vim.fn.getreg('"')
  return vim.split(s, "\n", { plain = true, trimempty = false }), vim.fn.getregtype('"')
end

vim.g.clipboard = {
  name = "osc52",
  copy = { ["+"] = copy, ["*"] = copy },
  paste = { ["+"] = paste, ["*"] = paste },
}
vim.o.clipboard = "unnamedplus"

-- ~/.config/nvim/lua/config/options.lua
vim.opt.clipboard = "unnamedplus"

vim.g.clipboard = {
  name = "wsl-clipboard",
  copy = { ["+"] = "clip.exe", ["*"] = "clip.exe" },
  paste = {
    ["+"] = "powershell.exe -NoProfile -Command Get-Clipboard",
    ["*"] = "powershell.exe -NoProfile -Command Get-Clipboard",
  },
  cache_enabled = 0,
}

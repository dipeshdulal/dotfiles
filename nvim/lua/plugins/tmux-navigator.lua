-- Seamless Ctrl+h/j/k/l between nvim splits and herdr panes.
-- Uses christoomey/vim-tmux-navigator as the base (kept for tmux fallback),
-- but disables its default maps and loads vim-herdr-navigation's editor/nvim.lua
-- as the single source of truth. Falls back to tmux ($TMUX) or plain wincmd
-- when not inside a herdr pane.
return {
  "christoomey/vim-tmux-navigator",
  lazy = false,
  init = function()
    vim.g.tmux_navigator_no_mappings = 1
  end,
  config = function()
    dofile(vim.fn.expand("~/Projects/vim-herdr-navigation/editor/nvim.lua"))
  end,
}

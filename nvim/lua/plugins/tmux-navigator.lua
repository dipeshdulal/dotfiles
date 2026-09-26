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
    -- Case-sensitive filesystems (Linux) need the lowercase path; macOS users
    -- may have either. Probe both before falling back to plain wincmd.
    for _, path in ipairs({
      vim.fn.expand("~/projects/vim-herdr-navigation/editor/nvim.lua"),
      vim.fn.expand("~/Projects/vim-herdr-navigation/editor/nvim.lua"),
    }) do
      if vim.fn.filereadable(path) == 1 then
        dofile(path)
        return
      end
    end
    vim.notify(
      "vim-herdr-navigation not found; falling back to wincmd",
      vim.log.levels.WARN
    )
  end,
}

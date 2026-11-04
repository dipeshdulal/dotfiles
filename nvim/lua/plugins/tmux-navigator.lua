-- Seamless Ctrl+h/j/k/l between nvim splits and the surrounding multiplexer.
-- Uses christoomey/vim-tmux-navigator as the tmux fallback (its default maps
-- are disabled). Precedence at a split edge: Rex, then herdr, then tmux.
--
-- Rex: focus crosses panes server-side via `rex.session.focus_direction`, so
-- it needs no Remote Control permission and no app round trip. Rex for Mac
-- sets REX_SESSION in every pane, which is how we detect it.
return {
  "christoomey/vim-tmux-navigator",
  lazy = false,
  init = function()
    vim.g.tmux_navigator_no_mappings = 1
  end,
  config = function()
    local function rex(dir)
      if vim.env.REX_SESSION == nil or vim.env.REX_SESSION == "" then
        return false
      end
      vim.fn.system({
        "rex",
        "do",
        "--autostart=false",
        "-s",
        vim.env.REX_SESSION,
        "-e",
        string.format('rex.session.focus_direction{direction="%s"}', dir),
      })
      return true
    end

    local function herdr(dir)
      if vim.env.HERDR_PANE_ID == nil or vim.env.HERDR_PANE_ID == "" then
        return false
      end
      local bin = vim.env.HERDR_BIN_PATH
      if bin == nil or bin == "" then
        bin = "herdr"
      end
      vim.fn.system({ bin, "pane", "focus", "--direction", dir, "--current" })
      return true
    end

    local function tmux(dir)
      if vim.env.TMUX == nil or vim.env.TMUX == "" then
        return false
      end
      local names = { left = "Left", down = "Down", up = "Up", right = "Right" }
      pcall(vim.cmd, "TmuxNavigate" .. names[dir])
      return true
    end

    local function nav(wincmd, dir)
      local prev = vim.api.nvim_get_current_win()
      vim.cmd("wincmd " .. wincmd)
      if vim.api.nvim_get_current_win() ~= prev then
        return -- moved within nvim
      end
      -- At a split edge: cross into the surrounding multiplexer.
      if rex(dir) then
        return
      end
      if herdr(dir) then
        return
      end
      tmux(dir)
    end

    local maps = {
      { "<C-h>", "h", "left", "Navigate left (vim/rex/herdr)" },
      { "<C-j>", "j", "down", "Navigate down (vim/rex/herdr)" },
      { "<C-k>", "k", "up", "Navigate up (vim/rex/herdr)" },
      { "<C-l>", "l", "right", "Navigate right (vim/rex/herdr)" },
    }

    for _, m in ipairs(maps) do
      vim.keymap.set("n", m[1], function()
        nav(m[2], m[3])
      end, { silent = true, noremap = true, desc = m[4] })
    end
  end,
}

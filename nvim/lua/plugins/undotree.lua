return {
  "mbbill/undotree",
  cmd = "UndotreeToggle",
  keys = {
    { "<leader>u", "<cmd>UndotreeToggle<cr><cmd>Neotree close<cr>", desc = "undotree toggle" },
  },
  init = function()
    -- Persist undo, refer https://github.com/mbbill/undotree#usage
    local undodir = vim.fn.expand("~/.undo-nvim")

    if vim.fn.has("persistent_undo") == 1 then
      if vim.fn.isdirectory(undodir) == 0 then
        os.execute("mkdir -p " .. undodir)
      end

      vim.opt.undodir = undodir
      vim.opt.undofile = true
    end
  end
}

return {
  "folke/trouble.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    require('trouble').setup({
      auto_preview = false,
      auto_open = false,
      follow = false,
    })
    vim.keymap.set("n", "<leader>t", "<cmd>Trouble diagnostics toggle<CR>")
  end
}

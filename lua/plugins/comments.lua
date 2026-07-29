return {
  "numToStr/Comment.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    -- `.env` files get filetype `env` but no treesitter parser is installed,
    -- so Comment.nvim's ts-based commentstring calc crashes ("[Comment.nvim] nil")
    -- and `gc` silently does nothing. Short-circuit with the native commentstring.
    pre_hook = function()
      if vim.bo.filetype == "env" then
        return "# %s"
      end
    end,
  },
}

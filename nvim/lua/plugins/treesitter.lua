return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").setup()

      -- install parsers (new `main`-branch API; replaces old `ensure_installed`)
      require("nvim-treesitter").install({
        "c", "lua", "javascript", "html",
        "go", "dart", "typescript", "python",
        "vimdoc", "vim",
      })

      -- highlighting + indent are no longer modules on `main`;
      -- start them per-buffer via FileType.
      vim.api.nvim_create_autocmd("FileType", {
        pattern = {
          "c", "lua", "javascript", "html",
          "go", "dart", "typescript", "python",
          "vimdoc", "vim",
        },
        callback = function()
          -- treesitter highlighting
          pcall(vim.treesitter.start)
          -- treesitter-based indent (experimental)
          vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },
}

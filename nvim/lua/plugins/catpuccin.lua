return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    config = function()
      local catpuccin = require("catppuccin")
      catpuccin.setup({
        transparent_background = true,
        custom_highlights = function(colors)
          return {
            WinSeparator = { fg = colors.flamingo }
          }
        end
      })
      vim.opt.termguicolors = true
      vim.cmd.colorscheme("catppuccin")
    end
  },
  {
    "nvim-lualine/lualine.nvim",
    lazy = false,
    config = function()
      local lualine = require("lualine")
      lualine.setup({
        extensions = { "oil" },
        sections = {
          lualine_c = {
            {
              'filename',
              path = 1,
            }
          }
        }
      })
    end
  },
}

return {
  'nvim-telescope/telescope.nvim',
  dependencies = {
    "MunifTanjim/nui.nvim",
    'nvim-lua/plenary.nvim',
    { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
    {
      "nvim-telescope/telescope-ui-select.nvim",
      opts = {},
    }
  },
  keys = {
    { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "find files" },
    { "<leader>fg", "<cmd>Telescope live_grep<cr>",  desc = "live grep" },
    { "<leader>fb", "<cmd>Telescope buffers<cr>",    desc = "find buffers" },
    { "<leader>fh", "<cmd>Telescope help_tags<cr>",  desc = "find help tags" },
  },
  config = function()
    local telescope = require("telescope")
    local actions = require("telescope.actions")

    telescope.setup({
      extensions = {
        fzf = {
          fuzzy = true,
          override_generic_sorter = true,
          override_file_sorter = true,
          case_mode = "smart_case",
        },
        ["ui-select"] = {
          require("telescope.themes").get_dropdown {}
        }
      },
      defaults = {
        mappings = {
          i = {
            ["<C-k>"] = actions.move_selection_previous,
            ["<C-j>"] = actions.move_selection_next,
          }
        }
      }
    })


    telescope.load_extension("fzf")
    telescope.load_extension("ui-select")
  end
}

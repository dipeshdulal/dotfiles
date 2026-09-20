return {
  'nvim-flutter/flutter-tools.nvim',
  ft = { "dart" },
  dependencies = {
    'nvim-lua/plenary.nvim',
    'stevearc/dressing.nvim',  -- optional for vim.ui.select
    'mfussenegger/nvim-dap',   -- config calls require('dap'); ensure it's loaded first
  },
  config = function()
    require("flutter-tools").setup({
      fvm = true,
      debugger = {
        enabled = true,
        run_via_dap = true,
      }
    })
    require('dap').defaults.dart.exception_breakpoints = {}
  end
}

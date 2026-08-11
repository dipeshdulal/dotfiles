return {
  "mfussenegger/nvim-dap",
  dependencies = {
    {
      "rcarriga/nvim-dap-ui",
      dependencies = {
        { "nvim-neotest/nvim-nio" }
      },
      keys = {
        {
          "<leader>du",
          function()
            require("dapui").toggle({})
          end
        },
      },
      opts = {},
      config = function(_, opts)
        local dap = require("dap")
        local dapui = require("dapui")
        dapui.setup(opts)

        -- do not open debugger ui automatically
        -- dap.listeners.after.event_initialized["dapui_config"] = function()
        --   dapui.open({})
        --   vim.cmd("Neotree close")
        -- end

        dap.listeners.before.event_terminated["dapui_config"] = function()
          dapui.close({})
        end

        dap.listeners.before.event_exited["dapui_config"] = function()
          dapui.close({})
        end
      end
    },
    {
      "theHamsta/nvim-dap-virtual-text",
      opts = {},
    },
    {
      "jay-babu/mason-nvim-dap.nvim",
      dependencies = "mason.nvim",
      cmd = { "DapInstall", "DapUninstall" },
      opts = {
        automatic_setup = true,
        handlers = {
          function(config)
            require("mason-nvim-dap").default_setup(config)
          end,
        },
        ensure_installed = {
          "delve",
          "debugpy"
        },
      },
    },
  },
  keys = {
    { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint" },
    { "<leader>dc", function() require("dap").continue() end,          desc = "Continue" },
    { "<leader>do", function() require("dap").step_over() end,         desc = "Step Over" },
    { "<leader>di", function() require("dap").step_into() end,         desc = "Step Into" },
    { "<leader>dw", function() require("dap.ui.widgets").hover() end,  desc = "Widgets" },
    { "<leader>dr", function() require("dap").repl.open() end,         desc = "Repl" },
  },
  config = function()
    local dap = require("dap")
    dap.adapters.go = {
      type = 'executable',
      command = 'node',
      args = { os.getenv("HOME") .. '/vscode-go/dist/debugAdapter.js' }
    }

    dap.configurations.go = {
      {
        type = "go",
        name = "Attach Debugger",
        request = "attach",
        port = 5002,
        mode = "remote",
        cwd = vim.fn.getcwd(),
      }
    }
  end
}

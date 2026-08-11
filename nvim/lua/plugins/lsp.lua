return {
  {
    'williamboman/mason.nvim',
    lazy = false,
    config = true,
  },
  {
    'saghen/blink.cmp',
    dependencies = 'rafamadriz/friendly-snippets',
    version = '*',
    opts = {
      keymap = {
        preset = 'default',
        ["<C-Space>"] = { 'show', 'fallback' },
        ["<C-k>"] = { 'select_prev', 'fallback' }, -- previous suggestion
        ["<C-j>"] = { 'select_next', 'fallback' }, -- next suggestion
        ["<CR>"] = { 'accept', 'fallback' },
      },
      cmdline = {
        completion = {
          menu = {
            auto_show = false,
          }
        }
      },
      signature = {
        enabled = true,
        window = {
          border = "rounded"
        }
      },
      completion = {
        documentation = {
          auto_show = true,
          window = {
            border = "rounded",
          },
          auto_show_delay_ms = 500,
        },
        menu = {
          border = "rounded",
        },
      },
      appearance = {
        nerd_font_variant = 'mono'
      },
    },
  },
  {
    'neovim/nvim-lspconfig',
    cmd = { 'LspInfo', 'LspInstall', 'LspStart' },
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
      { 'saghen/blink.cmp' },
      { 'williamboman/mason-lspconfig.nvim' },
      {
        "nvimtools/none-ls.nvim",
        dependencies = {
          "nvimtools/none-ls-extras.nvim",
        },
        config = function()
          local null_ls = require("null-ls")
          null_ls.setup({
            sources = {
              null_ls.builtins.formatting.prettier.with({
                disabled_filetypes = { "templ" },
              }),
              null_ls.builtins.code_actions.gitsigns,
              null_ls.builtins.formatting.black.with({ extra_args = { "--fast" } }),
              require("none-ls.diagnostics.eslint"),
            },
          })
        end,
      },
    },
    config = function()
      -- lsp keybindings
      vim.api.nvim_create_autocmd('LspAttach', {
        desc = 'LSP actions',
        callback = function(event)
          local opts = { buffer = event.buf }

          -- these will be buffer-local keybindings
          -- because they only work if you have an active language server

          vim.keymap.set('n', 'K', function()
            vim.lsp.buf.hover({
              border = 'rounded',
            })
          end, opts)

          vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>', opts)
          vim.keymap.set('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<cr>', opts)
          vim.keymap.set('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<cr>', opts)
          vim.keymap.set('n', 'go', '<cmd>lua vim.lsp.buf.type_definition()<cr>', opts)
          vim.keymap.set('n', 'gr', '<cmd>lua vim.lsp.buf.references()<cr>', opts)
          vim.keymap.set('n', 'gs', '<cmd>lua vim.lsp.buf.signature_help()<cr>', opts)

          vim.keymap.set('n', '<leader>jj', '<cmd> lua vim.diagnostic.goto_next()<cr>', opts)
          vim.keymap.set('n', '<leader>kk', '<cmd> lua vim.diagnostic.goto_prev()<cr>', opts)

          -- override defaults from lsp_zero
          vim.keymap.set("n", "<leader>ca", '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
          vim.keymap.set("n", "<leader>r", '<cmd>lua vim.lsp.buf.rename()<CR>', opts)

          -- code formatting
          vim.keymap.set("n", "<leader>mp", function()
            vim.lsp.buf.format()
          end)
        end
      })

      vim.lsp.config('lua_ls', {
        settings = {
          Lua = {
            runtime = {
              version = 'LuaJIT',
            },
            diagnostics = {
              globals = {
                'vim',
              }
            },
            workspace = {
              library = vim.api.nvim_get_runtime_file("", true),
            }
          }
        }
      })

      -- disable invalid server name issue for now, provide empty table as configuraion
      vim.lsp.config('null-ls', {})
      vim.lsp.config('GitHub Copilot', {})

      require('mason-lspconfig').setup({
        ensure_installed = {
          "gopls",
          "ts_ls",
          "html",
          "tailwindcss",
          "pyright",
          "lua_ls"
        },
      })
    end
  }
}

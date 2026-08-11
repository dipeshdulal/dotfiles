return {
  'RRethy/vim-illuminate',
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local illuminate = require("illuminate")
    illuminate.configure({
      -- 'treesitter' provider removed: nvim-treesitter `main` branch dropped
      -- the `locals` module it relied on. LSP + regex cover highlighting.
      providers = {
        'lsp',
        'regex',
      },
      delay = 100,
      filetypes_denylist = {
        'dirbuf',
        'dirvish',
        'fugitive',
      },
    })
  end
}

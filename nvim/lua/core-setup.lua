local opt = vim.opt

-- leader key --
vim.g.mapleader = " "

-- options --
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.smartindent = true

opt.fillchars = { eob = " " }
opt.mouse = "a"

opt.number = true
opt.relativenumber = true

-- highlight line
opt.cursorline = true

-- exrc
opt.exrc = true

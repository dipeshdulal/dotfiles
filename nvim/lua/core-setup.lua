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

-- highlight current line in the number column only.
-- full-line ("both") highlight repaints the whole line and corrupts rendering
-- on lines with wide/combining unicode (Devanagari) under Ghostty.
opt.cursorline = true
opt.cursorlineopt = "number"

-- keep a margin around the cursor so the viewport doesn't lurch
opt.scrolloff = 8
opt.sidescrolloff = 8

-- exrc
opt.exrc = true

-- tty
vim.o.ambiwidth = "single"
vim.o.number = true

opt.list = false

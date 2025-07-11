local opt = vim.opt

opt.number = true
opt.relativenumber = true

opt.expandtab = true
opt.tabstop = 2
opt.shiftwidth = 2
opt.softtabstop = 2

opt.autoindent = true
opt.smartindent = true

opt.wrap = false

opt.ignorecase = true
opt.smartcase = true

opt.cursorline = true

opt.termguicolors = true
opt.background = "dark"
opt.signcolumn = "yes"

opt.backspace = "indent,eol,start"

opt.clipboard:append("unnamedplus")

opt.splitright = true
opt.splitbelow = true

opt.swapfile = false
opt.backup = false
opt.undofile = true

opt.scrolloff = 8
opt.sidescrolloff = 8

opt.mouse = "a"

opt.updatetime = 250
opt.timeoutlen = 300

opt.showmode = false

opt.hlsearch = true
opt.incsearch = true
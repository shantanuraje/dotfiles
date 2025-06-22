-- Set leader key early
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.have_nerd_font = false

-- Load core settings
require('core.options')    -- Basic vim options
require('core.keymaps')    -- Basic keymappings
require('core.autocmds')   -- Autocommands

-- Bootstrap lazy.nvim
require('core.lazy_bootstrap')

-- Load plugins
require('lazy').setup({
  -- Import all plugin specs from separate files
  { import = 'plugins' },
}, {
  ui = {
    icons = vim.g.have_nerd_font and {} or {
      cmd = "⌘",
      config = "🛠",
      event = "📅",
      ft = "📂",
      init = "⚙",
      keys = "🗝",
      plugin = "🔌",
      runtime = "💻",
      require = "🌙",
      source = "📄",
      start = "🚀",
      task = "📌",
      lazy = "💤 ",
    },
  },
}) 
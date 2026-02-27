return {
  {
    "epwalsh/obsidian.nvim",
    version = "*",
    lazy = true,
    ft = "markdown",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    opts = {
      workspaces = {
        {
          name = "personal",
          path = "~/Documents/personal",
        },
      },

      -- Optional: Disable UI features if you don't have nerd fonts
      ui = {
        enable = false,
      },

      -- Optional: Customize daily notes location
      daily_notes = {
        folder = "06-Journal",
      },
    },
  },
} 
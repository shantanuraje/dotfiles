return {
  "coder/claudecode.nvim",
  dependencies = { "folke/snacks.nvim" },
  opts = {
    -- Server Configuration
    port_range = { min = 10000, max = 65535 },
    auto_start = true,
    log_level = "info", -- "trace", "debug", "info", "warn", "error"
    terminal_cmd = nil, -- Custom terminal command (default: "claude")
    
    -- Selection Tracking
    track_selection = true,
    visual_demotion_delay_ms = 50,
    
    -- Terminal Configuration
    terminal = {
      split_side = "right", -- "left" or "right"
      split_width_percentage = 0.30,
      provider = "auto", -- "auto", "snacks", or "native"
      auto_close = true,
    },
    
    -- Diff Integration
    diff_opts = {
      auto_close_on_accept = true,
      vertical_split = true,
      open_in_current_tab = true,
    },
  },
  keys = {
    { "<leader>cc", "<cmd>ClaudeCode<cr>", desc = "Open Claude Code" },
    { "<leader>ct", "<cmd>ClaudeCodeToggle<cr>", desc = "Toggle Claude Code terminal" },
    { "<leader>ca", "<cmd>ClaudeCodeAccept<cr>", desc = "Accept Claude Code suggestion", mode = { "n", "v" } },
    { "<leader>cr", "<cmd>ClaudeCodeReject<cr>", desc = "Reject Claude Code suggestion", mode = { "n", "v" } },
  },
}
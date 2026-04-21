return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    opts = {
      -- NixOS bundles ABI-matched parsers for: c, lua, markdown, markdown_inline,
      -- query, vim, vimdoc at /run/current-system/sw/lib/nvim/parser/
      -- Only ensure_installed for languages NOT provided by the system to avoid
      -- version conflicts (nil node :range() crash in injection resolution).
      ensure_installed = {
        "bash",
        "css",
        "diff",
        "html",
        "ini",
        "luadoc",
        "nix",
        "yaml",
      },
      auto_install = true,
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = { "ruby" },
      },
      indent = { enable = true, disable = { "ruby" } },
    },
    config = function(_, opts)
      require("nvim-treesitter.install").prefer_git = true
      require("nvim-treesitter.configs").setup(opts)

      -- NixOS ships ABI-matched parsers AND query files for core languages.
      -- nvim-treesitter overrides those queries with its own (using custom
      -- directives like #set-lang-from-info-string!) which crash on Neovim
      -- 0.12.x with: "attempt to call method 'range' (a nil value)".
      -- Remove nvim-treesitter's query overrides for system-provided languages
      -- so the compatible runtime queries are used instead.
      local ts_queries = vim.fn.stdpath("data") .. "/lazy/nvim-treesitter/queries"
      local system_langs = { "c", "lua", "markdown", "markdown_inline", "query", "vim", "vimdoc" }
      for _, lang in ipairs(system_langs) do
        local query_dir = ts_queries .. "/" .. lang
        if vim.fn.isdirectory(query_dir) == 1 then
          -- Remove from runtimepath query resolution by renaming the dir
          local disabled = query_dir .. ".disabled"
          if vim.fn.isdirectory(disabled) == 0 then
            vim.fn.rename(query_dir, disabled)
          end
        end
      end
    end,
  },
} 
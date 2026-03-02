return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      heading = {
        enabled = true,
        icons = { "# ", "## ", "### ", "#### ", "##### ", "###### " },
      },
      code = {
        enabled = true,
        sign = false,
        width = "full",
        language_pad = 1,
      },
      checkbox = {
        enabled = true,
      },
      bullet = {
        enabled = true,
      },
    },
  },
}

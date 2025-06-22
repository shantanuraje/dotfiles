return {
	{
		"CopilotC-Nvim/CopilotChat.nvim",
		dependencies = {
			{ "github/copilot.vim" },
			{ "nvim-lua/plenary.nvim", branch = "master" },
		},
		build = "make tiktoken", -- Only on MacOS or Linux
		opts = {
			-- See Configuration section for options
		},
		keys = {
			{ "<leader>zc", "<cmd>vsplit | CopilotChat<cr>", desc = "Copilot Chat" },
			{ "<leader>zp", "<cmd>Copilot panel<cr>", desc = "Copilot Panel" },
			{ "<leader>zj", "<cmd>Copilot jump<cr>", desc = "Copilot Jump" },
		},
	},
}

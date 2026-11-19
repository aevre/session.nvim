local M = {}

local health = vim.health
local start = health.start or health.report_start
local ok = health.ok or health.report_ok
local error = health.error or health.report_error

function M.check()
	start("session.nvim")
	if vim.fn.has("nvim-0.12") == 1 then
		ok("Neovim 0.12+ is available")
	else
		error("Neovim 0.12+ is required")
	end

	if vim.fn.exists(":mksession") == 2 then
		ok("`:mksession` is available")
	else
		error("`:mksession` is required")
	end
end

return M

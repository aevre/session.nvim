local M = {}

---Register the public Ex commands once per setup call.
---@param manager session.Manager
function M.setup(manager)
	vim.api.nvim_create_user_command("SessionSelect", manager.select, { force = true })
	vim.api.nvim_create_user_command("SessionLast", manager.last, { force = true })
	vim.api.nvim_create_user_command("SessionSave", function(args)
		local path, err = manager.save(args.args ~= "" and args.args or nil, args.bang)
		if not path then
			vim.notify("session.nvim: " .. tostring(err), vim.log.levels.ERROR)
		end
	end, { nargs = "?", bang = true, force = true })
	vim.api.nvim_create_user_command("SessionLoad", function(args)
		local ok, err = manager.load(args.args ~= "" and args.args or nil)
		if not ok and err then
			vim.notify("session.nvim: " .. tostring(err), vim.log.levels.WARN)
		end
	end, { nargs = "?", force = true })
end

return M

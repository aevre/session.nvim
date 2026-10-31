local M = {}

---Register the public Ex commands once per setup call.
---@param manager session.Manager
function M.setup(manager)
	vim.api.nvim_create_user_command("SessionSelect", manager.select, { force = true })
	vim.api.nvim_create_user_command("SessionLast", manager.last, { force = true })
	vim.api.nvim_create_user_command("SessionInfo", function()
		local record = manager.active()
		local message = record
				and ("Session: " .. record.name .. "\nProject: " .. record.root .. "\nFile: " .. record.path)
			or "No active session"
		vim.notify(message, vim.log.levels.INFO, { title = "session.nvim" })
	end, { force = true })
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
	vim.api.nvim_create_user_command("SessionDelete", function(args)
		local ok, err = manager.delete(args.bang)
		if not ok and err then
			vim.notify("session.nvim: " .. tostring(err), vim.log.levels.ERROR)
		end
	end, { bang = true, force = true })
	vim.api.nvim_create_user_command("SessionDeleteSelect", function(args)
		manager.delete_select(args.bang)
	end, { bang = true, force = true })
	vim.api.nvim_create_user_command("SessionRename", function(args)
		if args.args == "" then
			vim.notify("session.nvim: usage: SessionRename new_name", vim.log.levels.ERROR)
			return
		end
		local path, err = manager.rename(args.args)
		if not path then
			vim.notify("session.nvim: " .. tostring(err), vim.log.levels.ERROR)
		end
	end, { nargs = 1, force = true })
	vim.api.nvim_create_user_command("SessionRenameSelect", manager.rename_select, { force = true })
end

return M

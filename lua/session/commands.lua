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
		if args.args == "" then
			manager.delete_select(args.bang)
			return
		end
		local ok, err = manager.delete(args.args, args.bang)
		if not ok and err then
			vim.notify("session.nvim: " .. tostring(err), vim.log.levels.ERROR)
		end
	end, { nargs = "?", bang = true, force = true })
	vim.api.nvim_create_user_command("SessionRename", function(args)
		if args.args == "" then
			manager.rename_select()
			return
		end
		local names = vim.split(args.args, "%s+", { trimempty = true })
		if #names > 2 then
			vim.notify("session.nvim: expected [old_name] new_name", vim.log.levels.ERROR)
			return
		end
		local name, new_name = names[2] and names[1] or nil, names[2] or names[1]
		local path, err = manager.rename(name, new_name)
		if not path then
			vim.notify("session.nvim: " .. tostring(err), vim.log.levels.ERROR)
		end
	end, { nargs = "*", force = true })
end

return M

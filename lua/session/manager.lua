local Config = require("session.config")
local Project = require("session.project")
local Storage = require("session.storage")

local M = {}
local uv = vim.uv or vim.loop
---@type session.Record?
local active

---Return the current active session identity.
---@return session.Record?
function M.active()
	return active
end

---Save a workspace to a session file and make it active.
---@param root string
---@param name session.Name
---@param force boolean
---@return string?, string?
function M.save_to(root, name, force)
	local config = Config.get()
	name = Storage.name(name)
	root = vim.fs.normalize(root)
	local target = Storage.path(config.dir, root, name)
	if not force and uv.fs_stat(target) then
		return nil, "session already exists"
	end

	local temp = target .. ".tmp-" .. vim.fn.getpid()
	pcall(uv.fs_unlink, temp)
	local ok, err = pcall(vim.api.nvim_cmd, { cmd = "mksession", bang = true, args = { temp } }, {})
	if not ok then
		pcall(uv.fs_unlink, temp)
		return nil, err
	end
	local metadata_ok, metadata_err = Storage.write_metadata(temp, root, name)
	if not metadata_ok then
		pcall(uv.fs_unlink, temp)
		return nil, metadata_err
	end
	local renamed, rename_err = uv.fs_rename(temp, target)
	if not renamed then
		pcall(uv.fs_unlink, temp)
		return nil, rename_err
	end
	active = { path = target, root = root, name = name }
	return target
end

local function modified_file_buffer_exists()
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if
			vim.api.nvim_buf_is_loaded(buf)
			and vim.bo[buf].buftype == ""
			and vim.api.nvim_buf_get_name(buf) ~= ""
			and vim.bo[buf].modified
		then
			return true
		end
	end
	return false
end

local function confirm_discard()
	return not modified_file_buffer_exists()
		or vim.fn.confirm("Discard unsaved changes and load session?", "&Cancel\n&Load", 1) == 2
end

---Load a previously identified session and update the active identity.
---@param record session.Record?
---@param skip_switch_save? boolean
---@return boolean?, string?
function M.load_record(record, skip_switch_save)
	if not record or not uv.fs_stat(record.path) then
		return nil, "session not found"
	end
	if not confirm_discard() then
		return false
	end

	if not uv.fs_stat(record.root) then
		return nil, "session project root not found"
	end

	local config = Config.get()
	if active and config.autosave_on_switch and not skip_switch_save then
		local saved, err = M.save_to(active.root, active.name, true)
		if not saved then
			return nil, err
		end
	end

	local ok, err = pcall(function()
		vim.cmd("silent source " .. vim.fn.fnameescape(record.path))
		vim.api.nvim_set_current_dir(record.root)
	end)
	if not ok then
		return nil, err
	end
	active = record
	return true
end

---Save to the project inferred from the current buffer.
---@param name session.Name
---@param force? boolean
---@return string?, string?
function M.save(name, force)
	return M.save_to(Project.root(), name, force == true)
end

---Load a named session from the current project's root.
---@param name session.Name
---@return boolean?, string?
function M.load(name)
	local config = Config.get()
	local root = Project.root()
	local path = Storage.path(config.dir, root, name)
	return M.load_record(Storage.read(path))
end

---List saved sessions, newest first.
---@return session.Record[]
function M.list()
	return Storage.list(Config.get().dir)
end

---Load the most recently modified saved session.
---@return boolean?, string?
function M.last()
	return M.load_record(M.list()[1])
end

---Open the UI selector for all saved sessions.
function M.select()
	vim.ui.select(M.list(), {
		prompt = "Session> ",
		format_item = function(record)
			return record.root .. "  [" .. record.name .. "]"
		end,
	}, function(record)
		if record then
			local ok, err = M.load_record(record)
			if not ok and err then
				vim.notify("session.nvim: " .. tostring(err), vim.log.levels.WARN)
			end
		end
	end)
end

---Restore the most specific recorded project containing the startup location.
function M.restore_startup()
	if vim.fn.argc() > 0 then
		return
	end
	local path = vim.api.nvim_buf_get_name(0)
	local anchor = path ~= "" and vim.fs.dirname(path) or Project.startup_cwd()
	local matches = {}
	for _, record in ipairs(M.list()) do
		if vim.fs.relpath(record.root, anchor) ~= nil then
			matches[#matches + 1] = record
		end
	end
	table.sort(matches, function(a, b)
		return #a.root > #b.root
	end)
	if matches[1] then
		M.load_record(matches[1], true)
	end
end

---Save the active session on exit when configured.
function M.save_on_exit()
	local root, name = active and active.root or Project.root(), active and active.name or nil
	local path, err = M.save_to(root, name, true)
	if not path then
		vim.notify("session.nvim: " .. tostring(err), vim.log.levels.ERROR)
	end
end

return M

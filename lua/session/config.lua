local M = {}

---@type session.Config
local defaults = {
	dir = vim.fn.stdpath("state") .. "/sessions",
	autosave = true,
	autosave_on_switch = false,
	auto_restore = false,
}

---@type session.Config
local options = vim.deepcopy(defaults)

---Merge user settings over the defaults and normalize the storage path.
---@param opts? session.Config
---@return session.Config
function M.setup(opts)
	options = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
	options.dir = vim.fs.normalize(vim.fn.expand(options.dir))
	vim.fn.mkdir(options.dir, "p")
	return options
end

---@return session.Config
function M.get()
	return options
end

return M

local M = {}
local startup_cwd = assert((vim.uv or vim.loop).cwd())

local function normalize(path)
	local normalized = vim.fs.normalize(path)
	return normalized ~= "/" and normalized:gsub("/$", "") or normalized
end

---Find the project identity for a buffer using LSP, Git, then startup cwd.
---@param buf? integer
---@return string
function M.root(buf)
	buf = buf or vim.api.nvim_get_current_buf()
	local filename = vim.api.nvim_buf_get_name(buf)
	local start = filename ~= "" and vim.fs.dirname(filename) or startup_cwd
	local roots = {}

	for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
		local root = client.config.root_dir
		if not root and client.workspace_folders and client.workspace_folders[1] then
			root = vim.uri_to_fname(client.workspace_folders[1].uri)
		end
		if root and vim.fs.relpath(root, start) ~= nil then
			roots[#roots + 1] = normalize(root)
		end
	end

	table.sort(roots, function(a, b)
		return #a > #b
	end)
	if roots[1] then
		return roots[1]
	end
	return normalize(vim.fs.root(start, ".git") or startup_cwd)
end

---Return the cwd captured when this module was first loaded.
---@return string
function M.startup_cwd()
	return startup_cwd
end

return M
